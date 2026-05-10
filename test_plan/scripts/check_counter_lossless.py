#!/usr/bin/env python3
"""Check E1 per-stage counter conservation and write a chain ledger."""

from __future__ import annotations

import argparse
import json
import math
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

STAGES = tuple(f"C{i}" for i in range(1, 10))


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def synthetic_input() -> dict[str, Any]:
    counts = {stage: 1000 for stage in STAGES}
    return {
        "schema_version": 1,
        "cohort": "SYN",
        "matrix_id": "SYN_A_M0_R1",
        "mode": "A",
        "stage_counts": counts,
        "bar1": {
            "CNT_OPQ_INPUT_W": 250,
            "CNT_BYTES_WRITTEN": 1000,
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


def snapshot_delta(value: Any) -> int:
    if isinstance(value, dict):
        if "delta" in value:
            return int(value["delta"])
        if "after" in value and "before" in value:
            return int(value["after"]) - int(value["before"])
        if "count" in value:
            return int(value["count"])
    return int(value)


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


def tolerance_for(mode: str, expected: int, configured: float | int | None) -> float:
    if configured is not None:
        return float(configured)
    if mode.upper() == "C":
        return 5.0 * math.sqrt(max(float(expected), 1.0))
    return 0.0


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
    configured_tolerance = data.get("tolerance")
    failures: list[dict[str, Any]] = []

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
