# `rdma_subsystem` — Integration RTL Plan

Status: **PLAN — pending review.** This is the integration-level RTL plan
for the supercore. Per-IP RTL plans are in their own submodule folders:
- `mu3e-ip-cores/rdma_dma_engine/RTL_PLAN.md`
- `mu3e-ip-cores/rdma_sq_fetcher/RTL_PLAN.md`
- `mu3e-ip-cores/rdma_cq_pusher/RTL_PLAN.md`
- `mu3e-ip-cores/rdma_run_manager/RTL_PLAN.md`

## 1. Scope

This plan covers the **supercore-level RTL only** — i.e. the integration
wrapper that hooks the four sibling IPs together as a single Qsys/AXI
subsystem. The 4 IPs are themselves complete IP submodules with their
own RTL, UVM, syn, and `_hw.tcl`; this layer just wires them.

## 2. File set

```
rdma_subsystem/
|-- RTL_PLAN_INT.md                       (this file)
|-- ARCHITECTURE_PLAN.md                  (already committed)
|-- PHASE_STATUS.md                       (already committed)
|-- README.md
|-- rtl/                                  (this commit)
|   |-- rdma_subsystem_top.sv             top-level wrapper
|   |-- rdma_subsystem_axi_xbar.sv        internal AXI4 crossbar (3 masters -> 1 host port)
|   |-- rdma_subsystem_pkg.sv             shared params (WQE_BUS_W, DMA_DATA_W, ...)
|   |-- rdma_subsystem_csr_decoder.sv     BAR1 routing (rdma_run_manager owns the decoded CSR)
|   `-- rdma_subsystem_reset_chain.sv     reset distribution + sync to subsystem clk
|-- syn/quartus/                          (this commit)
|   `-- rdma_subsystem_standalone.qsf     standalone fitter for sign-off
|-- rdma_subsystem.qsys                   Qsys system file (this commit)
|-- rdma_subsystem_hw.tcl                 (this commit)
`-- tb_int/                               separate plan in DV_PLAN_INT.md
```

## 3. Top-level interface

```systemverilog
module rdma_subsystem_top #(
    parameter int unsigned DMA_DATA_W = 256,
    parameter int unsigned WQE_BUS_W  = 512,
    parameter int unsigned DEBUG_LEVEL = 0
) (
    input  logic                       clk,
    input  logic                       reset_n,

    // OPQ egress (AXI4-Stream sink, 36b TDATA)
    input  logic [35:0]                s_axis_opq_tdata,
    input  logic                       s_axis_opq_tvalid,
    output logic                       s_axis_opq_tready,
    input  logic                       s_axis_opq_tlast,
    input  logic [1:0]                 s_axis_opq_tuser,

    // BAR1 CSR slave (AXI4-Lite, 32b data, 8b address) — owned by rdma_run_manager
    input  logic [7:0]                 s_axil_awaddr,
    input  logic                       s_axil_awvalid,
    output logic                       s_axil_awready,
    input  logic [31:0]                s_axil_wdata,
    input  logic [3:0]                 s_axil_wstrb,
    input  logic                       s_axil_wvalid,
    output logic                       s_axil_wready,
    output logic [1:0]                 s_axil_bresp,
    output logic                       s_axil_bvalid,
    input  logic                       s_axil_bready,
    input  logic [7:0]                 s_axil_araddr,
    input  logic                       s_axil_arvalid,
    output logic                       s_axil_arready,
    output logic [31:0]                s_axil_rdata,
    output logic [1:0]                 s_axil_rresp,
    output logic                       s_axil_rvalid,
    input  logic                       s_axil_rready,

    // AXI4 host-DRAM master (single bundle out of internal xbar)
    output logic [3:0]                 m_axi_awid,
    output logic [63:0]                m_axi_awaddr,
    output logic [7:0]                 m_axi_awlen,
    output logic [2:0]                 m_axi_awsize,
    output logic [1:0]                 m_axi_awburst,
    output logic                       m_axi_awvalid,
    input  logic                       m_axi_awready,
    output logic [DMA_DATA_W-1:0]      m_axi_wdata,
    output logic [DMA_DATA_W/8-1:0]    m_axi_wstrb,
    output logic                       m_axi_wlast,
    output logic                       m_axi_wvalid,
    input  logic                       m_axi_wready,
    input  logic [3:0]                 m_axi_bid,
    input  logic [1:0]                 m_axi_bresp,
    input  logic                       m_axi_bvalid,
    output logic                       m_axi_bready,
    output logic [3:0]                 m_axi_arid,
    output logic [63:0]                m_axi_araddr,
    output logic [7:0]                 m_axi_arlen,
    output logic [2:0]                 m_axi_arsize,
    output logic [1:0]                 m_axi_arburst,
    output logic                       m_axi_arvalid,
    input  logic                       m_axi_arready,
    input  logic [3:0]                 m_axi_rid,
    input  logic [DMA_DATA_W-1:0]      m_axi_rdata,
    input  logic [1:0]                 m_axi_rresp,
    input  logic                       m_axi_rlast,
    input  logic                       m_axi_rvalid,
    output logic                       m_axi_rready,

    // MSI-X (Phase 2 — tied off in Phase 1)
    output logic                       msix_req,
    output logic [4:0]                 msix_vector,
    input  logic                       msix_ack
);
```

## 4. Internal wiring

```
                                                         +--------------------+
                                                         | rdma_run_manager   |
   s_axil_*  ----------------------------> AXI4-Lite --->| (CSR + dispatch FSM)|
                                                         |                    |
                            +-- sqe AXIS <----- m_axis ---|                    |
                            |                            +--------------------+
                            |                              ^   |
                            |                              |   v
                            |                              cqe AXIS (in)
                            |                              from cq_pusher
                            v
                      +-----------+
                      | rdma_sq_  |---- m_axi_* (read) ----+
                      | fetcher   |                        |
                      +-----------+                        |
                                                           |
                      +-----------+                        |
   OPQ AXIS  ------>| rdma_dma_   |---- m_axi_* (write) ---+----> XBar ---> m_axi_* (single bundle)
                      | engine    |                        |
                      +-----------+                        |
                            ^                              |
                            | (job_req/done from rm)       |
                                                           |
                      +-----------+                        |
   <----- cqe AXIS <-| rdma_cq_   |---- m_axi_* (write) ---+
                      | pusher    |
                      +-----------+
                            ^
                            | MSI-X (Phase 2)
                            v
                      msix_*
```

## 5. AXI4 internal crossbar (`rdma_subsystem_axi_xbar.sv`)

Three AXI4 masters into one external host-DRAM bundle:
- `sq_fetcher` — read-only (AR/R)
- `dma_engine` — write-only (AW/W/B)
- `cq_pusher` — write-only (AW/W/B)

Phase 1 implementation: simple round-robin / fixed-priority arbiter
favoring write-side traffic since `dma_engine` is the highest-bandwidth
producer. Read-side has a single master so no arbitration needed on AR/R.

Phase 2: replace with vendor crossbar (Altera `altera_axi_interconnect`
or AMBA AXI compliant generic) as the path matures.

## 6. CSR decoding

The supercore exposes a single AXI4-Lite slave at the BAR1 boundary. The
internal `rdma_subsystem_csr_decoder.sv` is a passthrough — it just
forwards every transaction to `rdma_run_manager`'s AXI4-Lite slave.
Reason: only `rdma_run_manager` owns host-visible CSR; the other 3 IPs
have no host-visible CSR. The decoder exists so future Phase 2 expansion
(per-QP CSRs, per-IP debug CSRs) doesn't need a top-level RTL change.

## 7. Reset distribution

Single external `reset_n` is buffered through `rdma_subsystem_reset_chain.sv`,
which generates per-IP reset_n (with a 2-flop sync per IP for clock-domain
crossing if a future IP runs at a different clk). Phase 1 single-clock,
single-reset domain.

## 8. DEBUG_LEVEL parameter

The supercore parameter `DEBUG_LEVEL` is broadcast unchanged to every
sub-IP. Each IP already implements 0/1/2 cumulative debug semantics
(synth-clean / FIFO observability / per-hit lineage sidecar). The supercore
adds NO debug logic of its own — it only relays the parameter and any
sideband counters needed for `tb_int` cross-IP scoreboarding (those land in
the supercore's `_dbg_*` outputs, tied off in synth).

## 9. Phasing

| Phase | Scope | Validation |
|------:|-------|------------|
| Phase 1 — semi-permanent (this commit) | All 5 RTL files. Standalone Qsys system + `_hw.tcl`. AXI4 master into a behavioral host stub for sign-off. | Standalone Quartus syn at 1.1× target; subsystem-level `tb_int/` cosim with OPQ source stub + behavioral run_tool model. |
| Phase 2 — high-perf RDMA | Replace AXI4 master output with a thin AXI4↔AVMM bridge to the existing Altera A10 PCIe HIP completer. Add MSI-X hookup. | Hardware integration into `swb_block.vhd`. |

## 10. Files to add and commit cadence

Implementation order (mirrors per-IP plans):

1. `rtl/rdma_subsystem_pkg.sv` — params shared across the wrapper
2. `rtl/rdma_subsystem_reset_chain.sv` — clk/reset distribution
3. `rtl/rdma_subsystem_axi_xbar.sv` — internal 3-master-to-1 AXI4 xbar
4. `rtl/rdma_subsystem_csr_decoder.sv` — passthrough to run_manager
5. `rtl/rdma_subsystem_top.sv` — top, instantiating the 4 IPs + xbar + decoder + reset chain

Then:
6. `rdma_subsystem.qsys` + `rdma_subsystem_hw.tcl` (Qsys integration)
7. `syn/quartus/rdma_subsystem_standalone.qsf` (1.1× sign-off corner)
8. `syn/SYN_REPORT.md` after standalone closes

## 11. Resource estimation (informational)

| Block | ALM_estimate | M20K_estimate | DSP_estimate |
|-------|-------------:|--------------:|-------------:|
| `rdma_subsystem_axi_xbar` | ~150 | 0 | 0 |
| `rdma_subsystem_csr_decoder` | ~30 | 0 | 0 |
| `rdma_subsystem_reset_chain` | ~20 | 0 | 0 |
| `rdma_subsystem_top` glue | ~50 | 0 | 0 |
| **Wrapper subtotal** | **~250** | **0** | **0** |
| Plus 4 sub-IPs (sum of their estimates) | ~3500 | ~14 | 0 |
| **Subsystem total** | **~3750** | **~14** | **0** |

Acceptance band: `[-20%, +50%]` per IP. Wrapper alone is small; the
dominant variable is the AXI4 crossbar arbiter — if the Phase 1 simple
round-robin balloons, we'll switch to vendor crossbar in Phase 2.

## 12. Risks

- **AXI4 crossbar fairness**: Phase 1 simple arbiter may starve the
  `cq_pusher` if `dma_engine` is at full BW. Tested in `tb_int/` PROF cases.
- **Reset deassertion timing**: all 4 IPs must come out of reset
  cleanly; Qsys-managed reset infrastructure is preferred for Phase 2.
- **MSI-X tie-off**: Phase 1 ties `msix_req=0` always. Phase 2 needs
  the cq_pusher's MSI-X stub replaced with real generation.

## 13. Acceptance

Phase 1 done when:
- All 5 RTL files committed; static screen Lint=0 / CDC=0 / RDC=0.
- Standalone Quartus syn at 275 MHz: ALM/M20K/DSP within band, slack ≥ 364 ps.
- `tb_int/` cosim PASSes (separate `DV_PLAN_INT.md`).
- All commits lint-compliant.
