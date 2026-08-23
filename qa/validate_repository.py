"""Deterministic publication checks for DEEPDSP-AMC."""

from __future__ import annotations

import csv
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

from PIL import Image
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "reports" / "24DTV_DKD2_22207056_LuongHaiLong_BanMoTa_DoAn_AMC.pdf"
NOTEBOOK = ROOT / "notebooks" / "24DTV_DKD2_22207056_LuongHaiLong_SourceCode_AMC.ipynb"
EXPECTED_METRICS = {
    "rf_accuracy": 0.5848484848484848,
    "rf_macro_f1": 0.5816903901546325,
    "cnn_accuracy": 0.7181818181818181,
    "cnn_macro_f1": 0.7200705426860555,
    "hybrid_accuracy": 0.7348484848484849,
    "hybrid_macro_f1": 0.7339569603511245,
    "alpha": 0.55,
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def relative_files() -> list[Path]:
    return [path.relative_to(ROOT) for path in ROOT.rglob("*") if path.is_file() and ".git" not in path.parts]


def check_inventory() -> dict[str, int]:
    required = [
        ROOT / "README.md",
        ROOT / "NOTICE.md",
        ROOT / "CITATION.cff",
        NOTEBOOK,
        REPORT,
        ROOT / "results" / "metrics.json",
        ROOT / "results" / "test_predictions.csv",
        ROOT / "demo_app" / "app.py",
        ROOT / "demo_app" / "dsp_engine.py",
        ROOT / "demo_app" / "models" / "rf_dsp_pipeline.joblib",
        ROOT / "demo_app" / "models" / "compact_iq_cnn.pt",
        ROOT / "assets" / "deepdsp-amc-banner.svg",
        ROOT / "assets" / "readme" / "accuracy_by_snr.png",
        ROOT / "assets" / "readme" / "hybrid_confusion_matrix.png",
        ROOT / "assets" / "readme" / "demo_app_english.png",
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    require(not missing, f"Missing required files: {missing}")
    files = relative_files()
    forbidden = [path for path in files if any(part in {".venv", "__pycache__", ".playwright-cli", "tmp"} for part in path.parts)]
    require(not forbidden, f"Forbidden generated files: {forbidden}")
    oversized = [(path, (ROOT / path).stat().st_size) for path in files if (ROOT / path).stat().st_size > 25_000_000]
    require(not oversized, f"Files above 25 MB belong in a release, not Git history: {oversized}")
    return {"files": len(files), "bytes": sum((ROOT / path).stat().st_size for path in files)}


def check_notebook() -> dict[str, int]:
    notebook = json.loads(NOTEBOOK.read_text(encoding="utf-8"))
    cells = notebook.get("cells", [])
    code = [cell for cell in cells if cell.get("cell_type") == "code"]
    executed = [cell for cell in code if cell.get("execution_count") is not None]
    errors = [output for cell in code for output in cell.get("outputs", []) if output.get("output_type") == "error"]
    png_outputs = [
        output
        for cell in code
        for output in cell.get("outputs", [])
        if "image/png" in output.get("data", {})
    ]
    require(len(cells) == 33, f"Expected 33 notebook cells, found {len(cells)}")
    require(len(code) == 22, f"Expected 22 code cells, found {len(code)}")
    require(len(executed) == 22, f"Expected all 22 code cells executed, found {len(executed)}")
    require(not errors, f"Notebook contains {len(errors)} error outputs")
    require(len(png_outputs) == 13, f"Expected 13 embedded PNG outputs, found {len(png_outputs)}")
    return {"cells": len(cells), "code_cells": len(code), "executed": len(executed), "errors": len(errors), "png_outputs": len(png_outputs)}


def check_metrics() -> dict[str, float | int]:
    metrics = json.loads((ROOT / "results" / "metrics.json").read_text(encoding="utf-8"))
    actual = {
        "rf_accuracy": metrics["rf"]["accuracy"],
        "rf_macro_f1": metrics["rf"]["macro_f1"],
        "cnn_accuracy": metrics["cnn"]["accuracy"],
        "cnn_macro_f1": metrics["cnn"]["macro_f1"],
        "hybrid_accuracy": metrics["hybrid"]["accuracy"],
        "hybrid_macro_f1": metrics["hybrid"]["macro_f1"],
        "alpha": metrics["hybrid"]["alpha_cnn_selected_on_validation"],
    }
    for key, expected in EXPECTED_METRICS.items():
        require(abs(actual[key] - expected) < 1e-12, f"Metric drift for {key}: {actual[key]} != {expected}")
    require(metrics["split_sizes"] == {"train": 4488, "validation": 792, "test": 1320}, "Unexpected data split")
    with (ROOT / "results" / "test_predictions.csv").open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))
    require(len(rows) == 1320, f"Expected 1320 test predictions, found {len(rows)}")
    measured = sum(row["hybrid_prediction"] == row["true_label"] for row in rows) / len(rows)
    require(abs(measured - actual["hybrid_accuracy"]) < 1e-12, "CSV predictions disagree with metrics JSON")
    return {**actual, "test_rows": len(rows)}


def check_report() -> dict[str, object]:
    reader = PdfReader(str(REPORT))
    require(len(reader.pages) == 44, f"Expected 44 report pages, found {len(reader.pages)}")
    empty = []
    non_a4 = []
    text = []
    for index, page in enumerate(reader.pages, start=1):
        extracted = page.extract_text() or ""
        text.append(extracted)
        if not extracted.strip():
            empty.append(index)
        width = float(page.mediabox.width)
        height = float(page.mediabox.height)
        if abs(width - 595.28) > 2 or abs(height - 841.89) > 2:
            non_a4.append(index)
    joined = "\n".join(text)
    require(not empty, f"Empty report pages: {empty}")
    require(not non_a4, f"Non-A4 report pages: {non_a4}")
    require("22207056" in joined and "DEEPDSP-AMC" in joined, "Report identity text is missing")
    require("yl5Sk6plWXg" in joined, "Published video URL is missing from report text")
    return {"pages": len(reader.pages), "empty_pages": empty, "page_size": "A4", "text_characters": len(joined)}


def check_images_and_svg() -> dict[str, object]:
    report_figures = sorted((ROOT / "assets" / "figures").glob("*.png"))
    require(len(report_figures) == 15, f"Expected 15 report PNG figures, found {len(report_figures)}")
    images = report_figures + sorted((ROOT / "assets" / "readme").glob("*.png"))
    dimensions = {}
    for path in images:
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            require(image.width >= 600 and image.height >= 450, f"Image is too small: {path.name} {image.size}")
            dimensions[str(path.relative_to(ROOT))] = [image.width, image.height]

    svg_path = ROOT / "assets" / "deepdsp-amc-banner.svg"
    svg_text = svg_path.read_text(encoding="utf-8")
    require(svg_text.isascii(), "Banner SVG must remain ASCII-only")
    tree = ET.fromstring(svg_text)
    forbidden_tags = {"path", "line", "polyline"}
    found = {element.tag.rsplit("}", 1)[-1] for element in tree.iter()}
    require(not (found & forbidden_tags), f"Banner contains forbidden line geometry: {found & forbidden_tags}")

    card_left = 785.0
    card_width = 345.0
    card_center = card_left + card_width / 2
    minimum_padding = 16.0
    banner_labels = {
        "DSP FEATURES AND RANDOM FOREST",
        "COMPACT ONE DIMENSIONAL CNN",
        "WEIGHTED PROBABILITY FUSION",
    }
    text_nodes = {
        "".join(element.itertext()).strip(): element
        for element in tree.iter()
        if element.tag.rsplit("}", 1)[-1] == "text"
    }
    for label in banner_labels:
        node = text_nodes.get(label)
        require(node is not None, f"Banner label is missing: {label}")
        font_size = float(node.attrib.get("font-size", "0"))
        estimated_width = len(label) * font_size * 0.64
        require(node.attrib.get("text-anchor") == "middle", f"Banner label is not centered: {label}")
        require(abs(float(node.attrib.get("x", "0")) - card_center) < 0.01, f"Banner label has the wrong center: {label}")
        require(
            estimated_width <= card_width - 2 * minimum_padding,
            f"Banner label may overflow its card: {label} ({estimated_width:.1f}px estimated)",
        )

    return {
        "report_figures": len(report_figures),
        "checked_images": len(images),
        "dimensions": dimensions,
        "banner_ascii": True,
        "banner_labels_centered": len(banner_labels),
        "banner_minimum_horizontal_padding": minimum_padding,
    }


def check_source_and_docs() -> dict[str, object]:
    app = (ROOT / "demo_app" / "app.py").read_text(encoding="utf-8")
    engine = (ROOT / "demo_app" / "dsp_engine.py").read_text(encoding="utf-8")
    require("predict_proba" in engine and "torch.inference_mode" in engine and "infer_frame" in engine, "Live inference markers are missing")
    banned_ui = ("Không thể", "Nhận dạng", "Dự đoán", "Độ tin cậy", "Thiết lập phép thử", "Đang chạy")
    require(not any(term in app for term in banned_ui), "Vietnamese public app text remains")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    require("Profile Views" not in readme and "komarev" not in readme.lower(), "Profile-view counters belong only in the profile repository")
    require("https://youtu.be/yl5Sk6plWXg" in readme, "Video link is missing from README")
    public_docs = [ROOT / "README.md", ROOT / "NOTICE.md", ROOT / "demo_app" / "README.md"] + list((ROOT / "docs").glob("*"))
    replacement = [path.name for path in public_docs if "\ufffd" in path.read_text(encoding="utf-8")]
    require(not replacement, f"Unicode replacement characters found: {replacement}")
    return {"live_inference": True, "public_documents": len(public_docs), "replacement_characters": 0}


def main() -> int:
    report = {
        "status": "PASS",
        "inventory": check_inventory(),
        "notebook": check_notebook(),
        "metrics": check_metrics(),
        "report": check_report(),
        "visuals": check_images_and_svg(),
        "source_and_docs": check_source_and_docs(),
    }
    destination = ROOT / "qa" / "validation-report.json"
    destination.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        print(f"VALIDATION FAILED: {error}", file=sys.stderr)
        sys.exit(1)
