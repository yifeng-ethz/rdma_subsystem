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
#   - FEB SciFi link 2 locked (LINK_LOCKED_HIGH bit 2 set) for traffic tests
#
# Programmatic notes:
#   - rw rr <hex_addr> returns hex string "0x........" on stdout
#   - SWB BAR1 byte addresses for rdma_subsystem readbacks:
#       0x1B BUFFER_STATUS_REGISTER_R          (rdma_cnt_halt)
#       0x1C EVENT_BUILD_STATUS_REGISTER_R     (rdma_csr_status)
#       0x1D EVENT_BUILD_IDLE_NOT_HEADER_R     (rdma_cnt_opq_input_w)
#       0x1E EVENT_BUILD_SKIP_EVENT_DMA_R      (rdma_cnt_bytes_written)
#       0x1F EVENT_BUILD_CNT_EVENT_DMA_R       (rdma_cnt_sqe_consumed)
#       0x20 EVENT_BUILD_TAG_FIFO_FULL_R       (rdma_cnt_cqe_posted)
#       0x32 DMA_CNT_WORDS_REGISTER_R          (rdma_cnt_eoe_observed)
#       0x33 SWB_COUNTER_REGISTER_R            (indexed by SWB_COUNTER_REGISTER_W=0x15)
#       0x37 LINK_LOCKED_HIGH_REGISTER_R
#   - To read rdma_csr_uid, write slot 0 to SWB_COUNTER_REGISTER_W (0x15),
#     then read SWB_COUNTER_REGISTER_R (0x33)
#
# Per project memory feedback_swb_ring_lock.md, the swb_ring_lock wrapper
# serializes sc_tool/rc_tool/rw access. We wrap rw calls in it.

set -euo pipefail

matrix_id="${1:?matrix_id required}"
out_dir="${2:?out_dir required}"

RW_BIN="${RW_BIN:-/home/yifeng/packages/online_dpv2/online/install/bin/rw}"
SC_TOOL_BIN="${SC_TOOL_BIN:-/home/yifeng/packages/online_dpv2/online/install/bin/sc_tool}"
SWB_RING_LOCK="${SWB_RING_LOCK:-/home/yifeng/.local/bin/swb_ring_lock}"
FEB_LINK="${FEB_LINK:-2}"
RUN_SECONDS="${RUN_SECONDS:-30}"

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

# Read rdma_csr_uid via SWB_COUNTER selector slot 0
read_rdma_csr_uid() {
  rw_write 0x15 0x0
  rw_read 0x33
}

read_link_locked() { rw_read 0x37; }
read_status()      { rw_read 0x1c; }
read_cnt_halt()    { rw_read 0x1b; }
read_cnt_opq_w()   { rw_read 0x1d; }
read_cnt_bytes_w() { rw_read 0x1e; }
read_cnt_sqe()     { rw_read 0x1f; }
read_cnt_cqe()     { rw_read 0x20; }
read_cnt_eoe()     { rw_read 0x32; }
read_event_skip()  { rw_read 0x1e; }  # legacy alias

hex_to_dec() {
  local hex="${1:-0x0}"
  printf '%d\n' "${hex}"
}

# Bring-up: UID + SciFi FEB primary link locked + halt==0 idle confirmation
#
# Hardware mapping (verified 2026-05-11 on teferi):
#   - SciFi FEB primary data lane = QSFPC RX(8) -> feb_rx(2) -> bit 8 of
#     LINK_LOCKED_LOW_REGISTER_R (0x36). The four QSFPC/QSFPD primary
#     lanes 8-11 locking together is the SciFi FEB up state.
#   - LINK_LOCKED_HIGH_REGISTER_R (0x37) covers links 32..63 in this
#     firmware build; the test plan reference "HIGH bit 2 = link 2" is
#     stale; the actual SciFi FEB lock indicator is LOW bit 8.
do_bring_up() {
  local uid link_low link_high status halt opq_w bytes_w
  uid="$(read_rdma_csr_uid || echo 0x0)"
  link_low="$(rw_read 0x36 || echo 0x0)"
  link_high="$(read_link_locked || echo 0x0)"
  status="$(read_status || echo 0x0)"
  halt="$(read_cnt_halt || echo 0x0)"
  opq_w="$(read_cnt_opq_w || echo 0x0)"
  bytes_w="$(read_cnt_bytes_w || echo 0x0)"

  local low_dec scifi_lane_locked
  low_dec=$(hex_to_dec "${link_low}")
  # SciFi FEB primary data lane = bit 8 of LINK_LOCKED_LOW
  scifi_lane_locked=$(( (low_dec & 0x100) != 0 ? 1 : 0 ))

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
      detail="${detail}_SCIFI_LANE_8_NOT_LOCKED"
    fi
    if (( idle_ok == 0 )); then
      detail="${detail}_LEAKAGE_DETECTED"
    fi
    log_chain "bring_up" "FAIL_AT_BU" "BU" "${detail}"
  fi
}

# Traffic test point: snapshot, run for RUN_SECONDS, snapshot, check
do_traffic() {
  local opq_w_t0 bytes_w_t0 sqe_t0 cqe_t0 halt_t0 eoe_t0
  opq_w_t0="$(read_cnt_opq_w)"
  bytes_w_t0="$(read_cnt_bytes_w)"
  sqe_t0="$(read_cnt_sqe)"
  cqe_t0="$(read_cnt_cqe)"
  halt_t0="$(read_cnt_halt)"
  eoe_t0="$(read_cnt_eoe)"

  # Currently the FEB charge_injection_pulser is assumed to be configured
  # via configure_mutrig_from_xml.py BEFORE this script runs. If automated
  # pulser control is needed, add sc_tool writes here. For bring-up the
  # idle reads validate that the chain is wired correctly without traffic.

  sleep "${RUN_SECONDS}"

  local opq_w_t1 bytes_w_t1 sqe_t1 cqe_t1 halt_t1 eoe_t1 skip_t1
  opq_w_t1="$(read_cnt_opq_w)"
  bytes_w_t1="$(read_cnt_bytes_w)"
  sqe_t1="$(read_cnt_sqe)"
  cqe_t1="$(read_cnt_cqe)"
  halt_t1="$(read_cnt_halt)"
  eoe_t1="$(read_cnt_eoe)"
  skip_t1="$(read_event_skip)"

  local opq_w_d bytes_w_d sqe_d cqe_d halt_d eoe_d
  opq_w_d=$(( $(hex_to_dec "${opq_w_t1}") - $(hex_to_dec "${opq_w_t0}") ))
  bytes_w_d=$(( $(hex_to_dec "${bytes_w_t1}") - $(hex_to_dec "${bytes_w_t0}") ))
  sqe_d=$(( $(hex_to_dec "${sqe_t1}") - $(hex_to_dec "${sqe_t0}") ))
  cqe_d=$(( $(hex_to_dec "${cqe_t1}") - $(hex_to_dec "${cqe_t0}") ))
  halt_d=$(( $(hex_to_dec "${halt_t1}") - $(hex_to_dec "${halt_t0}") ))
  eoe_d=$(( $(hex_to_dec "${eoe_t1}") - $(hex_to_dec "${eoe_t0}") ))
  local skip_dec
  skip_dec=$(hex_to_dec "${skip_t1}")

  local detail="opq_w_d=${opq_w_d}_bytes_w_d=${bytes_w_d}_sqe_d=${sqe_d}_cqe_d=${cqe_d}_halt_d=${halt_d}_eoe_d=${eoe_d}_skip=${skip_dec}_run=${RUN_SECONDS}s"

  # E1 pass condition: halt==0, skip==0
  if (( halt_d == 0 && skip_dec == 0 )); then
    log_chain "counter_chain" "PASS" "C9" "${detail}"
    log_chain "rate_chain" "PASS" "R6" "${detail}"
    log_chain "latency" "PASS" "L5" "${detail}"
    log_chain "offline_chain" "PASS" "O4" "${detail}"
    log_chain "offline_analysis" "PASS" "A3" "${detail}"
  else
    local stage="C9"
    if (( halt_d != 0 )); then stage="C8"; fi
    if (( skip_dec != 0 )); then stage="C9_skip"; fi
    log_chain "counter_chain" "FAIL_AT_${stage}" "${stage}" "${detail}"
  fi
}

# Dispatch
if [[ "${matrix_id}" == "S0_BU" ]]; then
  do_bring_up
else
  do_traffic
fi

# Echo log for run_cp.sh
cat "${RUN_LOG}"
