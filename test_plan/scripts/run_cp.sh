#!/usr/bin/env bash
# Run one rdma_subsystem onboard checkpoint point or a synthetic local pass.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"

matrix_id=""
cohort=""
mode="-"
mask="-"
rate="-"
chain="all"
synthetic=0
update_checklist=1
evidence_root="${repo_root}/test_plan/evidence"
checklist_out="${repo_root}/test_plan/CHECKLIST.md"
overall_rc=0

usage() {
  printf '%s\n' "Usage: run_cp.sh <matrix_id> [--synthetic] [--chain <chain>] [--evidence <dir>] [--checklist-out <path>] [--no-update]"
}

infer_point() {
  local id="$1"
  if [[ "${id}" == "S0_BU" ]]; then
    cohort="S0"
    mode="-"
    mask="-"
    rate="-"
    return
  fi
  IFS="_" read -r f1 f2 f3 f4 f5 _rest <<< "${id}"
  if [[ "${f1}" == "S10" ]]; then
    cohort="S10"
    mode="${f3:-A}"
    mask="${f4:-M0}"
    rate="${f5:-R1}"
  else
    cohort="${f1}"
    mode="${f2:-A}"
    mask="${f3:-M0}"
    rate="${f4:-R1}"
  fi
}

should_run() {
  local want="$1"
  [[ "${chain}" == "all" || "${chain}" == "${want}" ]]
}

run_stage() {
  set +e
  "$@"
  local rc=$?
  set -e
  if [[ "${rc}" -ne 0 && "${overall_rc}" -eq 0 ]]; then
    overall_rc="${rc}"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --synthetic)
      synthetic=1
      shift
      ;;
    --chain)
      chain="$2"
      shift 2
      ;;
    --cohort)
      cohort="$2"
      shift 2
      ;;
    --mode)
      mode="$2"
      shift 2
      ;;
    --mask)
      mask="$2"
      shift 2
      ;;
    --rate)
      rate="$2"
      shift 2
      ;;
    --evidence)
      evidence_root="$2"
      shift 2
      ;;
    --checklist-out)
      checklist_out="$2"
      shift 2
      ;;
    --no-update)
      update_checklist=0
      shift
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
      if [[ -n "${matrix_id}" ]]; then
        printf 'ERROR: only one matrix_id is allowed\n' >&2
        exit 2
      fi
      matrix_id="$1"
      shift
      ;;
  esac
done

if [[ -z "${matrix_id}" ]]; then
  usage >&2
  exit 2
fi

infer_point "${matrix_id}"
out_dir="${evidence_root}/${matrix_id}"
mkdir -p "${out_dir}"

if [[ "${synthetic}" -eq 0 ]]; then
  if [[ -z "${RDMA_CP_RUNNER:-}" ]]; then
    printf '%s\n' "ERROR: RDMA_CP_RUNNER is not set; use --synthetic for local script verification." >&2
    exit 2
  fi
  "${RDMA_CP_RUNNER}" "${matrix_id}" "${out_dir}"
  if [[ -f "${out_dir}/run.log" ]]; then
    python3 "${script_dir}/collect_evidence.py" \
      --run-log "${out_dir}/run.log" \
      --out-dir "${out_dir}" \
      --cohort "${cohort}" \
      --matrix-id "${matrix_id}" \
      --mode "${mode}" \
      --mask "${mask}" \
      --rate "${rate}"
  fi
else
  printf 'matrix_id=%s cohort=%s synthetic=1\n' "${matrix_id}" "${cohort}" > "${out_dir}/run.log"
  if [[ "${matrix_id}" == "S0_BU" ]]; then
    python3 "${script_dir}/collect_evidence.py" \
      --synthetic \
      --out-dir "${out_dir}" \
      --cohort "${cohort}" \
      --matrix-id "${matrix_id}" \
      --mode "${mode}" \
      --mask "${mask}" \
      --rate "${rate}"
  else
    if [[ "${overall_rc}" -eq 0 ]] && should_run "counter_chain"; then
      python3 - "${out_dir}/counter_input.json" "${cohort}" "${matrix_id}" "${mode}" <<'PY'
import json
import sys
path, cohort, matrix_id, mode = sys.argv[1:5]
data = {
    "schema_version": 1,
    "cohort": cohort,
    "matrix_id": matrix_id,
    "mode": mode,
    "stage_counts": {f"C{i}": 1000 for i in range(1, 10)},
    "bar1": {
        "CNT_OPQ_INPUT_W": 250,
        "CNT_BYTES_WRITTEN": 1000,
        "CNT_SQE_CONSUMED": 1,
        "CNT_CQE_POSTED": 1,
        "CNT_HALT": 0,
        "EVENT_SKIP_EVENT_DMA_R": 0,
    },
}
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2, sort_keys=True)
    handle.write("\n")
PY
      run_stage python3 "${script_dir}/check_counter_lossless.py" \
        --input "${out_dir}/counter_input.json" \
        --out "${out_dir}/counter_chain.json"
    fi
    if [[ "${overall_rc}" -eq 0 ]] && should_run "rate_chain"; then
      python3 - "${out_dir}/rate_input.json" "${cohort}" "${matrix_id}" "${mode}" "${mask}" "${rate}" <<'PY'
import json
import random
import sys
path, cohort, matrix_id, mode, mask, rate = sys.argv[1:7]
rates = {"R1": 10000, "R2": 100000, "R3": 500000, "R4": 1000000}
all_ch = set(range(256))
if mask == "M0":
    active = all_ch
elif mask == "M1":
    active = set(range(128, 256))
elif mask == "M2":
    active = set(range(0, 128))
elif mask == "M3":
    active = {ch for ch in range(256) if ch % 2 == 1}
elif mask == "M4":
    active = {0}
elif mask == "M5":
    active = all_ch - {0}
else:
    rng = random.Random(1)
    frac = 0.75 if mask == "M6" else 0.25
    active = all_ch - set(rng.sample(range(256), int(256 * frac)))
count = int(rates.get(rate, 10000) * 30)
ingress = [count if ch in active else 0 for ch in range(256)]
egress = list(ingress)
data = {
    "schema_version": 1,
    "cohort": cohort,
    "matrix_id": matrix_id,
    "mode": mode,
    "mask": mask,
    "rate": rate,
    "run_seconds": 30,
    "ingress_bins": ingress,
    "egress_bins": egress,
}
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2, sort_keys=True)
    handle.write("\n")
PY
      run_stage python3 "${script_dir}/build_rate_histogram.py" \
        --input "${out_dir}/rate_input.json" \
        --out "${out_dir}/rate_chain.json"
    fi
    if [[ "${overall_rc}" -eq 0 ]] && should_run "latency"; then
      python3 - "${out_dir}/latency_input.json" "${cohort}" "${matrix_id}" "${mode}" <<'PY'
import json
import sys
path, cohort, matrix_id, mode = sys.argv[1:5]
bounds = {
    "pre_rbcam": (0, 2000),
    "post_rbcam": (2000, 2200),
    "feb_egress": (2049, 6143),
    "opq_ingress": (2049, 6159),
    "opq_egress": (4300, 100000),
}
panels = {}
for name, (lo, hi) in bounds.items():
    span = hi - lo
    panels[name] = {
        "bound_lo": lo,
        "bound_hi": hi,
        "p05": lo + max(1, span // 20),
        "p50": (lo + hi) // 2,
        "p95": hi - max(1, span // 20),
        "in_bound_fraction": 1.0,
        "histogram": [[(lo + hi) // 2, 10]],
    }
data = {"schema_version": 1, "cohort": cohort, "matrix_id": matrix_id, "mode": mode, "panels": panels}
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2, sort_keys=True)
    handle.write("\n")
PY
      run_stage python3 "${script_dir}/build_latency_histogram.py" \
        --input "${out_dir}/latency_input.json" \
        --out "${out_dir}/latency.json"
    fi
    if [[ "${overall_rc}" -eq 0 ]] && { should_run "offline_chain" || should_run "offline_analysis"; }; then
      run_stage python3 "${script_dir}/decode_offline_dma.py" \
        --synthetic \
        --dma-bin "${out_dir}/dma.bin" \
        --out-dir "${out_dir}" \
        --cohort "${cohort}" \
        --matrix-id "${matrix_id}" \
        --expected-active-channel 0 \
        --require-inter-event
    fi
  fi
fi

if [[ "${update_checklist}" -eq 1 ]]; then
  python3 "${script_dir}/update_checklist.py" \
    --out "${checklist_out}" \
    --evidence "${evidence_root}"
fi

exit "${overall_rc}"
