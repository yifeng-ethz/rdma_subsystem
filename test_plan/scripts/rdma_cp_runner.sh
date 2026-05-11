#!/usr/bin/env bash
# rdma_cp_runner.sh
#
# Real-hardware CP runner for rdma_subsystem test_plan/run_cp.sh.
# Invoked as: rdma_cp_runner.sh <matrix_id> <out_dir>
#
# Reads SWB BAR1 registers via rw (mudaq host MMIO tool) and emits a
# run.log in the format collect_evidence.py expects:
#   chain=<name> status=PASS stage=<id> detail=<text>
#
# Hardware requirements:
#   - /dev/mudaq0 enumerated (SWB SOF loaded)
#   - FEB SciFi link 2 locked for traffic tests
#
# Programmatic notes:
#   - rw rr <hex_addr> returns hex string "0x........" on stdout
#   - SWB BAR1 byte addresses for rdma_subsystem readbacks:
#       0x1B BUFFER_STATUS_REGISTER_R          (rdma_cnt_halt)
#       0x1C EVENT_BUILD_STATUS_REGISTER_R     (rdma_csr_status)
#       0x1D EVENT_BUILD_IDLE_NOT_HEADER_R     (rdma_cnt_opq_input_w)
#       0x1E EVENT_BUILD_SKIP_EVENT_DMA_R      (rdma_cnt_bytes_written)
#       0x1F EVENT_BUILD_CNT_EVENT_DMA_R       (rdma_cnt_rqe_consumed)
#       0x20 EVENT_BUILD_TAG_FIFO_FULL_R       (rdma_cnt_cqe_posted)
#       0x32 DMA_CNT_WORDS_REGISTER_R          (rdma_cnt_eoe_observed)
#       0x33 SWB_COUNTER_REGISTER_R            (indexed by SWB_COUNTER_REGISTER_W=0x15)
#       0x36 LINK_LOCKED_LOW_REGISTER_R        (online_sc live SWB map)
#       0x37 LINK_LOCKED_HIGH_REGISTER_R       (online_sc live SWB map)
#   - To read rdma_csr_uid, write slot 0 to SWB_COUNTER_REGISTER_W (0x15),
#     then read SWB_COUNTER_REGISTER_R (0x33)
#
# Per project memory feedback_swb_ring_lock.md, the swb_ring_lock wrapper
# serializes sc_tool/rc_tool/rw access. We wrap rw calls in it.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
matrix_id="${1:?matrix_id required}"
out_dir="${2:?out_dir required}"

RW_BIN="${RW_BIN:-/home/yifeng/packages/online_dpv2/online/install/bin/rw}"
SC_TOOL_BIN="${SC_TOOL_BIN:-/home/yifeng/packages/online_dpv2/online/install/bin/sc_tool}"
RC_TOOL_BIN="${RC_TOOL_BIN:-/home/yifeng/packages/online_dpv2/online/install/bin/rc_tool}"
SWB_RING_LOCK="${SWB_RING_LOCK:-/home/yifeng/.local/bin/swb_ring_lock}"
FEB_LINK="${FEB_LINK:-2}"
FEB_RC_FEB="${FEB_RC_FEB:-7}"
RC_SETTLE_US="${RC_SETTLE_US:-500000}"
RUN_CONTROL_MODE="${RUN_CONTROL_MODE:-rc_tool}"
DBG_MM2RUNCTRL_BASE="${DBG_MM2RUNCTRL_BASE:-0x08880}"
DBG_GAP_CYCLES="${DBG_GAP_CYCLES:-4}"
EMULATOR_BASE0="${EMULATOR_BASE0:-0x08800}"
EMULATOR_STRIDE="${EMULATOR_STRIDE:-0x10}"
EMULATOR_LANES="${EMULATOR_LANES:-8}"
RUN_SECONDS="${RUN_SECONDS:-30}"
FEB_HIT_GENERATOR="${FEB_HIT_GENERATOR:-${script_dir}/feb_hit_generator.sh}"

mkdir -p "${out_dir}"
RUN_LOG="${out_dir}/run.log"
: >"${RUN_LOG}"

# Decode matrix_id components: e.g. S1_A_M4_R1 -> S1 A M4 R1
IFS='_' read -ra parts <<<"${matrix_id}"
cohort="${parts[0]:-S0}"
mode="-"
mask="-"
rate="-"
if [[ "${cohort}" != "S0" ]]; then
  if [[ "${cohort}" == "S10" ]]; then
    mode="${parts[2]:-A}"
    mask="${parts[3]:-M0}"
    rate="${parts[4]:-R1}"
  else
    mode="${parts[1]:-A}"
    mask="${parts[2]:-M0}"
    rate="${parts[3]:-R1}"
  fi
fi

log_chain() {
  printf 'chain=%s status=%s stage=%s detail=%s\n' "$1" "$2" "$3" "$4" >>"${RUN_LOG}"
}

# Read BAR1 byte addr via rw under the SWB ring lock
rw_read() {
  local addr="$1"
  if [[ -x "${SWB_RING_LOCK}" ]]; then
    "${SWB_RING_LOCK}" -- "${RW_BIN}" rr "${addr}" 2>/dev/null | tr -d '\n'
  else
    "${RW_BIN}" rr "${addr}" 2>/dev/null | tr -d '\n'
  fi
}

rw_write() {
  local addr="$1" val="$2"
  if [[ -x "${SWB_RING_LOCK}" ]]; then
    "${SWB_RING_LOCK}" -- "${RW_BIN}" wwr "${addr}" "${val}" 2>/dev/null >/dev/null
  else
    "${RW_BIN}" wwr "${addr}" "${val}" 2>/dev/null >/dev/null
  fi
}

sc_tool() {
  if [[ -x "${SWB_RING_LOCK}" ]]; then
    "${SWB_RING_LOCK}" -- "${SC_TOOL_BIN}" "$@"
  else
    "${SC_TOOL_BIN}" "$@"
  fi
}

sc_read_word() {
  local addr="$1"
  sc_tool "${FEB_LINK}" read "${addr}" 1 2>/dev/null | awk '/payload\[0\]/{print $3}' | tail -1
}

sc_write_words() {
  local addr="$1"
  shift
  sc_tool "${FEB_LINK}" write "${addr}" "$@"
}

emulator_addr() {
  local lane="$1" offset="${2:-0}"
  printf '0x%05x\n' $(( EMULATOR_BASE0 + lane * EMULATOR_STRIDE + offset ))
}

read_emulator_status_word() {
  local lane="$1"
  sc_read_word "$(emulator_addr "${lane}" 5)"
}

emulator_frame_count() {
  local status="${1:-0x0}"
  printf '%d\n' $(( status & 0xffff ))
}

emulator_event_count() {
  local status="${1:-0x0}"
  printf '%d\n' $(( (status >> 16) & 0x03ff ))
}

read_emulator_status_csv() {
  local lane word words=()
  for (( lane=0; lane<EMULATOR_LANES; lane++ )); do
    word="$(read_emulator_status_word "${lane}" || echo 0x0)"
    words+=("${word:-0x0}")
  done
  (IFS=,; printf '%s\n' "${words[*]}")
}

emulator_frame_delta_sum() {
  python3 - "$1" "$2" <<'PY'
import sys
before = [int(x, 16) for x in sys.argv[1].split(",") if x]
after = [int(x, 16) for x in sys.argv[2].split(",") if x]
total = 0
for a, b in zip(after, before):
    total += ((a & 0xFFFF) - (b & 0xFFFF)) & 0xFFFF
print(total)
PY
}

run_control_send() {
  local cmd="$1"
  shift
  if [[ -x "${SWB_RING_LOCK}" ]]; then
    "${SWB_RING_LOCK}" -- "${RC_TOOL_BIN}" send "${cmd}" --feb "${FEB_RC_FEB}" --settle-us "${RC_SETTLE_US}" "$@"
  else
    "${RC_TOOL_BIN}" send "${cmd}" --feb "${FEB_RC_FEB}" --settle-us "${RC_SETTLE_US}" "$@"
  fi
}

run_control_status() {
  if [[ -x "${SWB_RING_LOCK}" ]]; then
    "${SWB_RING_LOCK}" -- "${RC_TOOL_BIN}" status
  else
    "${RC_TOOL_BIN}" status
  fi
}

dbg_mm2runctrl_addr() {
  local offset="$1"
  printf '0x%05x\n' $(( DBG_MM2RUNCTRL_BASE + offset ))
}

dbg_mm2runctrl_write() {
  local offset="$1"
  shift
  sc_write_words "$(dbg_mm2runctrl_addr "${offset}")" "$@"
}

dbg_mm2runctrl_read() {
  local offset="$1"
  sc_read_word "$(dbg_mm2runctrl_addr "${offset}")"
}

dbg_mm2runctrl_sent_count() {
  local word
  word="$(dbg_mm2runctrl_read 7 || echo 0x0)"
  printf '%d\n' "$(( word ))"
}

dbg_mm2runctrl_wait_sent() {
  local target="$1"
  local attempts="${2:-50}"
  local count=0
  while (( attempts > 0 )); do
    count="$(dbg_mm2runctrl_sent_count || echo 0)"
    if (( count >= target )); then
      printf '%d\n' "${count}"
      return 0
    fi
    sleep 0.1
    attempts=$(( attempts - 1 ))
  done
  printf '%d\n' "${count}"
  return 0
}

run_control_start_dbg_mm2runctrl() {
  local run_number="$1"
  local gap_word sent_before target sent_after status last_sent
  gap_word="$(printf '0x%08x' $(( DBG_GAP_CYCLES << 16 )))"
  sent_before="$(dbg_mm2runctrl_sent_count || echo 0)"
  target=$(( sent_before + 5 ))
  {
    printf 'run_control_start mode=dbg_mm2runctrl base=%s gap_cycles=%s run_number=%s sent_before=%s\n' \
      "${DBG_MM2RUNCTRL_BASE}" "${DBG_GAP_CYCLES}" "${run_number}" "${sent_before}"
    dbg_mm2runctrl_write 2 0x00000007
    dbg_mm2runctrl_write 6 "${gap_word}"
    dbg_mm2runctrl_write 5 0x00000001
    sent_after="$(dbg_mm2runctrl_wait_sent "${target}" 100 || echo 0)"
    status="$(dbg_mm2runctrl_read 1 || echo 0x0)"
    last_sent="$(dbg_mm2runctrl_read 8 || echo 0x0)"
    printf 'dbg_mm2runctrl_start sent_after=%s target=%s status=%s last_sent=%s\n' \
      "${sent_after}" "${target}" "${status}" "${last_sent}"
  } >>"${out_dir}/run_control.log" 2>&1
  if (( sent_after < target )); then
    return 3
  fi
}

run_control_stop_dbg_mm2runctrl() {
  local sent_before target sent_after status last_sent
  sent_before="$(dbg_mm2runctrl_sent_count || echo 0)"
  target=$(( sent_before + 1 ))
  {
    printf 'run_control_stop mode=dbg_mm2runctrl base=%s sent_before=%s\n' \
      "${DBG_MM2RUNCTRL_BASE}" "${sent_before}"
    dbg_mm2runctrl_write 5 0x00000002 || true
    sent_after="$(dbg_mm2runctrl_wait_sent "${target}" 50 || echo 0)"
    status="$(dbg_mm2runctrl_read 1 || echo 0x0)"
    last_sent="$(dbg_mm2runctrl_read 8 || echo 0x0)"
    printf 'dbg_mm2runctrl_stop sent_after=%s target=%s status=%s last_sent=%s\n' \
      "${sent_after}" "${target}" "${status}" "${last_sent}"
  } >>"${out_dir}/run_control.log" 2>&1
  if (( sent_after < target )); then
    return 3
  fi
}

run_control_start() {
  local run_number="$1"
  case "${RUN_CONTROL_MODE}" in
    rc_tool)
      {
        printf 'run_control_start mode=rc_tool feb=%s settle_us=%s run_number=%s\n' "${FEB_RC_FEB}" "${RC_SETTLE_US}" "${run_number}"
        run_control_send reset
        run_control_send stop-reset
        run_control_send enable
        run_control_send run-prepare --run "${run_number}"
        run_control_send sync
        run_control_send start-run
        run_control_status
      } >>"${out_dir}/run_control.log" 2>&1
      ;;
    dbg_mm2runctrl)
      run_control_start_dbg_mm2runctrl "${run_number}"
      ;;
    *)
      printf 'ERROR: unknown RUN_CONTROL_MODE=%s\n' "${RUN_CONTROL_MODE}" >>"${out_dir}/run_control.log"
      return 2
      ;;
  esac
}

run_control_stop() {
  case "${RUN_CONTROL_MODE}" in
    rc_tool)
      {
        printf 'run_control_stop mode=rc_tool feb=%s settle_us=%s\n' "${FEB_RC_FEB}" "${RC_SETTLE_US}"
        run_control_send end-run || true
        run_control_send disable || true
        run_control_status || true
      } >>"${out_dir}/run_control.log" 2>&1
      ;;
    dbg_mm2runctrl)
      run_control_stop_dbg_mm2runctrl
      ;;
    *)
      printf 'ERROR: unknown RUN_CONTROL_MODE=%s\n' "${RUN_CONTROL_MODE}" >>"${out_dir}/run_control.log"
      return 2
      ;;
  esac
}

# Read rdma_csr_uid via SWB_COUNTER selector slot 0
read_rdma_csr_uid() {
  rw_write 0x15 0x0
  rw_read 0x33
}

read_link_locked_low()  { rw_read 0x36; }
read_link_locked_high() { rw_read 0x37; }
read_status()      { rw_read 0x1c; }
read_cnt_halt()    { rw_read 0x1b; }
read_cnt_opq_w()   { rw_read 0x1d; }
read_cnt_bytes_w() { rw_read 0x1e; }
read_cnt_rqe()     { rw_read 0x1f; }
read_cnt_cqe()     { rw_read 0x20; }
read_cnt_eoe()     { rw_read 0x32; }
read_event_skip()  { rw_read 0x1e; }  # legacy alias

hex_to_dec() {
  local hex="${1:-0x0}"
  printf '%d\n' "${hex}"
}

run_builder() {
  local name="$1"
  shift
  set +e
  "$@"
  local rc=$?
  set -e
  if [[ "${rc}" -ne 0 ]]; then
    printf 'builder=%s rc=%d\n' "${name}" "${rc}" >>"${out_dir}/builder.log"
  fi
}

append_json_status() {
  python3 - "${RUN_LOG}" "$@" <<'PY'
import json
import sys
from pathlib import Path

run_log = Path(sys.argv[1])
lines = []
for name in sys.argv[2:]:
    path = Path(name)
    if not path.is_file():
        continue
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    chain = data.get("chain")
    status = data.get("status", "PENDING")
    stage = data.get("stage", "")
    detail = str(data.get("detail", "")).replace(" ", "_")
    if chain:
        lines.append(f"chain={chain} status={status} stage={stage} detail={detail}\n")
with run_log.open("a", encoding="utf-8") as handle:
    handle.writelines(lines)
PY
}

write_traffic_builder_inputs() {
  local opq_w_d="$1" bytes_w_d="$2" rqe_d="$3" cqe_d="$4" halt_d="$5" eoe_d="$6" skip_d="$7"
  local first_stage_delta="${FEB_RATE_EMULATOR_DELTA:-}"
  python3 - "${script_dir}" "${out_dir}" "${cohort}" "${matrix_id}" "${mode}" "${mask}" "${rate}" "${RUN_SECONDS}" \
    "${opq_w_d}" "${bytes_w_d}" "${rqe_d}" "${cqe_d}" "${halt_d}" "${eoe_d}" "${skip_d}" "${first_stage_delta}" <<'PY'
import json
import sys
from pathlib import Path

script_dir, out_dir, cohort, matrix_id, mode, mask, rate, run_seconds = sys.argv[1:9]
opq_w_d, bytes_w_d, rqe_d, cqe_d, halt_d, eoe_d, skip_d = [int(value) for value in sys.argv[9:16]]
first_stage_text = sys.argv[16]
sys.path.insert(0, script_dir)
from traffic_expectations import N_CHANNELS

out = Path(out_dir)
channel_counts = [0] * N_CHANNELS
stage_counts = {
    "C1": int(first_stage_text) if first_stage_text else 0,
    "C2": int(first_stage_text) if first_stage_text else 0,
    "C3": int(first_stage_text) if first_stage_text else 0,
    "C4": int(first_stage_text) if first_stage_text else 0,
    "C5": int(first_stage_text) if first_stage_text else 0,
    "C6": int(first_stage_text) if first_stage_text else 0,
    "C7": opq_w_d,
    "C8": bytes_w_d // 4,
    "C9": cqe_d,
}
counter_input = {
    "schema_version": 1,
    "cohort": cohort,
    "matrix_id": matrix_id,
    "mode": mode,
    "mask": mask,
    "rate": rate,
    "run_seconds": float(run_seconds),
    "channel_counts": channel_counts,
    "stage_counts": stage_counts,
    "bar1": {
        "CNT_OPQ_INPUT_W": opq_w_d,
        "CNT_BYTES_WRITTEN": bytes_w_d,
        "CNT_RQE_CONSUMED": rqe_d,
        "CNT_CQE_POSTED": cqe_d,
        "CNT_HALT": halt_d,
        "EVENT_SKIP_EVENT_DMA_R": skip_d,
        "CNT_EOE_OBSERVED": eoe_d,
    },
}
if first_stage_text:
    counter_input["feb_rate_emulator_delta"] = int(first_stage_text)

rate_input = {
    "schema_version": 1,
    "cohort": cohort,
    "matrix_id": matrix_id,
    "mode": mode,
    "mask": mask,
    "rate": rate,
    "run_seconds": float(run_seconds),
    "ingress_bins": channel_counts,
    "egress_bins": channel_counts,
}
if first_stage_text:
    rate_input["feb_rate_emulator_delta"] = int(first_stage_text)

panel_names = ("pre_rbcam", "post_rbcam", "feb_egress", "opq_ingress", "opq_egress")
bounds = {
    "pre_rbcam": (0, 2000),
    "post_rbcam": (2000, 2200),
    "feb_egress": (2049, 6143),
    "opq_ingress": (2049, 6159),
    "opq_egress": (4300, 100000),
}
panels = {}
for name in panel_names:
    lo, hi = bounds[name]
    mid = (lo + hi) // 2
    panels[name] = {
        "bound_lo": lo,
        "bound_hi": hi,
        "p05": mid,
        "p50": mid,
        "p95": mid,
        "in_bound_fraction": 0.0,
        "sample_count": 0,
        "histogram": [[mid, 0]],
    }
latency_input = {
    "schema_version": 1,
    "cohort": cohort,
    "matrix_id": matrix_id,
    "mode": mode,
    "mask": mask,
    "rate": rate,
    "run_seconds": float(run_seconds),
    "panels": panels,
}

for name, payload in (
    ("counter_input.json", counter_input),
    ("rate_input.json", rate_input),
    ("latency_input.json", latency_input),
):
    with (out / name).open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")
PY
}

write_missing_dma_evidence() {
  python3 - "${out_dir}" "${cohort}" "${matrix_id}" "${mode}" "${mask}" "${rate}" "${RUN_SECONDS}" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

out_dir, cohort, matrix_id, mode, mask, rate, run_seconds = sys.argv[1:8]
out = Path(out_dir)
now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
common = {
    "schema_version": 1,
    "cohort": cohort,
    "matrix_id": matrix_id,
    "mode": mode,
    "mask": mask,
    "rate": rate,
    "run_seconds": float(run_seconds),
    "generated_at": now,
}
offline_chain = {
    **common,
    "evidence_kind": "E4_offline_dma_decode",
    "chain": "offline_chain",
    "status": "FAIL_AT_O4",
    "stage": "O4",
    "detail": "missing CP-O4 dma.bin host rx_buffer dump",
}
offline_analysis = {
    **common,
    "evidence_kind": "CP_A_offline_analysis",
    "chain": "offline_analysis",
    "status": "FAIL_AT_C1",
    "stage": "C1",
    "detail": "missing CP-O4 dma.bin and first-stage traffic proof",
    "failures": [{"stage": "C1", "reason": "missing first-stage traffic proof"}],
}
for name, payload in (("offline_chain.json", offline_chain), ("offline_analysis.json", offline_analysis)):
    tmp = out / f".{name}.tmp.{os.getpid()}"
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, out / name)
PY
}

# Bring-up: UID + SciFi FEB primary link locked + halt==0 idle confirmation
#
# Hardware mapping (current live SWB map, online_sc a10_pcie_registers):
#   - RESET_LINK_STATUS_REGISTER_R = 0x35
#   - LINK_LOCKED_LOW_REGISTER_R   = 0x36
#   - LINK_LOCKED_HIGH_REGISTER_R  = 0x37
#   - FEB SciFi is SWB link 2, so CP-BU requires LOW bit 2.
#     A value such as 0x00000F00 indicates links 8..11, not the SciFi FEB.
do_bring_up() {
  local uid link_low link_high status halt opq_w bytes_w
  uid="$(read_rdma_csr_uid || echo 0x0)"
  link_low="$(read_link_locked_low || echo 0x0)"
  link_high="$(read_link_locked_high || echo 0x0)"
  status="$(read_status || echo 0x0)"
  halt="$(read_cnt_halt || echo 0x0)"
  opq_w="$(read_cnt_opq_w || echo 0x0)"
  bytes_w="$(read_cnt_bytes_w || echo 0x0)"

  local low_dec scifi_lane_locked
  low_dec=$(hex_to_dec "${link_low}")
  # SciFi FEB primary data link = bit FEB_LINK of LINK_LOCKED_LOW.
  scifi_lane_locked=$(( (low_dec & (1 << FEB_LINK)) != 0 ? 1 : 0 ))

  local uid_lower
  uid_lower="$(echo "${uid}" | tr 'A-F' 'a-f')"
  local uid_ok=0
  if [[ "${uid_lower}" == "0x44514f50" ]]; then
    uid_ok=1
  fi

  # Idle leakage check: all counters should be zero
  local halt_dec opq_w_dec bytes_w_dec idle_ok
  halt_dec=$(hex_to_dec "${halt}")
  opq_w_dec=$(hex_to_dec "${opq_w}")
  bytes_w_dec=$(hex_to_dec "${bytes_w}")
  idle_ok=$(( halt_dec == 0 && opq_w_dec == 0 && bytes_w_dec == 0 ? 1 : 0 ))

  if (( uid_ok == 1 && scifi_lane_locked == 1 && idle_ok == 1 )); then
    log_chain "bring_up" "PASS" "BU" \
      "UID=${uid}_LINK_LOCKED_LOW=${link_low}_LINK_LOCKED_HIGH=${link_high}_STATUS=${status}_HALT=${halt}_OPQ_W=${opq_w}_BYTES_W=${bytes_w}_zero_leakage"
  else
    local detail="UID=${uid}_LINK_LOCKED_LOW=${link_low}_LINK_LOCKED_HIGH=${link_high}_STATUS=${status}_HALT=${halt}_OPQ_W=${opq_w}_BYTES_W=${bytes_w}"
    if (( uid_ok == 0 )); then
      detail="${detail}_UID_MISMATCH_expected_0x44514F50"
    fi
    if (( scifi_lane_locked == 0 )); then
      detail="${detail}_SCIFI_LINK_${FEB_LINK}_NOT_LOCKED"
    fi
    if (( idle_ok == 0 )); then
      detail="${detail}_LEAKAGE_DETECTED"
    fi
    log_chain "bring_up" "FAIL_AT_BU" "BU" "${detail}"
  fi
}

# Traffic test point: snapshot, run for RUN_SECONDS, snapshot, check
do_traffic() {
  local run_start_epoch
  run_start_epoch="$(date +%s)"
  local run_number
  run_number=$(( run_start_epoch & 0xffffffff ))
  local generator_rc=0

  : >"${out_dir}/run_control.log"
  set +e
  run_control_start "${run_number}"
  local run_control_rc=$?
  set -e

  if [[ -x "${FEB_HIT_GENERATOR}" ]]; then
    set +e
    "${FEB_HIT_GENERATOR}" "${mode}" "${rate}" "${mask}" --execute >"${out_dir}/feb_hit_generator.log" 2>&1
    generator_rc=$?
    set -e
  else
    generator_rc=127
    printf 'ERROR: FEB hit-generator helper not executable: %s\n' "${FEB_HIT_GENERATOR}" >"${out_dir}/feb_hit_generator.log"
  fi

  local opq_w_t0 bytes_w_t0 rqe_t0 cqe_t0 halt_t0 eoe_t0
  local skip_t0 link_low_t0 link_low_t1 link_high_t0 link_high_t1
  opq_w_t0="$(read_cnt_opq_w || echo 0x0)"
  bytes_w_t0="$(read_cnt_bytes_w || echo 0x0)"
  rqe_t0="$(read_cnt_rqe || echo 0x0)"
  cqe_t0="$(read_cnt_cqe || echo 0x0)"
  halt_t0="$(read_cnt_halt || echo 0x0)"
  eoe_t0="$(read_cnt_eoe || echo 0x0)"
  skip_t0="$(read_event_skip || echo 0x0)"
  link_low_t0="$(read_link_locked_low || echo 0x0)"
  link_high_t0="$(read_link_locked_high || echo 0x0)"
  local emu_status_t0 emu_status_t1
  emu_status_t0="$(read_emulator_status_csv || echo 0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0)"

  sleep "${RUN_SECONDS}"

  local opq_w_t1 bytes_w_t1 rqe_t1 cqe_t1 halt_t1 eoe_t1 skip_t1
  opq_w_t1="$(read_cnt_opq_w || echo 0x0)"
  bytes_w_t1="$(read_cnt_bytes_w || echo 0x0)"
  rqe_t1="$(read_cnt_rqe || echo 0x0)"
  cqe_t1="$(read_cnt_cqe || echo 0x0)"
  halt_t1="$(read_cnt_halt || echo 0x0)"
  eoe_t1="$(read_cnt_eoe || echo 0x0)"
  skip_t1="$(read_event_skip || echo 0x0)"
  link_low_t1="$(read_link_locked_low || echo 0x0)"
  link_high_t1="$(read_link_locked_high || echo 0x0)"
  emu_status_t1="$(read_emulator_status_csv || echo 0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0)"

	  if [[ -x "${FEB_HIT_GENERATOR}" ]]; then
	    set +e
	    "${FEB_HIT_GENERATOR}" --disable --execute >>"${out_dir}/feb_hit_generator.log" 2>&1
	    set -e
	  fi
	  local run_control_stop_rc=0
	  set +e
	  run_control_stop
	  run_control_stop_rc=$?
	  set -e

  local opq_w_d bytes_w_d rqe_d cqe_d halt_d eoe_d
  opq_w_d=$(( $(hex_to_dec "${opq_w_t1}") - $(hex_to_dec "${opq_w_t0}") ))
  bytes_w_d=$(( $(hex_to_dec "${bytes_w_t1}") - $(hex_to_dec "${bytes_w_t0}") ))
  rqe_d=$(( $(hex_to_dec "${rqe_t1}") - $(hex_to_dec "${rqe_t0}") ))
  cqe_d=$(( $(hex_to_dec "${cqe_t1}") - $(hex_to_dec "${cqe_t0}") ))
  halt_d=$(( $(hex_to_dec "${halt_t1}") - $(hex_to_dec "${halt_t0}") ))
  eoe_d=$(( $(hex_to_dec "${eoe_t1}") - $(hex_to_dec "${eoe_t0}") ))
  local skip_d
  skip_d=$(( $(hex_to_dec "${skip_t1}") - $(hex_to_dec "${skip_t0}") ))
  FEB_RATE_EMULATOR_DELTA="$(emulator_frame_delta_sum "${emu_status_t0}" "${emu_status_t1}")"
  export FEB_RATE_EMULATOR_DELTA

  {
	    printf 'matrix_id=%s mode=%s mask=%s rate=%s run_seconds=%s\n' "${matrix_id}" "${mode}" "${mask}" "${rate}" "${RUN_SECONDS}"
	    printf 'generator_rc=%d\n' "${generator_rc}"
	    printf 'run_control_rc=%d run_control_stop_rc=%d run_control_mode=%s run_number=%s feb_rc_feb=%s rc_settle_us=%s dbg_mm2runctrl_base=%s\n' \
	      "${run_control_rc}" "${run_control_stop_rc}" "${RUN_CONTROL_MODE}" "${run_number}" "${FEB_RC_FEB}" "${RC_SETTLE_US}" "${DBG_MM2RUNCTRL_BASE}"
    printf 'emulator_status_t0=%s\n' "${emu_status_t0}"
    printf 'emulator_status_t1=%s\n' "${emu_status_t1}"
    printf 'feb_rate_emulator_delta=%s\n' "${FEB_RATE_EMULATOR_DELTA}"
    printf 't0 opq_w=%s bytes_w=%s rqe=%s cqe=%s halt=%s eoe=%s skip=%s link_low=%s link_high=%s\n' "${opq_w_t0}" "${bytes_w_t0}" "${rqe_t0}" "${cqe_t0}" "${halt_t0}" "${eoe_t0}" "${skip_t0}" "${link_low_t0}" "${link_high_t0}"
    printf 't1 opq_w=%s bytes_w=%s rqe=%s cqe=%s halt=%s eoe=%s skip=%s link_low=%s link_high=%s\n' "${opq_w_t1}" "${bytes_w_t1}" "${rqe_t1}" "${cqe_t1}" "${halt_t1}" "${eoe_t1}" "${skip_t1}" "${link_low_t1}" "${link_high_t1}"
    printf 'delta opq_w=%d bytes_w=%d rqe=%d cqe=%d halt=%d eoe=%d skip=%d\n' "${opq_w_d}" "${bytes_w_d}" "${rqe_d}" "${cqe_d}" "${halt_d}" "${eoe_d}" "${skip_d}"
  } >"${out_dir}/counter_snapshots.txt"

  write_traffic_builder_inputs "${opq_w_d}" "${bytes_w_d}" "${rqe_d}" "${cqe_d}" "${halt_d}" "${eoe_d}" "${skip_d}"

  run_builder counter_chain python3 "${script_dir}/check_counter_lossless.py" \
    --input "${out_dir}/counter_input.json" \
    --out "${out_dir}/counter_chain.json"
  run_builder rate_chain python3 "${script_dir}/build_rate_histogram.py" \
    --input "${out_dir}/rate_input.json" \
    --out "${out_dir}/rate_chain.json"
  run_builder latency python3 "${script_dir}/build_latency_histogram.py" \
    --input "${out_dir}/latency_input.json" \
    --out "${out_dir}/latency.json"

  if [[ -n "${RDMA_DMA_DUMP_CMD:-}" ]]; then
    set +e
    RDMA_DMA_DUMP_OUT="${out_dir}/dma.bin" bash -c "${RDMA_DMA_DUMP_CMD}" >>"${out_dir}/dma_dump.log" 2>&1
    set -e
  fi

  local generator_delta_arg=()
  if [[ -n "${FEB_RATE_EMULATOR_DELTA:-}" ]]; then
    generator_delta_arg=(--generator-delta "${FEB_RATE_EMULATOR_DELTA}")
  fi
  local dma_is_fresh=0
  if [[ -f "${out_dir}/dma.bin" ]]; then
    local dma_mtime
    dma_mtime="$(stat -c %Y "${out_dir}/dma.bin")"
    if [[ "${dma_mtime}" -ge "${run_start_epoch}" ]]; then
      dma_is_fresh=1
    else
      printf 'stale dma.bin rejected: mtime=%s run_start=%s\n' "${dma_mtime}" "${run_start_epoch}" >>"${out_dir}/dma_dump.log"
    fi
  fi
  if [[ "${dma_is_fresh}" -eq 1 ]]; then
    run_builder offline python3 "${script_dir}/decode_offline_dma.py" \
      --dma-bin "${out_dir}/dma.bin" \
      --out-dir "${out_dir}" \
      --cohort "${cohort}" \
      --matrix-id "${matrix_id}" \
      --mode "${mode}" \
      --mask "${mask}" \
      --rate "${rate}" \
      --run-seconds "${RUN_SECONDS}" \
      "${generator_delta_arg[@]}"
  else
    write_missing_dma_evidence
  fi

  append_json_status \
    "${out_dir}/counter_chain.json" \
    "${out_dir}/rate_chain.json" \
    "${out_dir}/latency.json" \
    "${out_dir}/offline_chain.json" \
    "${out_dir}/offline_analysis.json"
}

# Dispatch
if [[ "${matrix_id}" == "S0_BU" ]]; then
  do_bring_up
else
  do_traffic
fi

# Echo log for run_cp.sh
cat "${RUN_LOG}"
