#!/usr/bin/env bash
# Configure the FEB SciFi hit generator used for rdma_subsystem real-traffic CP runs.
#
# Default action is dry-run: print the sc_tool command sequence. Pass
# --execute to run it under swb_ring_lock.
#
# Chosen live path:
#   mutrig_injector_0 CSR window at sc_tool word address 0x00AC80.
#   This was confirmed in the FEB SciFi sc_hub smoke tests as the datapath
#   mutrig_injector_0 burst aperture. Its RTL supports:
#     mode 2: deterministic periodic pulses
#     mode 1: header-synchronous pulses
#     mode 5: PRBS/random pulses
#
# Fallback/limited path:
#   charge_injection_pulser_0 at 0x04C00 is a single enable/rate/width CSR
#   and only covers a simple periodic pulser. It is disabled here so the
#   mutrig_injector_0 path is the sole generator during CP evidence runs.
#
# Masking:
#   The legacy mutrig_injector_0 output is a single inject pulse. If a live
#   FEB image exposes a 256-channel mask CSR, set FEB_MASK_CSR_ADDR to its
#   sc_tool word base and this helper writes eight 32-bit active-channel mask
#   words before enabling the generator. Without that CSR, mask-specific
#   cohorts remain expected to fail the strict per-channel evidence gate.

set -euo pipefail

SC_TOOL_BIN="${SC_TOOL_BIN:-/home/yifeng/packages/online_dpv2/online/install/bin/sc_tool}"
SWB_RING_LOCK="${SWB_RING_LOCK:-/home/yifeng/.local/bin/swb_ring_lock}"
FEB_LINK="${FEB_LINK:-2}"
MUTRIG_INJECTOR_BASE="${MUTRIG_INJECTOR_BASE:-0x00AC80}"
CHARGE_INJECTION_PULSER_ADDR="${CHARGE_INJECTION_PULSER_ADDR:-0x04C00}"
FEB_MASK_CSR_ADDR="${FEB_MASK_CSR_ADDR:-}"
EMULATOR_BASE0="${EMULATOR_BASE0:-0x08800}"
EMULATOR_STRIDE="${EMULATOR_STRIDE:-0x10}"
EMULATOR_LANES="${EMULATOR_LANES:-8}"
CLK_HZ="${CLK_HZ:-125000000}"

execute=0
disable=0

usage() {
  printf '%s\n' "Usage: feb_hit_generator.sh <mode> <rate> <mask> [--execute|--dry-run] [--disable]"
  printf '%s\n' "       feb_hit_generator.sh --disable [--execute|--dry-run]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --execute)
      execute=1
      shift
      ;;
    --dry-run)
      execute=0
      shift
      ;;
    --disable)
      disable=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      printf 'ERROR: unknown option %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

mode="${1:-}"
rate="${2:-}"
mask="${3:-}"

rate_hz() {
  case "${1^^}" in
    R1) printf '%s\n' 10000 ;;
    R2) printf '%s\n' 100000 ;;
    R3) printf '%s\n' 500000 ;;
    R4) printf '%s\n' 1000000 ;;
    *) printf '%s\n' "$1" ;;
  esac
}

ceil_div() {
  local num="$1" den="$2"
  printf '%d\n' $(( (num + den - 1) / den ))
}

emit_or_run() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  if [[ "${execute}" -eq 1 ]]; then
    if [[ -x "${SWB_RING_LOCK}" ]]; then
      "${SWB_RING_LOCK}" -- "$@"
    else
      "$@"
    fi
  fi
}

mask_words() {
  python3 - "$1" <<'PY'
import random
import sys

mask = sys.argv[1].upper()
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
elif mask == "M6":
    rng = random.Random(1)
    active = all_ch - set(rng.sample(range(256), int(256 * 0.75)))
elif mask == "M7":
    rng = random.Random(1)
    active = all_ch - set(rng.sample(range(256), int(256 * 0.25)))
else:
    raise SystemExit(f"ERROR: unknown mask {mask}")

words = []
for word_i in range(8):
    value = 0
    for bit_i in range(32):
        ch = word_i * 32 + bit_i
        if ch in active:
            value |= 1 << bit_i
    words.append(f"0x{value:08x}")
print(" ".join(words))
PY
}

mask_lane_words() {
  python3 - "$1" <<'PY'
import random
import sys

mask = sys.argv[1].upper()
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
elif mask == "M6":
    rng = random.Random(1)
    active = all_ch - set(rng.sample(range(256), int(256 * 0.75)))
elif mask == "M7":
    rng = random.Random(1)
    active = all_ch - set(rng.sample(range(256), int(256 * 0.25)))
else:
    raise SystemExit(f"ERROR: unknown mask {mask}")

for lane in range(8):
    local = 0
    for bit in range(32):
        if lane * 32 + bit in active:
            local |= 1 << bit
    print(f"{local:08x}")
PY
}

emu_rate_word() {
  python3 - "${rate_value}" "${CLK_HZ}" <<'PY'
import sys
rate = int(sys.argv[1])
clk = int(sys.argv[2])
word = int(round(rate * 65536.0 / clk))
if word < 1:
    word = 1
if word > 0xFFFF:
    word = 0xFFFF
print(word)
PY
}

emulator_addr() {
  local lane="$1" offset="${2:-0}"
  printf '0x%05x\n' $(( EMULATOR_BASE0 + lane * EMULATOR_STRIDE + offset ))
}

disable_generator() {
  emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "${MUTRIG_INJECTOR_BASE}" 0x00000000
  emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "${CHARGE_INJECTION_PULSER_ADDR}" 0x00000000
  local lane
  for (( lane=0; lane<EMULATOR_LANES; lane++ )); do
    emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "$(emulator_addr "${lane}" 0)" 0x00000000
  done
}

if [[ "${disable}" -eq 1 ]]; then
  disable_generator
  exit 0
fi

if [[ -z "${mode}" || -z "${rate}" || -z "${mask}" ]]; then
  usage >&2
  exit 2
fi

rate_value="$(rate_hz "${rate}")"
pulse_high_cycles="${PULSE_HIGH_CYCLES:-5}"
header_delay="${HEADER_DELAY_CYCLES:-100}"
header_ch="${HEADER_CH:-0}"
injection_multiplicity="${INJECTION_MULTIPLICITY:-1}"
pulse_interval="$(ceil_div "${CLK_HZ}" "${rate_value}")"
header_interval="$(ceil_div "${CLK_HZ}" "$(( rate_value * 910 ))")"
if [[ "${header_interval}" -lt 1 ]]; then
  header_interval=1
fi
prbs_rate="$(ceil_div "${CLK_HZ}" "$(( rate_value * 2 ))")"
if [[ "${prbs_rate}" -gt 0 ]]; then
  prbs_rate=$(( prbs_rate - 1 ))
fi
prbs_pattern="${PRBS_PATTERN:-0x00000001}"
prbs_seed="${PRBS_SEED:-0x0000ace1}"
prbs_ctrl="${PRBS_CTRL:-0x00000004}"

case "${mode^^}" in
  A)
    mode_value=2
    ;;
  B)
    mode_value=1
    ;;
  C)
    mode_value=5
    ;;
  *)
    printf 'ERROR: unknown mode %s\n' "${mode}" >&2
    exit 2
    ;;
esac

read -r -a lane_masks <<<"$(mask_lane_words "${mask}" | tr '\n' ' ')"
emu_rate="$(emu_rate_word)"
for (( lane=0; lane<EMULATOR_LANES; lane++ )); do
  lane_mask="${lane_masks[${lane}]:-00000000}"
  lane_base="$(emulator_addr "${lane}" 0)"
  if [[ "${lane_mask}" == "00000000" ]]; then
    emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "${lane_base}" 0x00000000
    continue
  fi

  # Current FEB v3 firmware has a 32-channel emulator per lane. The masked
  # injected-trigger leg is tied low, so exact arbitrary 256-channel masks are
  # not possible without a firmware change. For the smallest live smoke
  # (M4 = channel 0), use injector-paced one-hit bursts on lane 0. For broader
  # masks, use the emulator folded periodic/IID modes and let the strict
  # evidence checker reject any non-exact per-channel result.
  if [[ "${mode^^}" == "A" && "${mask^^}" == "M4" && "${lane}" -eq 0 ]]; then
    emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "${lane_base}" \
      0x00000003 \
      0x00000000 \
      0x00000001 \
      "${prbs_seed}" \
      0x00000008 \
      0x00000000 \
      "0x${lane_mask}"
  else
    case "${mode^^}" in
      A|B)
        emu_ctrl=0x00000007
        ;;
      C)
        emu_ctrl=0x00000005
        ;;
      *)
        emu_ctrl=0x00000000
        ;;
    esac
    emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "${lane_base}" \
      "$(printf '0x%08x' "${emu_ctrl}")" \
      "$(printf '0x%08x' "${emu_rate}")" \
      0x00000001 \
      "${prbs_seed}" \
      0x00000008 \
      0x00000000 \
      "0x${lane_mask}"
  fi
done

if [[ -n "${FEB_MASK_CSR_ADDR}" ]]; then
  read -r -a words <<<"$(mask_words "${mask}")"
  emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "${FEB_MASK_CSR_ADDR}" "${words[@]}"
else
  printf '# NOTE: FEB_MASK_CSR_ADDR not set; no live per-channel FEB mask CSR write emitted for %s.\n' "${mask}"
fi

# Disable both pulser paths before changing the full mutrig_injector CSR bank.
emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "${MUTRIG_INJECTOR_BASE}" 0x00000000
emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "${CHARGE_INJECTION_PULSER_ADDR}" 0x00000000

emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "${MUTRIG_INJECTOR_BASE}" \
  0x00000000 \
  "0x$(printf '%08x' "${header_delay}")" \
  "0x$(printf '%08x' "${header_interval}")" \
  "0x$(printf '%08x' "${injection_multiplicity}")" \
  "0x$(printf '%08x' "${header_ch}")" \
  "0x$(printf '%08x' "${pulse_interval}")" \
  "0x$(printf '%08x' "${pulse_high_cycles}")" \
  "0x$(printf '%08x' "${prbs_rate}")" \
  "${prbs_pattern}" \
  "${prbs_seed}" \
  "${prbs_ctrl}"

emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" write "${MUTRIG_INJECTOR_BASE}" "0x$(printf '%08x' "${mode_value}")"
emit_or_run "${SC_TOOL_BIN}" "${FEB_LINK}" read "${MUTRIG_INJECTOR_BASE}" 11
