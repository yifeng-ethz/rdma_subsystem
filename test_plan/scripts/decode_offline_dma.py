#!/usr/bin/env python3
"""Decode E4 dma.bin into hit records, frame checks, and offline ledgers."""

from __future__ import annotations

import argparse
import json
import os
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def synthetic_records() -> list[dict[str, int | bool]]:
    records: list[dict[str, int | bool]] = []
    for index in range(10):
        records.append(
            {
                "index": index,
                "channel": 0,
                "timestamp": index * 100,
                "sop": index == 0,
                "eop": index == 9,
                "raw": 0,
            }
        )
    return records


def encode_synthetic(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as handle:
        for rec in synthetic_records():
            flags = (1 if rec["sop"] else 0) | (2 if rec["eop"] else 0)
            word = int(rec["channel"]) | (int(rec["timestamp"]) << 8) | (flags << 56)
            handle.write(word.to_bytes(8, "little", signed=False))


def decode_words(path: Path) -> Iterable[dict[str, int | bool]]:
    size = path.stat().st_size
    if size % 8 != 0:
        raise SystemExit(f"ERROR: {path} length {size} is not a multiple of 8 bytes")
    index = 0
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(8)
            if not chunk:
                break
            raw = int.from_bytes(chunk, "little", signed=False)
            flags = (raw >> 56) & 0xFF
            yield {
                "index": index,
                "channel": raw & 0xFF,
                "timestamp": (raw >> 8) & ((1 << 48) - 1),
                "sop": bool(flags & 0x1),
                "eop": bool(flags & 0x2),
                "raw": raw,
            }
            index += 1


def histogram(values: list[int]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for value in values:
        counts[str(value)] += 1
    return dict(sorted(counts.items(), key=lambda item: int(item[0])))


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def decode(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    dma_path: Path = args.dma_bin
    if args.synthetic and not dma_path.exists():
        encode_synthetic(dma_path)
    if not dma_path.is_file():
        raise SystemExit(f"ERROR: missing dma file {dma_path}")

    records_path = args.out_dir / "decoded_hits.ndjson"
    records_path.parent.mkdir(parents=True, exist_ok=True)
    channel_counts: Counter[int] = Counter()
    inter_event: list[int] = []
    frame_errors: list[str] = []
    records_count = 0
    sop_count = 0
    eop_count = 0
    previous_ts: int | None = None
    in_frame = False

    with records_path.open("w", encoding="utf-8") as records_out:
        for rec in decode_words(dma_path):
            records_out.write(json.dumps(rec, sort_keys=True) + "\n")
            records_count += 1
            ch = int(rec["channel"])
            ts = int(rec["timestamp"])
            channel_counts[ch] += 1
            if previous_ts is not None:
                if ts < previous_ts:
                    frame_errors.append(f"timestamp moved backward at record {records_count - 1}")
                else:
                    inter_event.append(ts - previous_ts)
            previous_ts = ts
            if rec["sop"]:
                sop_count += 1
                if in_frame:
                    frame_errors.append(f"nested sop at record {records_count - 1}")
                in_frame = True
            if rec["eop"]:
                eop_count += 1
                if not in_frame:
                    frame_errors.append(f"eop without sop at record {records_count - 1}")
                in_frame = False

    if in_frame:
        frame_errors.append("file ended before eop")
    if records_count == 0:
        frame_errors.append("empty dma file")

    offline_status = "PASS" if not frame_errors else "FAIL_AT_O4"
    offline_detail = "decoded host rx_buffer stream" if not frame_errors else frame_errors[0]

    analysis_failures: list[str] = []
    if args.truth_count is not None and records_count != args.truth_count:
        analysis_failures.append(f"decoded count {records_count} != truth count {args.truth_count}")
    if args.expected_active_channel is not None:
        active_count = channel_counts.get(args.expected_active_channel, 0)
        if active_count != records_count:
            analysis_failures.append("records outside expected active channel")
    if args.require_inter_event and not inter_event:
        analysis_failures.append("missing inter-event samples")

    analysis_status = "PASS" if not analysis_failures else "FAIL_AT_A2"
    if args.require_inter_event and analysis_status == "PASS" and len(set(inter_event)) > 1:
        analysis_status = "FAIL_AT_A3"
        analysis_failures.append("inter-event period is not constant")

    common = {
        "schema_version": 1,
        "cohort": args.cohort,
        "matrix_id": args.matrix_id,
        "dma_bin": dma_path.as_posix(),
        "records_path": records_path.as_posix(),
        "records_count": records_count,
        "channel_counts": {str(key): value for key, value in sorted(channel_counts.items())},
        "sop_count": sop_count,
        "eop_count": eop_count,
        "generated_at": utc_now(),
    }

    offline_chain = {
        **common,
        "evidence_kind": "E4_offline_dma_decode",
        "chain": "offline_chain",
        "status": offline_status,
        "stage": "O4" if offline_status == "PASS" else "O4",
        "detail": offline_detail,
        "frame_errors": frame_errors,
    }
    offline_analysis = {
        **common,
        "evidence_kind": "CP_A_offline_analysis",
        "chain": "offline_analysis",
        "status": analysis_status,
        "stage": "A3" if analysis_status == "PASS" else analysis_status.replace("FAIL_AT_", ""),
        "detail": "offline stream checks passed" if not analysis_failures else analysis_failures[0],
        "failures": analysis_failures,
        "inter_event_histogram": histogram(inter_event),
    }
    return offline_chain, offline_analysis


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dma-bin", type=Path, required=True, help="input dma.bin")
    parser.add_argument("--out-dir", type=Path, required=True, help="output evidence directory")
    parser.add_argument("--cohort", default="UNKNOWN")
    parser.add_argument("--matrix-id", default="UNKNOWN")
    parser.add_argument("--truth-count", type=int)
    parser.add_argument("--expected-active-channel", type=int)
    parser.add_argument("--require-inter-event", action="store_true")
    parser.add_argument("--synthetic", action="store_true", help="create a small synthetic dma.bin if missing")
    args = parser.parse_args()

    offline_chain, offline_analysis = decode(args)
    write_json(args.out_dir / "offline_chain.json", offline_chain)
    write_json(args.out_dir / "offline_analysis.json", offline_analysis)
    return 0 if offline_chain["status"] == "PASS" and offline_analysis["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
