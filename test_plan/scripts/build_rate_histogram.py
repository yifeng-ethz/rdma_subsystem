#!/usr/bin/env python3
"""Build and check E2 per-channel rate histograms."""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from traffic_expectations import (
    N_CHANNELS,
    active_channels,
    expected_per_channel,
    expected_total,
    get_first_stage_delta,
    rate_hz,
    tolerance_for,
)


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def synthetic_input() -> dict[str, Any]:
    mask = "M4"
    mode = "A"
    rate = "R1"
    run_seconds = 30.0
    count = int(expected_per_channel(mode, rate, run_seconds))
    ingress = [0] * N_CHANNELS
    egress = [0] * N_CHANNELS
    ingress[0] = count
    egress[0] = count
    return {
        "schema_version": 1,
        "cohort": "SYN",
        "matrix_id": "SYN_A_M4_R1",
        "mode": mode,
        "mask": mask,
        "rate": rate,
        "run_seconds": run_seconds,
        "feb_rate_emulator_delta": sum(ingress),
        "ingress_bins": ingress,
        "egress_bins": egress,
    }


def load_input(path: Path | None, use_synthetic: bool) -> dict[str, Any]:
    if use_synthetic:
        return synthetic_input()
    if path is None:
        raise SystemExit("ERROR: --input is required unless --synthetic is used")
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise SystemExit("ERROR: rate input must be a JSON object")
    return data


def get_bins(data: dict[str, Any], key: str) -> list[int]:
    bins = data.get(key)
    if not isinstance(bins, list):
        raise SystemExit(f"ERROR: missing list {key}")
    if len(bins) != N_CHANNELS:
        raise SystemExit(f"ERROR: {key} must contain {N_CHANNELS} bins")
    return [int(value) for value in bins]


def check_rate_histogram(data: dict[str, Any]) -> dict[str, Any]:
    ingress = get_bins(data, "ingress_bins")
    egress = get_bins(data, "egress_bins")
    mode = str(data.get("mode") or "A").upper()
    mask = str(data.get("mask") or "M0").upper()
    run_seconds = float(data.get("run_seconds") or 30.0)
    expected_rate = rate_hz(data.get("rate_hz", data.get("rate", "R1")))
    active = active_channels(mask)
    tolerance = data.get("tolerance")
    failures: list[dict[str, Any]] = []
    expected_ch = expected_per_channel(mode, expected_rate, run_seconds)
    expected_all = expected_total(mode, mask, expected_rate, run_seconds)
    expected_all_tol = tolerance_for(mode, expected_all, tolerance)
    first_stage_delta = get_first_stage_delta(data, ingress)

    if expected_all > 0:
        if first_stage_delta is None:
            failures.append(
                {
                    "stage": "C1",
                    "reason": "missing FEB/rate_emulator first-stage delta",
                    "expected_min_delta": 1,
                }
            )
        elif first_stage_delta <= 0:
            failures.append(
                {
                    "stage": "C1",
                    "counter": "first_stage_delta",
                    "expected_min_delta": 1,
                    "observed": first_stage_delta,
                    "reason": "programmed nonzero traffic produced zero FEB-side delta",
                }
            )
        elif abs(float(first_stage_delta) - expected_all) > expected_all_tol:
            failures.append(
                {
                    "stage": "C1",
                    "counter": "first_stage_delta",
                    "expected": expected_all,
                    "observed": first_stage_delta,
                    "tolerance": expected_all_tol,
                }
            )

    for ch in range(N_CHANNELS):
        if failures:
            break
        if ch not in active:
            if ingress[ch] != 0 or egress[ch] != 0:
                failures.append(
                    {
                        "stage": "R1",
                        "channel": ch,
                        "expected": 0,
                        "observed_ingress": ingress[ch],
                        "observed_egress": egress[ch],
                    }
                )
                break
            continue
        hist_tol = tolerance_for(mode, ingress[ch], tolerance)
        if abs(egress[ch] - ingress[ch]) > hist_tol:
            failures.append(
                {
                    "stage": "R3",
                    "channel": ch,
                    "expected": ingress[ch],
                    "observed": egress[ch],
                    "tolerance": hist_tol,
                }
            )
            break
        rate_tol = tolerance_for(mode, expected_ch, tolerance)
        if abs(float(egress[ch]) - expected_ch) > rate_tol:
            failures.append(
                {
                    "stage": "R1",
                    "channel": ch,
                    "expected": expected_ch,
                    "observed": egress[ch],
                    "tolerance": rate_tol,
                }
            )
            break

    if failures:
        first = failures[0]
        status = f"FAIL_AT_{first['stage']}"
        detail = json.dumps(first, sort_keys=True)
    else:
        status = "PASS"
        detail = "ingress and egress per-channel histograms match"

    return {
        "schema_version": 1,
        "evidence_kind": "E2_rate_histogram",
        "cohort": data.get("cohort", "UNKNOWN"),
        "matrix_id": data.get("matrix_id", "UNKNOWN"),
        "chain": "rate_chain",
        "status": status,
        "stage": failures[0]["stage"] if failures else "R6",
        "detail": detail,
        "mode": mode,
        "mask": mask,
        "rate_hz": expected_rate,
        "run_seconds": run_seconds,
        "expected_per_channel": expected_ch,
        "expected_total": expected_all,
        "first_stage_delta": first_stage_delta,
        "active_channels": len(active),
        "total_ingress": sum(ingress),
        "total_egress": sum(egress),
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
    parser.add_argument("--input", type=Path, help="histogram JSON")
    parser.add_argument("--out", type=Path, required=True, help="ledger JSON output")
    parser.add_argument("--synthetic", action="store_true", help="use built-in passing input")
    args = parser.parse_args()

    result = check_rate_histogram(load_input(args.input, args.synthetic))
    write_json(args.out, result)
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
