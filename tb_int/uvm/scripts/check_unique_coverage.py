#!/usr/bin/env python3
"""Audit tb_int per-case Function Reference and scorecard uniqueness fields."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROW_RE = re.compile(r"^\|\s*([BEPX]\d{3})\s*\|.*\|\s*([^|]*cov:([A-Za-z0-9_]+)[^|]*)\s*\|$")


def load_rows(tb: Path) -> dict[str, str]:
    rows: dict[str, str] = {}
    for name in ("DV_BASIC.md", "DV_EDGE.md", "DV_PROF.md", "DV_ERROR.md"):
        for line in (tb / name).read_text(encoding="utf-8").splitlines():
            match = ROW_RE.match(line)
            if match:
                rows[match.group(1)] = match.group(3)
    return rows


def load_scorecard(root: Path, case_id: str) -> dict | None:
    for candidate in (
        root / "uvm" / "cov_after" / f"{case_id}.scorecard.json",
        root / "uvm" / "cov_after" / "dbg1" / f"{case_id}.scorecard.json",
    ):
        if candidate.exists():
            return json.loads(candidate.read_text(encoding="utf-8"))
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("tb")
    args = ap.parse_args()
    tb = Path(args.tb).resolve()
    rows = load_rows(tb)
    errors: list[str] = []
    if len(rows) != 512:
        errors.append(f"expected 512 case rows, found {len(rows)}")
    for case_id, cov_token in sorted(rows.items()):
        scorecard = load_scorecard(tb, case_id)
        if scorecard is None:
            errors.append(f"{case_id}: missing scorecard")
            continue
        if scorecard.get("coverage_bin") != cov_token:
            errors.append(f"{case_id}: scorecard coverage_bin does not match Function Reference token")
        delta = int(scorecard.get("unique_coverage_delta", 0) or 0)
        justification = str(scorecard.get("duplicate_justification", "") or "")
        if delta <= 0 and not justification:
            errors.append(f"{case_id}: no unique delta and no duplicate justification")
        if scorecard.get("passed") is not True:
            errors.append(f"{case_id}: scorecard did not pass")
    if errors:
        for err in errors:
            print(err)
        return 1
    print(f"unique-coverage-audit: PASS {len(rows)} cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
