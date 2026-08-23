"""Streamlit front end for the DEEPDSP-AMC project demonstration."""

from __future__ import annotations

from datetime import datetime
from html import escape
from pathlib import Path
import random
import sys

import numpy as np
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import streamlit as st

APP_DIR = Path(__file__).resolve().parent
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))

from dsp_engine import (
    CLASSES,
    FEATURE_NAMES,
    ChannelConfig,
    infer_frame,
    load_models,
    sweep_classes,
)


PLOT_CONFIG = {
    "displaylogo": False,
    "modeBarButtonsToRemove": ["lasso2d", "select2d"],
    "scrollZoom": False,
}
PLOT_FONT = "Aptos, Segoe UI, sans-serif"
COLORS = {
    "ink": "#0a1929",
    "muted": "#64788c",
    "line": "#d9e3ec",
    "cyan": "#07818e",
    "cyan_light": "#63c7cf",
    "amber": "#d9860b",
    "blue": "#315f9f",
    "green": "#18794e",
    "red": "#c13d3d",
    "plot_bg": "#fbfcfe",
    "grid": "#e6edf3",
    "blue_fill": "rgba(49, 95, 159, 0.10)",
    "paper": "#ffffff",
    "transparent": "rgba(255,255,255,0)",
}


st.set_page_config(
    page_title="DEEPDSP-AMC | DSP/ML Workbench",
    page_icon="📡",
    layout="wide",
    initial_sidebar_state="collapsed",
)
st.markdown(f"<style>{(APP_DIR / 'tokens.css').read_text(encoding='utf-8')}</style>", unsafe_allow_html=True)


@st.cache_resource(show_spinner=False)
def cached_models():
    return load_models(APP_DIR)


def append_log(stage: str, message: str) -> None:
    st.session_state.setdefault("event_log", []).append(
        {
            "Time": datetime.now().strftime("%H:%M:%S.%f")[:-3],
            "Stage": stage,
            "Message": message,
        }
    )


def run_one(modulation: str, snr_db: int, seed: int, max_echo: float, max_cfo: float):
    append_log("INPUT", f"New request: {modulation}, SNR={snr_db} dB, seed={seed}")
    channel = ChannelConfig(snr_db=snr_db, max_echo=max_echo, max_cfo=max_cfo)
    result = infer_frame(cached_models(), modulation, channel, seed)
    ch = result["channel"]
    append_log(
        "CHANNEL",
        "Two-ray channel: delay={} samples, echo={:.3f}, CFO={:+.6f} cycles/sample".format(
            ch["delay_samples"], ch["echo_amplitude"], ch["cfo_cycles_per_sample"]
        ),
    )
    append_log("DSP", f"Extracted 18 features in {result['latency_ms']['features']:.2f} ms")
    append_log(
        "INFERENCE",
        "RF={:.2f} ms; CNN={:.2f} ms; fusion α={:.2f}".format(
            result["latency_ms"]["rf"],
            result["latency_ms"]["cnn"],
            cached_models().alpha_cnn,
        ),
    )
    append_log(
        "RESULT",
        f"Label={result['modulation']} -> prediction={result['prediction']} "
        f"({result['confidence'] * 100:.2f}%)",
    )
    st.session_state["result"] = result


def plot_waveform(result: dict) -> go.Figure:
    samples = np.arange(len(result["received"]))
    figure = make_subplots(rows=2, cols=1, shared_xaxes=True, vertical_spacing=0.08)
    figure.add_trace(
        go.Scatter(x=samples, y=result["received"].real, name="I[n]", line={"color": COLORS["cyan"], "width": 1.5}),
        row=1,
        col=1,
    )
    figure.add_trace(
        go.Scatter(x=samples, y=result["received"].imag, name="Q[n]", line={"color": COLORS["amber"], "width": 1.35}),
        row=2,
        col=1,
    )
    figure.update_yaxes(title_text="I amplitude", row=1, col=1)
    figure.update_yaxes(title_text="Q amplitude", row=2, col=1)
    figure.update_xaxes(title_text="Sample index n", row=2, col=1)
    return style_figure(figure, 350, "Received I/Q waveform")


def plot_constellation(result: dict) -> go.Figure:
    received = result["received"]
    symbol_samples = received[4::8]
    figure = go.Figure()
    figure.add_trace(
        go.Scattergl(
            x=received.real,
            y=received.imag,
            mode="markers",
            name="All samples",
            marker={"size": 5, "color": COLORS["cyan_light"], "opacity": 0.35},
        )
    )
    figure.add_trace(
        go.Scattergl(
            x=symbol_samples.real,
            y=symbol_samples.imag,
            mode="markers",
            name="Every eighth sample",
            marker={"size": 8, "color": COLORS["ink"], "opacity": 0.82, "symbol": "diamond"},
        )
    )
    figure.update_xaxes(title="In-phase I", zeroline=True, zerolinecolor=COLORS["line"])
    figure.update_yaxes(title="Quadrature Q", scaleanchor="x", scaleratio=1, zeroline=True, zerolinecolor=COLORS["line"])
    return style_figure(figure, 350, "Received constellation")


def plot_psd(result: dict) -> go.Figure:
    figure = go.Figure(
        go.Scatter(
            x=result["frequency"],
            y=result["psd_db"],
            fill="tozeroy",
            line={"color": COLORS["blue"], "width": 1.7},
            fillcolor=COLORS["blue_fill"],
            name="Normalized PSD",
        )
    )
    figure.update_xaxes(title="Normalized frequency f / fs")
    figure.update_yaxes(title="Relative power (dB)", range=[-65, 4])
    return style_figure(figure, 350, "Power spectral density")


def plot_probabilities(result: dict) -> go.Figure:
    methods = (
        ("RF", result["rf_probability"], COLORS["amber"]),
        ("CNN", result["cnn_probability"], COLORS["blue"]),
        ("Hybrid", result["hybrid_probability"], COLORS["cyan"]),
    )
    figure = go.Figure()
    for name, probability, color in methods:
        figure.add_trace(
            go.Bar(
                y=list(CLASSES),
                x=probability * 100.0,
                name=name,
                orientation="h",
                marker_color=color,
                text=[f"{value * 100:.1f}%" for value in probability],
                textposition="outside",
                cliponaxis=False,
            )
        )
    figure.update_layout(barmode="group", legend_orientation="h", legend_y=1.14)
    figure.update_xaxes(title="Posterior probability (%)", range=[0, 108])
    figure.update_yaxes(categoryorder="array", categoryarray=list(reversed(CLASSES)))
    return style_figure(figure, 420, "RF, CNN, and hybrid decisions")


def style_figure(figure: go.Figure, height: int, title: str) -> go.Figure:
    figure.update_layout(
        title={"text": title, "font": {"size": 17, "color": COLORS["ink"]}, "x": 0.02},
        height=height,
        margin={"l": 50, "r": 28, "t": 62, "b": 46},
        paper_bgcolor=COLORS["transparent"],
        plot_bgcolor=COLORS["plot_bg"],
        font={"family": PLOT_FONT, "color": COLORS["muted"], "size": 12},
        hoverlabel={"bgcolor": COLORS["ink"], "font_color": COLORS["paper"]},
        legend={"font": {"size": 11}},
    )
    figure.update_xaxes(gridcolor=COLORS["grid"], linecolor=COLORS["line"], mirror=True)
    figure.update_yaxes(gridcolor=COLORS["grid"], linecolor=COLORS["line"], mirror=True)
    return figure


def metric_ribbon(result: dict) -> str:
    status = "CORRECT" if result["correct"] else "INCORRECT"
    status_class = "status-ok" if result["correct"] else "status-error"
    return f"""
    <div class="metric-ribbon">
      <div class="metric-cell"><div class="metric-label">Transmitted label</div><div class="metric-value">{result['modulation']}</div><div class="metric-note">ground truth</div></div>
      <div class="metric-cell"><div class="metric-label">Hybrid decision</div><div class="metric-value {status_class}">{status}</div><div class="metric-note">against ground truth</div></div>
      <div class="metric-cell"><div class="metric-label">Configured SNR</div><div class="metric-value">{result['snr_db']:+.0f} dB</div><div class="metric-note">AWGN after two-ray channel</div></div>
      <div class="metric-cell"><div class="metric-label">End-to-end latency</div><div class="metric-value">{result['latency_ms']['total']:.2f} ms</div><div class="metric-note">one 256-sample frame</div></div>
    </div>
    """


def render_logs() -> None:
    logs = st.session_state.get("event_log", [])
    if not logs:
        st.caption("No events yet.")
        return
    html = "".join(
        "<div class='log-line'><span class='log-time'>{}</span><span class='log-stage'>{}</span><span class='log-message'>{}</span></div>".format(
            escape(row["Time"]), escape(row["Stage"]), escape(row["Message"])
        )
        for row in reversed(logs[-18:])
    )
    st.markdown(html, unsafe_allow_html=True)


st.markdown(
    """
    <section class="hero">
      <div>
        <div class="eyebrow">24DTV_DKD2 · Digital Signal Processing Laboratory</div>
        <h1>DEEPDSP-AMC Workbench</h1>
        <p>Automatic classification of six digital modulation formats over an AWGN and multipath channel using DSP features, Random Forest, a compact 1D CNN, and weighted probability fusion.</p>
      </div>
      <div class="identity">
        <strong>Lương Hải Long · 22207056</strong>
        <span>Digital Signal Processing Laboratory</span>
        <span>Instructor: Huynh Quoc Thinh, M.Sc.</span>
        <span>HCMUS · Electronics & Telecommunications</span>
      </div>
    </section>
    """,
    unsafe_allow_html=True,
)

try:
    models = cached_models()
except Exception as error:
    st.error(f"Unable to load the models: {error}")
    st.stop()

if "event_log" not in st.session_state:
    st.session_state.event_log = []
if "result" not in st.session_state:
    append_log("BOOT", f"Loaded models from {models.model_dir}")
    append_log("MODEL", f"RF=400 trees; CNN={models.parameter_count:,} parameters; device={models.device.type}")
    run_one("16QAM", 3, 22207056, 0.20, 0.002)

control_column, evidence_column = st.columns([0.82, 2.18], gap="large")
with control_column:
    st.markdown('<div class="section-kicker">Control plane</div><div class="section-title">Experiment settings</div>', unsafe_allow_html=True)
    with st.form("control_form", border=True):
        modulation = st.selectbox("Transmitted modulation", CLASSES, index=3)
        snr_db = st.slider("AWGN channel SNR (dB)", min_value=-12, max_value=18, value=3, step=3)
        seed = st.number_input("Reproducibility seed", min_value=0, max_value=99_999_999, value=22_207_056, step=1)
        st.markdown("**Channel impairments**")
        max_echo = st.slider("Maximum echo amplitude", 0.0, 0.30, 0.20, 0.01)
        max_cfo_milli = st.slider("Maximum CFO (x10^-3 cycles/sample)", 0.0, 4.0, 2.0, 0.1)
        run_clicked = st.form_submit_button("Generate and classify", type="primary", width="stretch")
        sweep_clicked = st.form_submit_button("Sweep all six classes", width="stretch")

    random_col, clear_col = st.columns(2)
    with random_col:
        random_clicked = st.button("Random sample", width="stretch")
    with clear_col:
        if st.button("Clear log", width="stretch"):
            st.session_state.event_log = []
            st.rerun()

    st.markdown("##### Models in service")
    st.caption(f"RF pipeline + CompactIQCNN on `{models.device.type.upper()}`")
    st.dataframe(
        pd.DataFrame(
            [
                {"Block": "RF", "Scale": "400 trees", "Role": "18 DSP features"},
                {"Block": "CNN", "Scale": f"{models.parameter_count:,} parameters", "Role": "I/Q, magnitude, phase"},
                {"Block": "Fusion", "Scale": f"alpha={models.alpha_cnn:.2f}", "Role": "Weighted probability mean"},
            ]
        ),
        hide_index=True,
        width="stretch",
    )

with evidence_column:
    st.markdown('<div class="section-kicker">Evidence plane</div><div class="section-title">Observation and decision</div>', unsafe_allow_html=True)
    result = st.session_state.result
    prediction_class = "prediction" if result["correct"] else "prediction incorrect"
    st.markdown(
        f"""
        <div class="{prediction_class}">
          <div><div class="label">Hybrid prediction</div><div class="answer">{result['prediction']}</div></div>
          <div class="confidence"><div class="label">Confidence</div><strong>{result['confidence'] * 100:.2f}%</strong></div>
        </div>
        {metric_ribbon(result)}
        """,
        unsafe_allow_html=True,
    )
    wave_column, constellation_column = st.columns(2, gap="medium")
    with wave_column:
        st.plotly_chart(plot_waveform(result), width="stretch", config=PLOT_CONFIG)
    with constellation_column:
        st.plotly_chart(plot_constellation(result), width="stretch", config=PLOT_CONFIG)

    psd_column, probability_column = st.columns([0.92, 1.08], gap="medium")
    with psd_column:
        st.plotly_chart(plot_psd(result), width="stretch", config=PLOT_CONFIG)
    with probability_column:
        st.plotly_chart(plot_probabilities(result), width="stretch", config=PLOT_CONFIG)

if run_clicked:
    with st.status("Running DSP -> ML/DL -> fusion...", expanded=True) as status:
        st.write("Generating a baseband frame and simulating a two-ray AWGN channel")
        st.write("Extracting 18 DSP features and a four-channel tensor")
        run_one(modulation, snr_db, int(seed), max_echo, max_cfo_milli / 1_000.0)
        st.write("Running RF/CNN inference, probability fusion, and plot updates")
        status.update(label="Reproducible experiment complete", state="complete", expanded=False)
    st.rerun()

if random_clicked:
    random_modulation = random.choice(CLASSES)
    random_snr = random.choice(list(range(-12, 19, 3)))
    random_seed = random.randint(0, 99_999_999)
    run_one(random_modulation, random_snr, random_seed, max_echo, max_cfo_milli / 1_000.0)
    st.rerun()

if sweep_clicked:
    with st.status("Sweeping six modulation formats...", expanded=True) as status:
        sweep = sweep_classes(
            models,
            ChannelConfig(snr_db=snr_db, max_echo=max_echo, max_cfo=max_cfo_milli / 1_000.0),
            int(seed),
        )
        st.session_state.sweep = sweep
        correct = sum(row["Outcome"] == "Correct" for row in sweep)
        append_log("SWEEP", f"Swept six classes at {snr_db:+d} dB: {correct}/6 correct predictions")
        status.update(label=f"Complete: {correct}/6 classes correct", state="complete", expanded=False)
    st.rerun()

result = st.session_state.result

if "sweep" in st.session_state:
    with st.container(border=True):
        st.markdown("#### Six-class spot check")
        sweep_frame = pd.DataFrame(st.session_state.sweep)
        st.dataframe(sweep_frame, hide_index=True, width="stretch")
        st.caption("Each row uses a fresh frame. This demonstration does not replace the 1,320-frame test-set evaluation.")

feature_tab, channel_tab, log_tab = st.tabs(["18 DSP features", "Realized channel parameters", "Execution log"])
with feature_tab:
    feature_frame = pd.DataFrame(
        {"Feature": FEATURE_NAMES, "Value": result["features"]}
    )
    st.dataframe(
        feature_frame.style.format({"Value": "{:.6f}"}),
        hide_index=True,
        width="stretch",
        height=370,
    )
with channel_tab:
    channel_rows = [
        {"Parameter": name, "Value": value}
        for name, value in result["channel"].items()
    ]
    st.dataframe(pd.DataFrame(channel_rows), hide_index=True, width="stretch")
    st.caption("The displayed seed generates these coefficients; repeat the same settings to reproduce the frame.")
with log_tab:
    render_logs()
    log_frame = pd.DataFrame(st.session_state.event_log)
    st.download_button(
        "Download CSV log",
        data=log_frame.to_csv(index=False).encode("utf-8-sig"),
        file_name="deepdsp_amc_demo_log.csv",
        mime="text/csv",
    )

st.caption(
    "DEEPDSP-AMC | Synthetic signals follow the channel model documented in the report | "
    "The app computes predictions from the trained models at run time; no displayed result is precomputed."
)
