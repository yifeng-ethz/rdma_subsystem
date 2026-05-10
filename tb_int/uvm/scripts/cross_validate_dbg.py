#!/usr/bin/env python3
"""Compare DEBUG=1 and DEBUG=2 scorecards for tb_int cases."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--cases", nargs="+", required=True)
    args = ap.parse_args()
    root = Path(args.root).resolve()
    errors: list[str] = []
    for case_id in args.cases:
        p1 = root / "dbg1" / f"{case_id}.scorecard.json"
        p2 = root / "dbg2" / f"{case_id}.scorecard.json"
        if not p1.exists() or not p2.exists():
            errors.append(f"{case_id}: missing dbg1/dbg2 scorecard")
            continue
        s1 = json.loads(p1.read_text(encoding="utf-8"))
        s2 = json.loads(p2.read_text(encoding="utf-8"))
        for key in ("passed", "observed_txn", "coverage_bin"):
            if s1.get(key) != s2.get(key):
                errors.append(f"{case_id}: DEBUG mismatch for {key}: {s1.get(key)} != {s2.get(key)}")
    if errors:
        for err in errors:
            print(err)
        return 1
    print(f"debug-cross-validate: PASS {len(args.cases)} cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
