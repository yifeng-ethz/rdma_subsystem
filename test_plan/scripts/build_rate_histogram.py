#!/usr/bin/env python3
"""Build and check E2 per-channel rate histograms."""

from __future__ import annotations

import argparse
import json
import math
import os
import random
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

N_CHANNELS = 256


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def active_channels(mask: str) -> set[int]:
    mask = mask.upper()
    all_channels = set(range(N_CHANNELS))
    if mask == "M0":
        return all_channels
    if mask == "M1":
        return set(range(128, N_CHANNELS))
    if mask == "M2":
        return set(range(0, 128))
    if mask == "M3":
        return {ch for ch in range(N_CHANNELS) if ch % 2 == 1}
    if mask == "M4":
        return {0}
    if mask == "M5":
        return all_channels - {0}
    rng = random.Random(1)
    if mask == "M6":
        masked = set(rng.sample(range(N_CHANNELS), int(N_CHANNELS * 0.75)))
        return all_channels - masked
    if mask == "M7":
        masked = set(rng.sample(range(N_CHANNELS), int(N_CHANNELS * 0.25)))
        return all_channels - masked
    raise SystemExit(f"ERROR: unknown mask {mask}")


def rate_hz(rate: str | int | float) -> float:
    if isinstance(rate, (int, float)):
        return float(rate)
    text = str(rate).upper()
    table = {"R1": 10_000.0, "R2": 100_000.0, "R3": 500_000.0, "R4": 1_000_000.0}
    if text in table:
        return table[text]
    return float(text)


def synthetic_input() -> dict[str, Any]:
    mask = "M4"
    run_seconds = 30.0
    count = int(rate_hz("R1") * run_seconds)
    ingress = [0] * N_CHANNELS
    egress = [0] * N_CHANNELS
    ingress[0] = count
    egress[0] = count
    return {
        "schema_version": 1,
        "cohort": "SYN",
        "matrix_id": "SYN_A_M4_R1",
        "mode": "A",
        "mask": mask,
        "rate": "R1",
        "run_seconds": run_seconds,
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


def tolerance_for(mode: str, expected: int, configured: float | int | None) -> float:
    if configured is not None:
        return float(configured)
    if mode.upper() == "C":
        return 5.0 * math.sqrt(max(float(expected), 1.0))
    return max(1.0, abs(float(expected)) * 0.01)


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

    for ch in range(N_CHANNELS):
        if ch not in active:
            if egress[ch] != 0:
                failures.append({"stage": "R3", "channel": ch, "expected": 0, "observed": egress[ch]})
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
        expected_count = expected_rate * run_seconds
        rate_tol = tolerance_for(mode, int(expected_count), tolerance)
        if abs(egress[ch] - expected_count) > rate_tol:
            failures.append(
                {
                    "stage": "R1",
                    "channel": ch,
                    "expected": expected_count,
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
