# DEEPDSP-AMC Demo App

This Streamlit workbench runs the two trained branches released with the project:

- Random Forest on 18 handcrafted DSP features;
- CompactIQCNN on I, Q, magnitude, and phase-difference channels;
- weighted probability fusion with `alpha_cnn = 0.55`.

## Recommended Windows launch

Double-click `RUN_DEMO_APP.cmd`. The launcher creates an isolated `.venv`, installs the compatible dependency set, verifies imports, and opens the app. The first run needs an internet connection and may take several minutes. Later runs reuse the environment.

## Manual launch

```powershell
py -3.14 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --requirement requirements.txt
.\.venv\Scripts\python.exe -m streamlit run app.py
```

The `--requirement` or `-r` flag is required when installing from a requirements file.

The app loads models from `models/`. Every displayed signal, prediction, probability, and log entry is computed when the user runs an experiment; no result is staged for display.

## Suggested demonstration

1. Select `16QAM`, set `SNR = 3 dB`, and keep the default seed.
2. Choose **Generate and classify**.
3. Inspect the I/Q waveform, constellation, PSD, and RF/CNN/hybrid probabilities.
4. Open the feature, channel-parameter, and execution-log tabs.
5. Choose **Sweep all six classes** for a six-frame spot check at the selected SNR.

The sweep is an interactive demonstration, not a substitute for the fixed 1,320-frame test-set evaluation reported by the project.

