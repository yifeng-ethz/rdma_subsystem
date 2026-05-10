#!/usr/bin/env python3
"""Fail on UVM/Questa errors in a tb_int case log."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("log")
    args = ap.parse_args()
    path = Path(args.log)
    text = path.read_text(encoding="utf-8", errors="replace")
    failures = []
    for severity in ("UVM_ERROR", "UVM_FATAL"):
        match = re.search(rf"^\s*#?\s*{severity}\s*:\s*(\d+)\s*$", text, re.MULTILINE)
        if match and int(match.group(1)) != 0:
            failures.append(f"{severity}={match.group(1)}")
    for tok in ("** Error:", "Fatal:", "Segmentation fault"):
        if tok in text:
            failures.append(tok)
    if "TEST_DONE PASS" not in text:
        failures.append("missing TEST_DONE PASS")
    if failures:
        print(f"{path}: FAIL " + ", ".join(failures))
        return 1
    print(f"{path}: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
