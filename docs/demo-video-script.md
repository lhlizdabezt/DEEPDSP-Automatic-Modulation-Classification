# Five-Minute Demonstration Script

## Preparation

- Open the executed notebook and DEEPDSP-AMC Workbench side by side.
- Keep browser zoom between 90% and 100%.
- In the app, set `16QAM`, `SNR = 3 dB`, seed `22207056`, echo `0.20`, and CFO `0.002` cycles per sample.
- Do not retrain during the recording; the app loads the released artifacts.
- Target a total duration between 4 minutes 50 seconds and 5 minutes 10 seconds.

## 00:00 to 00:25 | Introduction

Introduce Luong Hai Long, student ID 22207056, class 24DTV_DKD2. State that DEEPDSP-AMC compares a DSP-feature Random Forest with a compact 1D CNN for six-class modulation recognition.

## 00:25 to 01:05 | Signal model and dataset

Show the six classes, the 256-sample frame, eight samples per symbol, and the SNR range from -12 dB to 18 dB. Explain that the 6,600 frames are generated inside the notebook and pass through RRC shaping, phase and frequency offsets, a weak reflected path, and AWGN. Clarify that SNR is not a classifier input.

## 01:05 to 01:45 | DSP views

Show the I/Q waveform, constellation, and power spectral density. Explain that PSK structure is mainly angular, 16QAM contains amplitude and phase structure, and FSK is clearer in frequency. Mention the Hann-window FFT and Welch spectral view.

## 01:45 to 02:35 | Classifiers and fusion

Explain the 18 DSP features and 400-tree Random Forest. Then show the four CNN channels: I, Q, magnitude, and sine of phase difference. State that CompactIQCNN has 81,030 trainable parameters and is CPU-compatible. Explain that the fusion weight is selected only on validation data.

## 02:35 to 03:35 | Results

Report the fixed test-set values: Random Forest 58.48% accuracy and 58.17% macro F1; CNN 71.82% and 72.01%; hybrid 73.48% and 73.40%. Note that hybrid accuracy reaches 90.00% at 9 dB. Point out the remaining QPSK and 8PSK confusion at low SNR.

## 03:35 to 04:30 | Live workbench

Choose **Generate and classify**. Show that the frame is generated from the visible seed, then inspect I/Q, the constellation, PSD, class probabilities, realized channel parameters, and the execution log. State that the app runs both models for the current frame and does not display a stored result.

## 04:30 to 05:00 | Conclusion and boundary

Summarize the improvement from the feature baseline to the compact CNN and hybrid. Close with the main limitation: the study uses controlled simulation. The next experiment is a locked-protocol evaluation on labeled RTL-SDR or USRP captures, including domain-shift and calibration analysis.

## Final checks

- State the student, class, and instructor within the first ten seconds.
- Read all reported values exactly.
- Show an actual app interaction and updated plots.
- Never describe the results as SDR or live-radio validation.

