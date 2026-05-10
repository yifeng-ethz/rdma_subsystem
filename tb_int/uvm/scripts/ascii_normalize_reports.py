#!/usr/bin/env python3
"""Normalize generated tb_int report Markdown to the ASCII-only project rule."""

from __future__ import annotations

import argparse
from pathlib import Path


REPLACEMENTS = {
    "\u2705": "[PASS]",
    "\u26a0\ufe0f": "[WARN]",
    "\u26a0": "[WARN]",
    "\u274c": "[FAIL]",
    "\u2753": "[PEND]",
    "\u2139\ufe0f": "[INFO]",
    "\u2139": "[INFO]",
    "\u2014": "-",
    "\u2013": "-",
    "\u00a0": " ",
}

GENERATED_MD = (
    "DV_REPORT.md",
    "DV_COV.md",
)

TEXT_SUFFIXES = {
    ".json",
    ".md",
    ".mk",
    ".py",
    ".sv",
}

SKIP_PARTS = {
    "build",
    "logs",
    "cov_after",
}


def report_paths(tb: Path) -> list[Path]:
    paths = [tb / name for name in GENERATED_MD]
    report_dir = tb / "REPORT"
    if report_dir.exists():
        paths.extend(sorted(report_dir.rglob("*.md")))
    return [path for path in paths if path.exists()]


def normalize_text(text: str) -> str:
    for old, new in REPLACEMENTS.items():
        text = text.replace(old, new)
    return text


def has_non_ascii(text: str) -> bool:
    return any(ord(ch) > 127 for ch in text)


def check_paths(tb: Path) -> list[str]:
    failures: list[str] = []
    for path in sorted(tb.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(tb)
        if any(part in SKIP_PARTS for part in rel.parts):
            continue
        if path.name != "Makefile" and path.suffix not in TEXT_SUFFIXES:
            continue
        text = path.read_text(encoding="utf-8")
        if has_non_ascii(text):
            failures.append(str(rel))
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("tb")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    tb = Path(args.tb).resolve()
    if not args.check:
        for path in report_paths(tb):
            text = path.read_text(encoding="utf-8")
            normalized = normalize_text(text)
            if normalized != text:
                path.write_text(normalized, encoding="ascii")

    failures = check_paths(tb)
    if failures:
        for failure in failures:
            print(f"non-ascii: {failure}")
        return 1
    print("ascii-check: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
