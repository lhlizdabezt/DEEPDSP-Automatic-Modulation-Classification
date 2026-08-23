"""DSP and inference engine for the DEEPDSP-AMC demonstration app.

The implementation mirrors the executed project notebook so that the app and
the report use the same signal model, 18 handcrafted features and CompactIQCNN.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from time import perf_counter
from typing import Any

import joblib
import numpy as np
import torch
from scipy import signal, stats
from torch import nn


CLASSES = ("BPSK", "QPSK", "8PSK", "16QAM", "2FSK", "4FSK")
FRAME_LEN = 256
SAMPLES_PER_SYMBOL = 8
RRC_ROLLOFF = 0.35
RRC_SPAN_SYMBOLS = 8
DEFAULT_ALPHA_CNN = 0.55

FEATURE_NAMES = (
    "amp_mean",
    "amp_std",
    "amp_cv",
    "amp_skew",
    "amp_kurtosis",
    "papr",
    "moment2_abs",
    "moment4_abs",
    "moment6_abs",
    "phase_diff_mean_abs",
    "phase_diff_std",
    "phase_concentration",
    "zero_cross_i",
    "zero_cross_q",
    "spectral_entropy",
    "spectral_flatness",
    "spectral_centroid",
    "spectral_spread",
)


@dataclass(frozen=True)
class ChannelConfig:
    """User-controlled channel envelope used for one synthetic frame."""

    snr_db: float
    max_echo: float = 0.20
    max_cfo: float = 0.002


@dataclass(frozen=True)
class ModelBundle:
    rf: Any
    cnn: nn.Module
    classes: tuple[str, ...]
    alpha_cnn: float
    device: torch.device
    model_dir: Path
    parameter_count: int


class CompactIQCNN(nn.Module):
    """Compact 1-D CNN architecture used by the submitted notebook."""

    def __init__(self, n_classes: int):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv1d(4, 32, kernel_size=9, padding=4, bias=False),
            nn.BatchNorm1d(32),
            nn.GELU(),
            nn.Conv1d(32, 32, kernel_size=7, padding=3, bias=False),
            nn.BatchNorm1d(32),
            nn.GELU(),
            nn.MaxPool1d(2),
            nn.Dropout(0.10),
            nn.Conv1d(32, 64, kernel_size=7, padding=3, bias=False),
            nn.BatchNorm1d(64),
            nn.GELU(),
            nn.Conv1d(64, 64, kernel_size=5, padding=2, bias=False),
            nn.BatchNorm1d(64),
            nn.GELU(),
            nn.MaxPool1d(2),
            nn.Dropout(0.15),
            nn.Conv1d(64, 96, kernel_size=5, padding=2, bias=False),
            nn.BatchNorm1d(96),
            nn.GELU(),
            nn.AdaptiveAvgPool1d(1),
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Linear(96, 64),
            nn.GELU(),
            nn.Dropout(0.20),
            nn.Linear(64, n_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.classifier(self.features(x))


def rrc_taps(beta: float, sps: int, span_symbols: int) -> np.ndarray:
    """Return a unit-energy root-raised-cosine impulse response."""

    n = np.arange(-span_symbols * sps / 2, span_symbols * sps / 2 + 1)
    t = n / sps
    taps = np.empty_like(t, dtype=np.float64)
    for index, ti in enumerate(t):
        if np.isclose(ti, 0.0):
            taps[index] = 1.0 + beta * (4.0 / np.pi - 1.0)
        elif beta > 0 and np.isclose(abs(ti), 1.0 / (4.0 * beta)):
            taps[index] = (beta / np.sqrt(2.0)) * (
                (1.0 + 2.0 / np.pi) * np.sin(np.pi / (4.0 * beta))
                + (1.0 - 2.0 / np.pi) * np.cos(np.pi / (4.0 * beta))
            )
        else:
            numerator = np.sin(np.pi * ti * (1.0 - beta))
            numerator += 4.0 * beta * ti * np.cos(np.pi * ti * (1.0 + beta))
            denominator = np.pi * ti * (1.0 - (4.0 * beta * ti) ** 2)
            taps[index] = numerator / denominator
    return (taps / np.sqrt(np.sum(taps**2))).astype(np.float32)


RRC = rrc_taps(RRC_ROLLOFF, SAMPLES_PER_SYMBOL, RRC_SPAN_SYMBOLS)


def constellation_symbols(kind: str, count: int, rng: np.random.Generator) -> np.ndarray:
    if kind == "BPSK":
        return rng.choice(np.array([-1.0, 1.0], dtype=np.complex64), count)
    if kind in {"QPSK", "8PSK"}:
        order = 4 if kind == "QPSK" else 8
        indices = rng.integers(0, order, count)
        offset = np.pi / 4 if kind == "QPSK" else 0.0
        return np.exp(1j * (2 * np.pi * indices / order + offset)).astype(np.complex64)
    if kind == "16QAM":
        levels = np.array([-3, -1, 1, 3], dtype=np.float32)
        in_phase = rng.choice(levels, count)
        quadrature = rng.choice(levels, count)
        return ((in_phase + 1j * quadrature) / np.sqrt(10.0)).astype(np.complex64)
    raise ValueError(f"Unsupported constellation: {kind}")


def generate_clean_frame(kind: str, rng: np.random.Generator) -> np.ndarray:
    """Generate a normalized 256-sample complex baseband frame."""

    margin_symbols = RRC_SPAN_SYMBOLS + 6
    symbol_count = int(np.ceil(FRAME_LEN / SAMPLES_PER_SYMBOL)) + 2 * margin_symbols

    if kind in {"BPSK", "QPSK", "8PSK", "16QAM"}:
        symbols = constellation_symbols(kind, symbol_count, rng)
        upsampled = np.zeros(symbol_count * SAMPLES_PER_SYMBOL, dtype=np.complex64)
        upsampled[::SAMPLES_PER_SYMBOL] = symbols
        shaped = signal.fftconvolve(upsampled, RRC, mode="same")
        center = len(shaped) // 2
        frame = shaped[center - FRAME_LEN // 2 : center + FRAME_LEN // 2]
    elif kind in {"2FSK", "4FSK"}:
        order = 2 if kind == "2FSK" else 4
        tones = (
            np.array([-0.080, 0.080])
            if order == 2
            else np.array([-0.135, -0.045, 0.045, 0.135])
        )
        symbols = rng.integers(0, order, symbol_count)
        instantaneous_frequency = np.repeat(tones[symbols], SAMPLES_PER_SYMBOL)
        phase = 2.0 * np.pi * np.cumsum(instantaneous_frequency)
        shaped = np.exp(1j * phase)
        center = len(shaped) // 2
        frame = shaped[center - FRAME_LEN // 2 : center + FRAME_LEN // 2]
    else:
        raise ValueError(f"Unsupported modulation: {kind}")

    power = np.mean(np.abs(frame) ** 2)
    return (frame / np.sqrt(power + 1e-12)).astype(np.complex64)


def apply_channel(
    clean: np.ndarray,
    config: ChannelConfig,
    rng: np.random.Generator,
) -> tuple[np.ndarray, dict[str, float | int]]:
    """Apply a two-ray channel, CFO, random phase, timing shift and AWGN."""

    sample_index = np.arange(len(clean), dtype=np.float32)
    delay = int(rng.integers(1, 5))
    echo_amplitude = float(rng.uniform(0.0, config.max_echo))
    echo_phase = float(rng.uniform(-np.pi, np.pi))
    impulse = np.zeros(delay + 1, dtype=np.complex64)
    impulse[0] = 1.0
    impulse[-1] = echo_amplitude * np.exp(1j * echo_phase)
    faded = signal.lfilter(impulse, [1.0], clean)

    cfo = float(rng.uniform(-config.max_cfo, config.max_cfo))
    initial_phase = float(rng.uniform(-np.pi, np.pi))
    shifted = faded * np.exp(1j * (2.0 * np.pi * cfo * sample_index + initial_phase))
    timing_shift = int(rng.integers(0, SAMPLES_PER_SYMBOL))
    shifted = np.roll(shifted, timing_shift)

    signal_power = float(np.mean(np.abs(shifted) ** 2))
    noise_power = signal_power / (10.0 ** (config.snr_db / 10.0))
    noise = np.sqrt(noise_power / 2.0) * (
        rng.standard_normal(len(clean)) + 1j * rng.standard_normal(len(clean))
    )
    received = shifted + noise
    received /= np.sqrt(np.mean(np.abs(received) ** 2) + 1e-12)
    metadata: dict[str, float | int] = {
        "delay_samples": delay,
        "echo_amplitude": echo_amplitude,
        "echo_phase_rad": echo_phase,
        "cfo_cycles_per_sample": cfo,
        "initial_phase_rad": initial_phase,
        "timing_shift_samples": timing_shift,
        "noise_power": noise_power,
    }
    return received.astype(np.complex64), metadata


def dsp_features(z: np.ndarray) -> np.ndarray:
    """Extract the 18 amplitude, phase, moment and spectral features."""

    normalized = z / np.sqrt(np.mean(np.abs(z) ** 2) + 1e-12)
    amplitude = np.abs(normalized)
    differential_phase = np.angle(normalized[1:] * np.conj(normalized[:-1]))
    windowed = normalized * signal.windows.hann(len(normalized), sym=False)
    spectrum = np.abs(np.fft.fftshift(np.fft.fft(windowed))) ** 2
    probability = spectrum / (np.sum(spectrum) + 1e-12)
    frequency = np.fft.fftshift(np.fft.fftfreq(len(normalized)))
    centroid = float(np.sum(frequency * probability))
    spread = float(np.sqrt(np.sum(((frequency - centroid) ** 2) * probability)))
    signs_i = np.signbit(normalized.real)
    signs_q = np.signbit(normalized.imag)
    return np.array(
        [
            amplitude.mean(),
            amplitude.std(),
            amplitude.std() / (amplitude.mean() + 1e-12),
            stats.skew(amplitude, bias=False),
            stats.kurtosis(amplitude, fisher=True, bias=False),
            np.max(amplitude**2) / (np.mean(amplitude**2) + 1e-12),
            abs(np.mean(normalized**2)),
            abs(np.mean(normalized**4)),
            abs(np.mean(normalized**6)),
            abs(np.mean(differential_phase)),
            np.std(differential_phase),
            abs(np.mean(np.exp(1j * differential_phase))),
            np.mean(signs_i[1:] != signs_i[:-1]),
            np.mean(signs_q[1:] != signs_q[:-1]),
            -np.sum(probability * np.log2(probability + 1e-12)) / np.log2(len(probability)),
            np.exp(np.mean(np.log(spectrum + 1e-12))) / (np.mean(spectrum) + 1e-12),
            centroid,
            spread,
        ],
        dtype=np.float32,
    )


def cnn_tensor(frames: np.ndarray) -> np.ndarray:
    """Map complex frames to I, Q, magnitude and sin(differential phase)."""

    normalized = frames / np.sqrt(
        np.mean(np.abs(frames) ** 2, axis=1, keepdims=True) + 1e-12
    )
    differential_phase = np.angle(normalized[:, 1:] * np.conj(normalized[:, :-1]))
    differential_phase = np.pad(differential_phase, ((0, 0), (1, 0)), mode="edge")
    return np.stack(
        [normalized.real, normalized.imag, np.abs(normalized), np.sin(differential_phase)],
        axis=1,
    ).astype(np.float32)


def resolve_model_dir(app_dir: Path) -> Path:
    """Prefer the standalone model bundle, then fall back to project artifacts."""

    candidates = (app_dir / "models", app_dir.parent / "artifacts")
    for candidate in candidates:
        if (candidate / "rf_dsp_pipeline.joblib").exists() and (
            candidate / "compact_iq_cnn.pt"
        ).exists():
            return candidate
    raise FileNotFoundError(
        "Không tìm thấy rf_dsp_pipeline.joblib và compact_iq_cnn.pt trong demo_app/models "
        "hoặc artifacts. Hãy chạy notebook trước."
    )


def load_models(app_dir: Path) -> ModelBundle:
    """Load the exact RF and CNN artifacts created by the notebook."""

    model_dir = resolve_model_dir(app_dir)
    checkpoint = torch.load(
        model_dir / "compact_iq_cnn.pt",
        map_location="cpu",
        weights_only=False,
    )
    classes = tuple(checkpoint["classes"])
    if classes != CLASSES:
        raise ValueError(f"Unexpected class order: {classes}")
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    cnn = CompactIQCNN(len(classes)).to(device)
    cnn.load_state_dict(checkpoint["state_dict"])
    cnn.eval()
    rf = joblib.load(model_dir / "rf_dsp_pipeline.joblib")
    return ModelBundle(
        rf=rf,
        cnn=cnn,
        classes=classes,
        alpha_cnn=DEFAULT_ALPHA_CNN,
        device=device,
        model_dir=model_dir,
        parameter_count=int(checkpoint["parameter_count"]),
    )


def infer_frame(
    bundle: ModelBundle,
    modulation: str,
    channel: ChannelConfig,
    seed: int,
) -> dict[str, Any]:
    """Generate one frame and return real RF, CNN and fused probabilities."""

    total_start = perf_counter()
    rng = np.random.default_rng(seed)
    clean = generate_clean_frame(modulation, rng)
    received, channel_metadata = apply_channel(clean, channel, rng)

    feature_start = perf_counter()
    features = dsp_features(received)
    feature_ms = (perf_counter() - feature_start) * 1_000.0

    rf_start = perf_counter()
    rf_probability = bundle.rf.predict_proba(features.reshape(1, -1))[0]
    rf_ms = (perf_counter() - rf_start) * 1_000.0

    cnn_input = torch.from_numpy(cnn_tensor(received.reshape(1, -1))).to(bundle.device)
    cnn_start = perf_counter()
    with torch.inference_mode():
        cnn_probability = torch.softmax(bundle.cnn(cnn_input), dim=1)[0].cpu().numpy()
    cnn_ms = (perf_counter() - cnn_start) * 1_000.0

    hybrid_probability = (
        bundle.alpha_cnn * cnn_probability
        + (1.0 - bundle.alpha_cnn) * rf_probability
    )
    predicted_index = int(np.argmax(hybrid_probability))
    total_ms = (perf_counter() - total_start) * 1_000.0

    psd = np.abs(
        np.fft.fftshift(np.fft.fft(received * signal.windows.hann(len(received), sym=False)))
    ) ** 2
    psd_db = 10.0 * np.log10(psd / (np.max(psd) + 1e-12) + 1e-12)
    frequency = np.fft.fftshift(np.fft.fftfreq(len(received)))

    return {
        "modulation": modulation,
        "snr_db": channel.snr_db,
        "seed": seed,
        "clean": clean,
        "received": received,
        "channel": channel_metadata,
        "features": features,
        "rf_probability": rf_probability,
        "cnn_probability": cnn_probability,
        "hybrid_probability": hybrid_probability,
        "prediction": bundle.classes[predicted_index],
        "confidence": float(hybrid_probability[predicted_index]),
        "correct": bundle.classes[predicted_index] == modulation,
        "frequency": frequency,
        "psd_db": psd_db,
        "latency_ms": {
            "features": feature_ms,
            "rf": rf_ms,
            "cnn": cnn_ms,
            "total": total_ms,
        },
    }


def sweep_classes(
    bundle: ModelBundle,
    channel: ChannelConfig,
    seed: int,
) -> list[dict[str, Any]]:
    """Run one fresh sample for every supported modulation."""

    rows = []
    for class_index, modulation in enumerate(bundle.classes):
        result = infer_frame(bundle, modulation, channel, seed + class_index * 1_009)
        rows.append(
            {
                "Ground truth": modulation,
                "Hybrid prediction": result["prediction"],
                "Confidence (%)": round(result["confidence"] * 100.0, 2),
                "Outcome": "Correct" if result["correct"] else "Incorrect",
                "Latency (ms)": round(result["latency_ms"]["total"], 2),
            }
        )
    return rows
