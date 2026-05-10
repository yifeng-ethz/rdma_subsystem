#!/usr/bin/env python3
"""Collect a run log into a per-test-point JSON ledger."""

from __future__ import annotations

import argparse
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

CHAIN_NAMES = (
    "bring_up",
    "counter_chain",
    "rate_chain",
    "latency",
    "offline_chain",
    "offline_analysis",
)

CHAIN_ALIASES = {
    "BU": "bring_up",
    "BRING_UP": "bring_up",
    "C": "counter_chain",
    "COUNTER": "counter_chain",
    "COUNTER_CHAIN": "counter_chain",
    "R": "rate_chain",
    "RATE": "rate_chain",
    "RATE_CHAIN": "rate_chain",
    "L": "latency",
    "LATENCY": "latency",
    "O": "offline_chain",
    "OFFLINE": "offline_chain",
    "OFFLINE_CHAIN": "offline_chain",
    "A": "offline_analysis",
    "ANALYSIS": "offline_analysis",
    "OFFLINE_ANALYSIS": "offline_analysis",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def normalize_chain(value: str) -> str | None:
    text = value.strip()
    if text in CHAIN_NAMES:
        return text
    return CHAIN_ALIASES.get(text.upper().replace("-", "_"))


def parse_key_values(line: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for key, value in re.findall(r"([A-Za-z0-9_./-]+)=([^ \t]+)", line):
        result[key] = value.strip().strip(",;")
    return result


def parse_log(path: Path) -> dict[str, dict[str, Any]]:
    chains: dict[str, dict[str, Any]] = {}
    if not path.is_file():
        raise SystemExit(f"ERROR: missing run log {path}")
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("{"):
            try:
                obj = json.loads(stripped)
            except json.JSONDecodeError:
                obj = None
            if isinstance(obj, dict):
                chain = normalize_chain(str(obj.get("chain", "")))
                if chain:
                    chains[chain] = {
                        "status": str(obj.get("status", "PENDING")),
                        "stage": str(obj.get("stage", "")),
                        "detail": str(obj.get("detail", "")),
                    }
                    continue
        kv = parse_key_values(stripped)
        chain = normalize_chain(kv.get("chain", kv.get("CHAIN", "")))
        status = kv.get("status") or kv.get("STATUS")
        if chain and status:
            chains[chain] = {
                "status": status,
                "stage": kv.get("stage", kv.get("STAGE", "")),
                "detail": kv.get("detail", ""),
            }
            continue
        simple = re.match(r"^(bring_up|counter_chain|rate_chain|latency|offline_chain|offline_analysis)\s+(PASS|FAIL_AT_[A-Za-z0-9_-]+|PENDING|SKIP)\b", stripped)
        if simple:
            chains[simple.group(1)] = {"status": simple.group(2), "stage": "", "detail": ""}
    return chains


def synthetic_chains(matrix_id: str) -> dict[str, dict[str, Any]]:
    if matrix_id == "S0_BU":
        return {"bring_up": {"status": "PASS", "stage": "BU", "detail": "synthetic bring-up pass"}}
    return {
        "counter_chain": {"status": "PASS", "stage": "C9", "detail": "synthetic pass"},
        "rate_chain": {"status": "PASS", "stage": "R6", "detail": "synthetic pass"},
        "latency": {"status": "PASS", "stage": "L5", "detail": "synthetic pass"},
        "offline_chain": {"status": "PASS", "stage": "O4", "detail": "synthetic pass"},
        "offline_analysis": {"status": "PASS", "stage": "A3", "detail": "synthetic pass"},
    }


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-log", type=Path, help="run log to parse")
    parser.add_argument("--out-dir", type=Path, required=True, help="test-point evidence directory")
    parser.add_argument("--cohort", required=True)
    parser.add_argument("--matrix-id", required=True)
    parser.add_argument("--mode", default="-")
    parser.add_argument("--mask", default="-")
    parser.add_argument("--rate", default="-")
    parser.add_argument("--synthetic", action="store_true", help="write a passing synthetic ledger")
    args = parser.parse_args()

    chains = synthetic_chains(args.matrix_id) if args.synthetic else parse_log(args.run_log)
    ledger = {
        "schema_version": 1,
        "evidence_kind": "run_ledger",
        "cohort": args.cohort,
        "matrix_id": args.matrix_id,
        "mode": args.mode,
        "mask": args.mask,
        "rate": args.rate,
        "chains": chains,
        "generated_at": utc_now(),
    }
    write_json(args.out_dir / "ledger.json", ledger)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
