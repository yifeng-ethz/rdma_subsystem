# rdma_subsystem Standalone Synthesis Report

Date: 2026-05-10

## Status

Overall status: **BLOCKED**

The wrapper RTL, Qsys package, and standalone Quartus project compile and pass
static screening. Phase D signoff is not green because final resources are
below the `RTL_PLAN_INT.md` section 11 subsystem band and the 275 MHz slack is
below the required 0.364 ns floor.

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
| ALM | 3750 | 3000 to 5625 | 2240 | **RESOURCE ESTIMATE UNDERRUN** |
| M20K | 14 | 12 to 21 | 9 | **RESOURCE ESTIMATE UNDERRUN** |
| DSP | 0 | 0 | 0 | PASS |

Root cause: the compiled Phase 1 standalone implementation is smaller than the
aggregate section 11 estimate. The DMA data FIFO is the only inferred M20K RAM
in the final netlist, and the four sibling IP implementations plus wrapper
logic synthesize to 2240 ALMs in the standalone host-stub context. This is an
underrun against the requested band, so the estimate should not be silently
updated.

Requested review action: authorize either a resource-band relaxation for the
current measured Phase 1 standalone implementation or a revised resource
baseline in `RTL_PLAN_INT.md`.

## Timing Result

| Corner | Setup slack | Hold slack | Status |
|--------|------------:|-----------:|--------|
| Slow 900mV 100C | 0.278 ns | 0.043 ns | **FAIL: below 0.364 ns setup floor** |
| Slow 900mV 0C | 0.355 ns | 0.041 ns | **FAIL: below 0.364 ns setup floor** |
| Fast 900mV 100C | 1.261 ns | 0.020 ns | PASS |
| Fast 900mV 0C | 1.613 ns | 0.017 ns | PASS |

The design is fully constrained for setup and hold. The worst setup path is
inside the sibling DMA engine, not in the new supercore wrapper:

- From: `rdma_dma_engine:dma_engine_i|rdma_dma_data_fifo:data_fifo_i|stored_level[0]`
- To: `rdma_dma_engine:dma_engine_i|rdma_dma_writer:writer_i|writer.beats_remaining[2]`
- Data delay: 3.362 ns
- Logic depth: 7 levels

The path runs from the DMA FIFO level counter through the writer burst-selection
logic into `writer.beats_remaining[*]`. The committed wrapper only wires the DMA
engine into the supercore and cannot retime this path without modifying the
forbidden sibling IP.

Requested review action: authorize a targeted `rdma_dma_engine` timing patch
that registers or splits the FIFO-level to burst-selection path, or relax the
0.364 ns slack floor for this Phase 1 standalone signoff.

## Notes

- No sibling `../rdma_*` RTL files were modified.
- `tb_int/` was not touched; subsystem cosim remains a separate brief.
- `rdma_subsystem_report_timing.tcl` is kept as the reproducible timing-path
  extraction script for the setup and hold path reports listed above.
