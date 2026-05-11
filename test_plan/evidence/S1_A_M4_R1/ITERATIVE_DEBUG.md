# S1_A_M4_R1 Iterative Debug Notes

Date: 2026-05-11

## Symptom

The strict traffic gate rejects the previous zero-traffic pass pattern.
The 30 s `S1_A_M4_R1` run now fails at C1 because programmed nonzero
traffic produces zero FEB-side first-stage delta:

- `counter_snapshots.txt`: `feb_rate_emulator_delta=0`
- `counter_chain.json`: `FAIL_AT_C1`
- `rate_chain.json`: `FAIL_AT_C1`
- `latency.json`: `FAIL_AT_L1`
- `offline_chain.json`: `FAIL_AT_O4`

## Known-Good Boundary

Slow control to the FEB datapath CSR window is live:

- `sc_tool 2 diag` completed with `rsp=OK`.
- Emulator lane-0 CSR writes read back correctly during the reset-link
  probe: `ctrl=0x00000007`.
- The SC hub diagnostic counters show the latest read/write addresses
  in the emulator window (`0x08805`, `0x08870`).

## Failing Boundary

Run control is not reaching the emulator RUNNING state:

- `run_control.log` shows the SWB reset-link transmitter accepts the
  command sequence and reports `start-run` locally when using `rc_tool`,
  but the FEB emulator status counters remain zero.
- `feb_rc_index_probe.log` sent the same short liveness run to FEB
  destinations 0..7. Every destination kept lane-0 status at zero:
  `status_before=0x00000000 status_after=0x00000000`.
- Generated FEB v3 wiring shows `dbg_mm2runctrl_0` is instantiated but
  its `aso_ctrl_data`, `aso_ctrl_valid`, and `aso_ctrl_ready` ports are
  all `open`, so the local CSR self-run source cannot drive the
  `emulator_ctrl_splitter`.
- The restored pipe image
  `firmware_builds/systems/system_20260427_testplanphase5/syn/board_projects/fe_scifi_feb_v3/output_files_pipe/top_nostp_pipe.sof`
  responds coherently over slow control, and exposes `dbg_mm2runctrl_0`
  at `0x08880`. A 30 s S1 run with `RUN_CONTROL_MODE=dbg_mm2runctrl`
  still fails at C1: `run_control_rc=3`, `run_control_stop_rc=3`,
  `sent_after=0`, `target=5`, `status=0x00000807` at start and
  `status=0x0000080F` after stop. This means the local source is stuck
  pending and no command is accepted by the run-control sink.
- A generated-VHDL debug build that routed `dbg_mm2runctrl_0` into the
  v3 `run_control_splitter` did compile and program
  (`output_files/top.sof`, checksum `0x17E25B53`, 2026-05-11 04:26),
  but that debug image broke the FEB slow-control reply path:
  `sc_tool 2 read 0x08880 9` and `sc_tool 2 diag` timed out with
  unmatched secondary-ring replies. The board was restored to the
  archived pipe image (`0x13192DBC`) before rerunning S1.
- The latest archived Phase-7 pipeline/STP SOF (`0x149BD3D6`) was also
  tried as a fallback, but it failed the same slow-control preflight. The
  board is back on the archived pipe image, and `sc_tool 2 diag` again
  returns OK after `mudaq_recover_pcie`.

## Current Root-Cause Hypothesis

The immediate blocker is before RDMA: the FEB emulator never accepts a
RUNNING control word. Both the SWB reset-link path and the local
`dbg_mm2runctrl_0` path fail before the emulator counter can increment.
The next useful probe is at the FEB run-control receive path:

- `upload_subsystem.runctl_mgmt_host_0.asi_synclink_*`
- `upload_subsystem.runctl_mgmt_host_0.aso_runctl_*`
- `data_path_subsystem.run_control_splitter.out15`
- `data_path_subsystem.emulator_ctrl_splitter.out1`
- `data_path_subsystem.emulator_mutrig_0.ctrl_state_q`

The existing `dbg_mm2runctrl_0` CSR cannot be used as a fallback without
a FEB firmware wiring change because its output is open in the generated
top-level data-path VHDL.

## Link-Lock Note

The live SWB bitstream follows the `online_sc` register map:

- `RESET_LINK_STATUS_REGISTER_R = 0x35`
- `LINK_LOCKED_LOW_REGISTER_R = 0x36`
- `LINK_LOCKED_HIGH_REGISTER_R = 0x37`

`rw rr 0x36` currently returns `0x00000f00`, which is links 8..11. Per
`/home/yifeng/CLAUDE.md`, that pattern is not the SciFi FEB at SWB link
2. CP-BU must require bit 2 in `LINK_LOCKED_LOW_REGISTER_R`, not bit 8.
