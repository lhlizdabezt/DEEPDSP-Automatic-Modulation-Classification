# DEEPDSP-AMC v1.0.0

This first public release packages the complete, evidence-backed academic project for automatic six-class digital modulation classification.

## Included

- executed 33-cell notebook with 22 executed code cells and 13 embedded figure outputs;
- 44-page A4 academic report with Typst source;
- English Streamlit workbench and compressed trained models;
- 18-feature Random Forest, 81,030-parameter CompactIQCNN, and validation-selected probability fusion;
- fixed metrics, training history, and 1,320 test predictions;
- 15 original report figures plus English README figures and app capture;
- demonstration video, YouTube metadata, and five-minute script;
- deterministic repository validator and GitHub Actions workflow.

## Locked test results

| Method | Accuracy | Macro F1 |
|---|---:|---:|
| Random Forest | 58.48% | 58.17% |
| CompactIQCNN | 71.82% | 72.01% |
| Hybrid | 73.48% | 73.40% |

The hybrid fusion weight is `0.55`. Test accuracy reaches 90.00% at 9 dB.

## Scope

Results apply to the documented controlled synthetic dataset and fixed split. This release does not claim evaluation on SDR captures or live radio hardware.

## Verification

The source workspace release audit passed notebook execution, report pagination, equations, algorithms, figures, video-script timing, real app-inference markers, package integrity, and Moodle 20 MB limits. The public repository validator independently checks metric drift, prediction-row agreement, PDF extraction, visuals, models, documentation, SVG safety, and repository hygiene.

