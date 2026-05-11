#!/usr/bin/env python3
"""Build E3 latency-histogram ledger and optional plot manifest."""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from traffic_expectations import expected_total, tolerance_for

PANEL_ORDER = ("pre_rbcam", "post_rbcam", "feb_egress", "opq_ingress", "opq_egress")
DEFAULT_BOUNDS = {
    "pre_rbcam": (0, 2000),
    "post_rbcam": (2000, 2200),
    "feb_egress": (2049, 6143),
    "opq_ingress": (2049, 6159),
    "opq_egress": (4300, 100000),
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def synthetic_input() -> dict[str, Any]:
    mode = "A"
    mask = "M4"
    rate = "R1"
    run_seconds = 30.0
    sample_count = int(expected_total(mode, mask, rate, run_seconds))
    panels: dict[str, Any] = {}
    for name, (lo, hi) in DEFAULT_BOUNDS.items():
        mid = (lo + hi) // 2
        panels[name] = {
            "bound_lo": lo,
            "bound_hi": hi,
            "p05": lo + max(1, (hi - lo) // 20),
            "p50": mid,
            "p95": hi - max(1, (hi - lo) // 20),
            "in_bound_fraction": 1.0,
            "sample_count": sample_count,
            "histogram": [[mid, sample_count]],
        }
    return {
        "schema_version": 1,
        "cohort": "SYN",
        "matrix_id": "SYN_A_M4_R1",
        "mode": mode,
        "mask": mask,
        "rate": rate,
        "run_seconds": run_seconds,
        "source": "synthetic",
        "panels": panels,
    }


def load_input(path: Path | None, use_synthetic: bool) -> dict[str, Any]:
    if use_synthetic:
        return synthetic_input()
    if path is None:
        raise SystemExit("ERROR: --input is required unless --synthetic is used")
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise SystemExit("ERROR: latency input must be a JSON object")
    return data


def find_reference_generator() -> str | None:
    root = Path("/home/yifeng/packages/mu3e_ip_dev/.worktrees/mu3e_ip_cores_hit_type0_mux_20260504")
    base = root / "firmware_builds/systems/system_20260504_emulator_type0/tb_int/feb_swb_corun"
    if not base.exists():
        return None
    candidates: list[Path] = []
    for pattern in (
        "report_*/feb_swb_lifetime_hist.py",
        "report_*/feb_swb_lifetime_hist.sh",
        "report_*/feb_swb_lifetime_hist.f90",
        "report_*/feb_swb_lifetime_hist.c",
        "report_*/plot_latency_hists.py",
        "scripts/*lifetime*hist*.py",
        "scripts/*latency*hist*.py",
    ):
        candidates.extend(sorted(base.glob(pattern)))
    if candidates:
        return candidates[0].as_posix()
    reference_pngs = sorted(base.glob("report_*/feb_swb_lifetime_hist.png"))
    if reference_pngs:
        return reference_pngs[0].as_posix()
    return None


def panel_status(name: str, panel: dict[str, Any]) -> tuple[bool, dict[str, Any]]:
    lo, hi = DEFAULT_BOUNDS[name]
    bound_lo = int(panel.get("bound_lo", lo))
    bound_hi = int(panel.get("bound_hi", hi))
    p05 = float(panel.get("p05", bound_lo))
    p50 = float(panel.get("p50", (bound_lo + bound_hi) / 2.0))
    p95 = float(panel.get("p95", bound_hi))
    in_bound_fraction = float(panel.get("in_bound_fraction", 0.0))
    ok = (
        in_bound_fraction >= 0.99
        and bound_lo <= p05 <= bound_hi
        and bound_lo <= p50 <= bound_hi
        and bound_lo <= p95 <= bound_hi
    )
    summary = {
        "panel": name,
        "bound_lo": bound_lo,
        "bound_hi": bound_hi,
        "p05": p05,
        "p50": p50,
        "p95": p95,
        "in_bound_fraction": in_bound_fraction,
        "pass": ok,
    }
    return ok, summary


def panel_sample_count(panel: dict[str, Any]) -> int:
    if "sample_count" in panel:
        return int(panel["sample_count"])
    histogram = panel.get("histogram")
    if isinstance(histogram, list):
        total = 0
        for item in histogram:
            if isinstance(item, list) and len(item) >= 2:
                total += int(item[1])
            elif isinstance(item, dict):
                total += int(item.get("count", item.get("samples", 0)))
        return total
    return 0


def build_manifest(data: dict[str, Any], reference: str | None) -> dict[str, Any]:
    raw_panels = data.get("panels")
    if not isinstance(raw_panels, dict):
        raise SystemExit("ERROR: latency input must contain a panels object")

    mode = str(data.get("mode") or "A").upper()
    mask = str(data.get("mask") or "M0").upper()
    rate = data.get("rate_hz", data.get("rate", "R1"))
    run_seconds = float(data.get("run_seconds") or 30.0)
    expected_samples = expected_total(mode, mask, rate, run_seconds)
    sample_tolerance = tolerance_for(mode, expected_samples, data.get("tolerance"))
    failures: list[dict[str, Any]] = []
    panel_summaries: list[dict[str, Any]] = []
    for index, name in enumerate(PANEL_ORDER, start=1):
        raw_panel = raw_panels.get(name)
        if not isinstance(raw_panel, dict):
            failure = {"stage": f"L{index}", "panel": name, "reason": "missing panel"}
            failures.append(failure)
            panel_summaries.append({"panel": name, "pass": False, "reason": "missing"})
            continue
        samples = panel_sample_count(raw_panel)
        if expected_samples > 0 and abs(float(samples) - expected_samples) > sample_tolerance:
            failure = {
                "stage": f"L{index}",
                "panel": name,
                "reason": "sample count does not match programmed traffic",
                "expected": expected_samples,
                "observed": samples,
                "tolerance": sample_tolerance,
            }
            if not failures:
                failures.append(failure)
            panel_summaries.append(
                {
                    "panel": name,
                    "pass": False,
                    "sample_count": samples,
                    "reason": failure["reason"],
                }
            )
            continue
        ok, summary = panel_status(name, raw_panel)
        summary["sample_count"] = samples
        panel_summaries.append(summary)
        if not ok and not failures:
            failures.append({"stage": f"L{index}", "panel": name, "summary": summary})

    if failures:
        first = failures[0]
        status = f"FAIL_AT_{first['stage']}"
        detail = json.dumps(first, sort_keys=True)
    else:
        status = "PASS"
        detail = "all latency panels satisfy bounds"

    return {
        "schema_version": 1,
        "evidence_kind": "E3_latency_histogram",
        "cohort": data.get("cohort", "UNKNOWN"),
        "matrix_id": data.get("matrix_id", "UNKNOWN"),
        "chain": "latency",
        "status": status,
        "stage": failures[0]["stage"] if failures else "L5",
        "detail": detail,
        "mode": mode,
        "mask": mask,
        "rate": rate,
        "run_seconds": run_seconds,
        "expected_samples": expected_samples,
        "reference_generator": reference,
        "plot_png": data.get("plot_png"),
        "todo": (
            "Invoke the reference DISLIN generator for final PNG rendering."
            if reference is None or str(reference).endswith(".png")
            else ""
        ),
        "panels": panel_summaries,
        "failures": failures,
        "generated_at": utc_now(),
    }


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="panel summary JSON")
    parser.add_argument("--out", type=Path, required=True, help="manifest ledger JSON")
    parser.add_argument("--reference-generator", help="explicit reference generator path")
    parser.add_argument("--synthetic", action="store_true", help="use built-in passing panels")
    args = parser.parse_args()

    data = load_input(args.input, args.synthetic)
    reference = args.reference_generator or find_reference_generator()
    result = build_manifest(data, reference)
    write_json(args.out, result)
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
