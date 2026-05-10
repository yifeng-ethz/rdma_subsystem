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
