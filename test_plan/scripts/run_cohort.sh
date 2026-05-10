#!/usr/bin/env bash
# Run all matrix points in a cohort through run_cp.sh.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"

cohort=""
synthetic=0
evidence_root="${repo_root}/test_plan/evidence"
checklist_out="${repo_root}/test_plan/CHECKLIST.md"
dry_run=0

usage() {
  printf '%s\n' "Usage: run_cohort.sh <S0..S10> [--synthetic] [--dry-run] [--evidence <dir>] [--checklist-out <path>]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --synthetic)
      synthetic=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --evidence)
      evidence_root="$2"
      shift 2
      ;;
    --checklist-out)
      checklist_out="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      printf 'ERROR: unknown option %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "${cohort}" ]]; then
        printf 'ERROR: only one cohort is allowed\n' >&2
        exit 2
      fi
      cohort="$1"
      shift
      ;;
  esac
done

if [[ -z "${cohort}" ]]; then
  usage >&2
  exit 2
fi

while IFS=$'\t' read -r row_cohort matrix_id mode mask rate source; do
  if [[ -z "${matrix_id}" ]]; then
    continue
  fi
  if [[ "${dry_run}" -eq 1 ]]; then
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${row_cohort}" "${matrix_id}" "${mode}" "${mask}" "${rate}" "${source}"
    continue
  fi
  args=("${matrix_id}" "--evidence" "${evidence_root}" "--checklist-out" "${checklist_out}")
  if [[ "${synthetic}" -eq 1 ]]; then
    args+=("--synthetic")
  fi
  "${script_dir}/run_cp.sh" "${args[@]}"
done < <(python3 "${script_dir}/update_checklist.py" --list-cohort "${cohort}")
