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
      python3 - "${script_dir}" "${out_dir}/counter_input.json" "${cohort}" "${matrix_id}" "${mode}" "${mask}" "${rate}" <<'PY'
import json
import sys
script_dir, path, cohort, matrix_id, mode, mask, rate = sys.argv[1:8]
sys.path.insert(0, script_dir)
from traffic_expectations import N_CHANNELS, active_channels, expected_per_channel, expected_total
run_seconds = 30.0
per_channel = int(expected_per_channel(mode, rate, run_seconds))
total = int(expected_total(mode, mask, rate, run_seconds))
channel_counts = [0] * N_CHANNELS
for ch in active_channels(mask):
    channel_counts[ch] = per_channel
data = {
    "schema_version": 1,
    "cohort": cohort,
    "matrix_id": matrix_id,
    "mode": mode,
    "mask": mask,
    "rate": rate,
    "run_seconds": run_seconds,
    "feb_rate_emulator_delta": total,
    "channel_counts": channel_counts,
    "stage_counts": {f"C{i}": total for i in range(1, 10)},
    "bar1": {
        "CNT_OPQ_INPUT_W": total,
        "CNT_BYTES_WRITTEN": total * 4,
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
      python3 - "${script_dir}" "${out_dir}/rate_input.json" "${cohort}" "${matrix_id}" "${mode}" "${mask}" "${rate}" <<'PY'
import json
import sys
script_dir, path, cohort, matrix_id, mode, mask, rate = sys.argv[1:8]
sys.path.insert(0, script_dir)
from traffic_expectations import N_CHANNELS, active_channels, expected_per_channel
run_seconds = 30.0
count = int(expected_per_channel(mode, rate, run_seconds))
active = active_channels(mask)
ingress = [count if ch in active else 0 for ch in range(N_CHANNELS)]
egress = list(ingress)
data = {
    "schema_version": 1,
    "cohort": cohort,
    "matrix_id": matrix_id,
    "mode": mode,
    "mask": mask,
    "rate": rate,
    "run_seconds": run_seconds,
    "feb_rate_emulator_delta": sum(ingress),
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
      python3 - "${script_dir}" "${out_dir}/latency_input.json" "${cohort}" "${matrix_id}" "${mode}" "${mask}" "${rate}" <<'PY'
import json
import sys
script_dir, path, cohort, matrix_id, mode, mask, rate = sys.argv[1:8]
sys.path.insert(0, script_dir)
from traffic_expectations import expected_total
run_seconds = 30.0
sample_count = int(expected_total(mode, mask, rate, run_seconds))
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
        "sample_count": sample_count,
        "histogram": [[(lo + hi) // 2, sample_count]],
    }
data = {
    "schema_version": 1,
    "cohort": cohort,
    "matrix_id": matrix_id,
    "mode": mode,
    "mask": mask,
    "rate": rate,
    "run_seconds": run_seconds,
    "panels": panels,
}
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
