#!/usr/bin/env bash
# Regenerate CHECKLIST.md and diff it against the committed/worktree copy.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
tmp="${TMPDIR:-/tmp}/rdma_checklist_verify.$$.md"

python3 "${script_dir}/update_checklist.py" \
  --out "${tmp}" \
  --evidence "${repo_root}/test_plan/evidence"

diff -u "${repo_root}/test_plan/CHECKLIST.md" "${tmp}" >&2

python3 - "${tmp}" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
required_total = 0
required_pass = 0
required_bad = []

for raw in path.read_text(encoding="utf-8").splitlines():
    if not raw.startswith("| S"):
        continue
    cols = [col.strip() for col in raw.strip().strip("|").split("|")]
    if len(cols) < 12:
        continue
    cohort, matrix_id, chain = cols[0], cols[1], cols[2]
    optional = cols[7].lower()
    status = cols[8]
    if optional == "yes":
        continue
    required_total += 1
    if status == "PASS":
        required_pass += 1
    else:
        required_bad.append((cohort, matrix_id, chain, status))

if required_bad:
    print(
        f"ERROR: required checklist rows are not all PASS "
        f"({required_pass}/{required_total} PASS)",
        file=sys.stderr,
    )
    for cohort, matrix_id, chain, status in required_bad[:20]:
        print(f"  {cohort} {matrix_id} {chain}: {status}", file=sys.stderr)
    if len(required_bad) > 20:
        print(f"  ... {len(required_bad) - 20} more", file=sys.stderr)
    raise SystemExit(1)

print(f"required checklist rows PASS: {required_pass}/{required_total}", file=sys.stderr)
PY
