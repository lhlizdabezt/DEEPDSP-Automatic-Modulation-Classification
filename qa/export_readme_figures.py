"""Export English README figures from the locked DEEPDSP-AMC result files."""

from __future__ import annotations

import csv
import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"
OUTPUT = ROOT / "assets" / "readme"
CLASSES = ("BPSK", "QPSK", "8PSK", "16QAM", "2FSK", "4FSK")
COLORS = {"rf": "#315f9f", "cnn": "#d9860b", "hybrid": "#07818e"}


def load_rows() -> list[dict[str, str]]:
    with (RESULTS / "test_predictions.csv").open(encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream))


def accuracy_by_snr(rows: list[dict[str, str]], prediction_key: str) -> tuple[list[int], list[float]]:
    snr_values = sorted({int(row["snr_db"]) for row in rows})
    accuracy = []
    for snr in snr_values:
        subset = [row for row in rows if int(row["snr_db"]) == snr]
        accuracy.append(100.0 * sum(row[prediction_key] == row["true_label"] for row in subset) / len(subset))
    return snr_values, accuracy


def export_accuracy(rows: list[dict[str, str]]) -> None:
    figure, axis = plt.subplots(figsize=(10.8, 6.2), constrained_layout=True)
    for label, key, marker, color in (
        ("Random Forest", "rf_prediction", "o", COLORS["rf"]),
        ("CompactIQCNN", "cnn_prediction", "s", COLORS["cnn"]),
        ("Hybrid", "hybrid_prediction", "D", COLORS["hybrid"]),
    ):
        snr, accuracy = accuracy_by_snr(rows, key)
        axis.plot(snr, accuracy, marker=marker, linewidth=2.7, markersize=7, label=label, color=color)
    axis.axhspan(90, 100, color="#18794e", alpha=0.07)
    axis.set(title="Test Accuracy by Signal-to-Noise Ratio", xlabel="SNR (dB)", ylabel="Accuracy (%)")
    axis.set_xticks(snr)
    axis.set_ylim(10, 102)
    axis.grid(True, alpha=0.2)
    axis.legend(frameon=False, ncol=3, loc="upper left")
    figure.savefig(OUTPUT / "accuracy_by_snr.png", dpi=180, facecolor="white")
    plt.close(figure)


def export_confusion(rows: list[dict[str, str]]) -> None:
    index = {label: position for position, label in enumerate(CLASSES)}
    matrix = np.zeros((len(CLASSES), len(CLASSES)), dtype=float)
    for row in rows:
        matrix[index[row["true_label"]], index[row["hybrid_prediction"]]] += 1
    matrix = 100.0 * matrix / matrix.sum(axis=1, keepdims=True)

    figure, axis = plt.subplots(figsize=(8.3, 7.1), constrained_layout=True)
    image = axis.imshow(matrix, cmap="Blues", vmin=0, vmax=100)
    for row in range(len(CLASSES)):
        for column in range(len(CLASSES)):
            color = "white" if matrix[row, column] >= 58 else "#16212b"
            axis.text(column, row, f"{matrix[row, column]:.1f}", ha="center", va="center", color=color, fontsize=10)
    axis.set(
        title="Hybrid Classifier Confusion Matrix",
        xlabel="Predicted modulation",
        ylabel="True modulation",
        xticks=range(len(CLASSES)),
        yticks=range(len(CLASSES)),
        xticklabels=CLASSES,
        yticklabels=CLASSES,
    )
    figure.colorbar(image, ax=axis, label="Row percentage (%)", shrink=0.82)
    figure.savefig(OUTPUT / "hybrid_confusion_matrix.png", dpi=180, facecolor="white")
    plt.close(figure)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    rows = load_rows()
    if len(rows) != 1320:
        raise ValueError(f"Expected 1320 test rows, found {len(rows)}")
    metrics = json.loads((RESULTS / "metrics.json").read_text(encoding="utf-8"))
    if metrics["hybrid"]["accuracy"] != sum(row["hybrid_prediction"] == row["true_label"] for row in rows) / len(rows):
        raise ValueError("Prediction CSV and metrics JSON disagree")
    export_accuracy(rows)
    export_confusion(rows)
    print("README figure export: PASS")


if __name__ == "__main__":
    main()

