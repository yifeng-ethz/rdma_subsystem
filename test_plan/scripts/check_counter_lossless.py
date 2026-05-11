#!/usr/bin/env python3
"""Check E1 per-stage counter conservation and write a chain ledger."""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from traffic_expectations import (
    active_channels,
    check_expected_channels,
    expected_per_channel,
    expected_total,
    get_channel_counts,
    get_first_stage_delta,
    snapshot_delta,
    tolerance_for,
)

STAGES = tuple(f"C{i}" for i in range(1, 10))


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def synthetic_input() -> dict[str, Any]:
    mode = "A"
    mask = "M4"
    rate = "R1"
    run_seconds = 30.0
    per_channel = int(expected_per_channel(mode, rate, run_seconds))
    total = int(expected_total(mode, mask, rate, run_seconds))
    channel_counts = [0] * 256
    for ch in active_channels(mask):
        channel_counts[ch] = per_channel
    counts = {stage: total for stage in STAGES}
    return {
        "schema_version": 1,
        "cohort": "SYN",
        "matrix_id": "SYN_A_M4_R1",
        "mode": mode,
        "mask": mask,
        "rate": rate,
        "run_seconds": run_seconds,
        "feb_rate_emulator_delta": total,
        "channel_counts": channel_counts,
        "stage_counts": counts,
        "bar1": {
            "CNT_OPQ_INPUT_W": total,
            "CNT_BYTES_WRITTEN": total * 4,
            "CNT_SQE_CONSUMED": 1,
            "CNT_CQE_POSTED": 1,
            "CNT_HALT": 0,
            "EVENT_SKIP_EVENT_DMA_R": 0,
        },
    }


def load_input(path: Path | None, use_synthetic: bool) -> dict[str, Any]:
    if use_synthetic:
        return synthetic_input()
    if path is None:
        raise SystemExit("ERROR: --input is required unless --synthetic is used")
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise SystemExit("ERROR: counter input must be a JSON object")
    return data


def extract_stage_counts(data: dict[str, Any]) -> dict[str, int]:
    raw = data.get("stage_counts") or data.get("stages") or data.get("snapshots")
    if raw is None:
        raise SystemExit("ERROR: missing stage_counts/stages/snapshots in counter input")

    counts: dict[str, int] = {}
    if isinstance(raw, dict):
        for key, value in raw.items():
            stage = str(key).upper().replace("CP-", "")
            counts[stage] = snapshot_delta(value)
    elif isinstance(raw, list):
        for entry in raw:
            if not isinstance(entry, dict):
                continue
            stage = str(entry.get("stage") or entry.get("id") or "").upper().replace("CP-", "")
            counts[stage] = snapshot_delta(entry)
    else:
        raise SystemExit("ERROR: unsupported stage_counts format")

    missing = [stage for stage in STAGES if stage not in counts]
    if missing:
        raise SystemExit(f"ERROR: missing counter stages: {', '.join(missing)}")
    return counts


def extract_counter_block(data: dict[str, Any]) -> dict[str, int]:
    raw = data.get("bar1") or data.get("counters") or {}
    if not isinstance(raw, dict):
        return {}
    result: dict[str, int] = {}
    for key, value in raw.items():
        try:
            result[str(key)] = snapshot_delta(value)
        except (TypeError, ValueError):
            continue
    return result


def check_conservation(data: dict[str, Any]) -> dict[str, Any]:
    counts = extract_stage_counts(data)
    mode = str(data.get("mode") or "A").upper()
    mask = str(data.get("mask") or "M0").upper()
    rate = data.get("rate_hz", data.get("rate", "R1"))
    run_seconds = float(data.get("run_seconds") or 30.0)
    configured_tolerance = data.get("tolerance")
    failures: list[dict[str, Any]] = []
    channel_counts = get_channel_counts(data)
    first_stage_delta = get_first_stage_delta(data, channel_counts)
    exp_total = expected_total(mode, mask, rate, run_seconds)
    exp_total_tol = tolerance_for(mode, exp_total, configured_tolerance)

    if exp_total > 0:
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
        elif abs(float(first_stage_delta) - exp_total) > exp_total_tol:
            failures.append(
                {
                    "stage": "C1",
                    "counter": "first_stage_delta",
                    "expected": exp_total,
                    "observed": first_stage_delta,
                    "tolerance": exp_total_tol,
                }
            )

    if exp_total > 0 and not failures:
        if channel_counts is None:
            failures.append(
                {
                    "stage": "C1",
                    "reason": "missing per-channel FEB/rate_emulator counts",
                    "expected_total": exp_total,
                }
            )
        else:
            failures.extend(
                check_expected_channels(
                    channel_counts,
                    mode,
                    mask,
                    rate,
                    run_seconds,
                    "C1",
                    configured_tolerance,
                )
            )

    if exp_total > 0 and not failures:
        if abs(float(counts["C1"]) - exp_total) > exp_total_tol:
            failures.append(
                {
                    "stage": "C1",
                    "counter": "stage_counts.C1",
                    "expected": exp_total,
                    "observed": counts["C1"],
                    "tolerance": exp_total_tol,
                }
            )

    if not failures:
        for prev_stage, stage in zip(STAGES, STAGES[1:]):
            expected = counts[prev_stage]
            observed = counts[stage]
            tolerance = tolerance_for(mode, expected, configured_tolerance)
            if abs(observed - expected) > tolerance:
                failures.append(
                    {
                        "stage": stage,
                        "previous_stage": prev_stage,
                        "expected": expected,
                        "observed": observed,
                        "tolerance": tolerance,
                    }
                )
                break

    counters = extract_counter_block(data)
    if counters.get("CNT_HALT", 0) != 0 and not failures:
        failures.append({"stage": "C8", "counter": "CNT_HALT", "observed": counters["CNT_HALT"]})
    if counters.get("EVENT_SKIP_EVENT_DMA_R", 0) != 0 and not failures:
        failures.append(
            {
                "stage": "C8",
                "counter": "EVENT_SKIP_EVENT_DMA_R",
                "observed": counters["EVENT_SKIP_EVENT_DMA_R"],
            }
        )
    if {"CNT_OPQ_INPUT_W", "CNT_BYTES_WRITTEN"}.issubset(counters) and not failures:
        header_overhead = int(data.get("header_overhead", 0))
        expected_bytes = counters["CNT_OPQ_INPUT_W"] * 4
        observed_bytes = counters["CNT_BYTES_WRITTEN"] + header_overhead
        if observed_bytes != expected_bytes:
            failures.append(
                {
                    "stage": "C8",
                    "counter": "CNT_BYTES_WRITTEN",
                    "expected": expected_bytes,
                    "observed": observed_bytes,
                    "header_overhead": header_overhead,
                }
            )
    if {"CNT_SQE_CONSUMED", "CNT_CQE_POSTED"}.issubset(counters) and not failures:
        if counters["CNT_SQE_CONSUMED"] != counters["CNT_CQE_POSTED"]:
            failures.append(
                {
                    "stage": "C9",
                    "counter": "CNT_CQE_POSTED",
                    "expected": counters["CNT_SQE_CONSUMED"],
                    "observed": counters["CNT_CQE_POSTED"],
                }
            )

    if failures:
        first = failures[0]
        status = f"FAIL_AT_{first['stage']}"
        detail = json.dumps(first, sort_keys=True)
    else:
        status = "PASS"
        detail = "all adjacent counter stages conserve"

    return {
        "schema_version": 1,
        "evidence_kind": "E1_counter_lossless",
        "cohort": data.get("cohort", "UNKNOWN"),
        "matrix_id": data.get("matrix_id", "UNKNOWN"),
        "chain": "counter_chain",
        "status": status,
        "stage": failures[0]["stage"] if failures else "C9",
        "detail": detail,
        "mode": mode,
        "mask": mask,
        "rate": rate,
        "run_seconds": run_seconds,
        "expected_per_channel": expected_per_channel(mode, rate, run_seconds),
        "expected_total": exp_total,
        "first_stage_delta": first_stage_delta,
        "stage_counts": counts,
        "counters": counters,
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
    parser.add_argument("--input", type=Path, help="counter snapshot JSON")
    parser.add_argument("--out", type=Path, required=True, help="ledger JSON output")
    parser.add_argument("--synthetic", action="store_true", help="use built-in passing input")
    args = parser.parse_args()

    result = check_conservation(load_input(args.input, args.synthetic))
    write_json(args.out, result)
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
