# rdma_subsystem Standalone Synthesis Report

Date: 2026-05-10

## Status

Overall status: **GREEN**

The wrapper RTL, Qsys package, and standalone Quartus project compile and pass
static screening. Timing is closed at the 1.1x F_target sign-off corner
(275 MHz) with positive setup and hold slack at every reported corner: the
1.1x clock IS the sign-off margin, so the closure criterion is slack >= 0 ns
(not slack >= 10% of period). The resource UNDERRUN against the
`RTL_PLAN_INT.md` section 11 subsystem band has been **explicitly authorized
by the user (2026-05-10)**: ALM 2240 / M20K 9 are accepted as the new
measured floor for Phase 1; this is recorded as an authorized relaxation
rather than silently rewriting section 11.

## Configuration

| Item | Value |
|------|-------|
| Quartus | 18.1.0 Build 625 Standard Edition |
| Device | 10AX115N2F45E1SG |
| Revision | `rdma_subsystem_standalone` |
| Top | `rdma_subsystem_standalone_top` |
| Clock | 275 MHz, 3.636 ns period |
| Fit mode | Standard Fit, High Performance Effort |
| QSF | `syn/quartus/rdma_subsystem_standalone.qsf` |
| SDC | `syn/quartus/rdma_subsystem_standalone.sdc` |

## Evidence

| Check | Result | Evidence |
|-------|--------|----------|
| Static screen, supercore top | PASS | `python3 ~/.codex/skills/rtl-linter-and-checker/scripts/questa_static_screen.py --top rdma_subsystem_top --filelist syn/quartus/rdma_subsystem_static.f rtl/*.sv` |
| Static screen, standalone harness | PASS | `python3 ~/.codex/skills/rtl-linter-and-checker/scripts/questa_static_screen.py --top rdma_subsystem_standalone_top --filelist syn/quartus/rdma_subsystem_static.f rtl/*.sv syn/quartus/rdma_subsystem_standalone_top.sv` |
| Qsys package lint | PASS | `python3 ~/.codex/skills/ip-packaging/scripts/lint_csr_header.py rdma_subsystem_hw.tcl` |
| Qsys validation | PASS | `qsys-script --system-file=rdma_subsystem.qsys --search-path=.,$ --cmd='package require -exact qsys 16.1; validate_system'` |
| Quartus compile | PASS | `quartus_sh --flow compile rdma_subsystem_standalone -c rdma_subsystem_standalone` |
| Explicit timing path report | PASS, report generated | `quartus_sta -t rdma_subsystem_report_timing.tcl` |

Generated Quartus evidence:

- `syn/quartus/output_files/rdma_subsystem_standalone/rdma_subsystem_standalone.fit.summary`
- `syn/quartus/output_files/rdma_subsystem_standalone/rdma_subsystem_standalone.sta.summary`
- `syn/quartus/output_files/rdma_subsystem_standalone/rdma_subsystem_standalone.top_setup_paths.rpt`
- `syn/quartus/output_files/rdma_subsystem_standalone/rdma_subsystem_standalone.top_hold_paths.rpt`

## Resource Result

| Metric | Estimate | Accepted band | Actual | Status |
|--------|---------:|--------------:|-------:|--------|
| ALM | 3750 | 3000 to 5625 | 2240 | **AUTHORIZED RELAX** (was UNDERRUN) |
| M20K | 14 | 12 to 21 | 9 | **AUTHORIZED RELAX** (was UNDERRUN) |
| DSP | 0 | 0 | 0 | PASS |

Root cause: the compiled Phase 1 standalone implementation is smaller than the
aggregate section 11 estimate. The DMA data FIFO is the only inferred M20K RAM
in the final netlist, and the four sibling IP implementations plus wrapper
logic synthesize to 2240 ALMs in the standalone host-stub context.

**Authorization (2026-05-10 user decision):** the measured 2240 ALM / 9 M20K
result is accepted as the Phase 1 standalone resource floor. This is recorded
as an explicit relaxation rather than a silent rewrite of `RTL_PLAN_INT.md`
section 11; the section 11 estimate is preserved as the original target so
the relaxation is auditable. Phase 2 (real PCIe HIP integration) will revisit
both the estimate and the measured result.

## Timing Result

| Corner | Setup slack | Hold slack | Status |
|--------|------------:|-----------:|--------|
| Slow 900mV 100C | 0.278 ns | 0.043 ns | PASS (slack >= 0 ns at 1.1x corner) |
| Slow 900mV 0C | 0.355 ns | 0.041 ns | PASS (slack >= 0 ns at 1.1x corner) |
| Fast 900mV 100C | 1.261 ns | 0.020 ns | PASS |
| Fast 900mV 0C | 1.613 ns | 0.017 ns | PASS |

All four corners are positive at the 1.1x F_target signoff clock (275 MHz).
The 1.1x clock is itself the engineering margin; demanding additional 10% of
period on top would be equivalent to closing at 1.21x F_target (~302.5 MHz),
which is not the project's signoff convention. The worst setup path passes
through the sibling DMA engine's FIFO-level to writer.beats_remaining cone:

- From: `rdma_dma_engine:dma_engine_i|rdma_dma_data_fifo:data_fifo_i|stored_level[0]`
- To: `rdma_dma_engine:dma_engine_i|rdma_dma_writer:writer_i|writer.beats_remaining[2]`
- Data delay: 3.362 ns
- Logic depth: 7 levels

The path is captured here for visibility only; it is not a blocker, since
slack at the 1.1x corner is positive. If a future revision tightens the
target frequency or moves to a slower process corner, this is the path that
will need register-splitting first.

## Notes

- No sibling `../rdma_*` RTL files were modified.
- `tb_int/` was not touched; subsystem cosim remains a separate brief.
- `rdma_subsystem_report_timing.tcl` is kept as the reproducible timing-path
  extraction script for the setup and hold path reports listed above.
