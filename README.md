# rdma_subsystem &mdash; Post-OPQ datapath supercore

Mu3e SWB post-OPQ datapath supercore integrating rdma_dma_engine plus rdma_sq_fetcher plus rdma_cq_pusher plus rdma_run_manager into one Qsys system.

## 2. Architectural map

`rdma_subsystem` is the SWB-side Qsys wrapper that replaces the legacy
post-OPQ event-builder path. It consumes the OPQ egress stream, fetches
host-posted SQEs, writes OPQ bytes into host DRAM, posts CQEs, and exposes the
single BAR1 CSR aperture owned by `rdma_run_manager`.

```
                             AXI4-Lite BAR1 CSR / JTAG alias
                                           |
                                           v
                                  +----------------+
                                  | csr_decoder    |
                                  +-------+--------+
                                          |
                                          v
  host SQ ring --AXI4 read--> +-----------+-------+   job/cfg   +---------------+
                              | rdma_sq_fetcher  |----SQE AXIS->| rdma_run_mgr  |
                              +------------------+              | CSR + FSM     |
                                                                  +-------+------+
                                                                          |
                                                                          | CQE AXIS
                                                                          v
  OPQ egress AXIS 36b --> +-----------------+  AXI4 write  +------+  +----------+
  {datak[3:0],data[31:0]} | rdma_dma_engine |------------->| xbar |<-| cq_pusher|
                          +-----------------+              +--+---+  +----------+
                                                              |
                                                              v
                                                        host_axi master
                                                        host DRAM buffers

  reset_n -> reset_chain -> sq_fetcher, dma_engine, cq_pusher, run_manager,
                             csr_decoder, xbar
```

| Block | Role | Data interfaces | Control visibility |
|---|---|---|---|
| `rdma_subsystem_top` | Top-level SystemVerilog wrapper and Qsys component top. | `opq_in` AXIS sink, `host_axi` AXI4 master, `msix` conduit. | `csr` AXI4-Lite slave forwards to `rdma_run_manager`. |
| `rdma_subsystem_csr_decoder` | BAR1 AXI4-Lite passthrough. | None. | Routes all CSR reads/writes to `rdma_run_manager`; no local registers. |
| `rdma_subsystem_reset_chain` | Reset distribution. | None. | Synchronizes the external active-low reset to each internal block. |
| `rdma_subsystem_axi_xbar` | Phase-1 3-master to 1-host AXI4 merge. | SQ read path, DMA write path, CQ write path, one external host master. | No CSR. |
| `rdma_sq_fetcher` | Fetches 64-byte SQEs from host SQ ring. | AXI4 read master in, SQE AXIS source out. | Configured by run-manager sideband: SQ base, depth, enable, tail doorbell. |
| `rdma_dma_engine` | Packs OPQ 36-bit words into 256-bit AXI4 host writes. | OPQ AXIS sink, AXI4 write master, job req/done sideband. | Job fields and clear-counter pulse from `rdma_run_manager`. |
| `rdma_cq_pusher` | Writes 64-byte CQEs to host CQ ring. | CQE AXIS sink, AXI4 write master, MSI-X conduit. | Configured by run-manager sideband: CQ base, depth, enable, head doorbell. |
| `rdma_run_manager` | BAR1 CSR owner and SQE-to-DMA-to-CQE coordinator. | SQE AXIS sink, CQE AXIS source, job req/done sideband. | Owns UID/META/CTRL/STATUS/ring/counter CSR map. |

The top-level RTL has no direct JTAG port. In system integration, the same CSR
aperture may be reached through a PCIe BAR1 proxy or an embedded JTAG master
alias; both must target the `rdma_run_manager` CSR window.

## 3. Contract - databus format

### 3.1 External AXIS and conduit interfaces

| Signal | Width | Role | Notes |
|---|---:|---|---|
| `s_axis_opq_tdata` | 36 | AXIS sink | OPQ egress word. Bits `[35:32]` are K-symbol flags, one per byte; bits `[31:0]` are the OPQ data word. |
| `s_axis_opq_tvalid` | 1 | AXIS sink | Marks a valid OPQ word. The DMA packer observes this when `CTRL.enable=1`. |
| `s_axis_opq_tready` | 1 | AXIS sink output | Phase-1 packer is readyless in practice and drives ready high; overflow/drop pressure is counted with `CNT_HALT`. |
| `s_axis_opq_tlast` | 1 | AXIS sink | OPQ end-of-event marker. Carried into CQE status bit `EOE`. |
| `s_axis_opq_tuser` | 2 | AXIS sink | `tuser[0]` is SOP; `tuser[1]` is reserved and ignored by current RTL. |
| `msix_req` | 1 | conduit source | Exposed for Phase 2 interrupt delivery. Current CQ pusher stub keeps it quiet until MSI-X is wired. |
| `msix_vector` | 5 | conduit source | MSI-X vector number; valid only with `msix_req`. |
| `msix_ack` | 1 | conduit sink | MSI-X acknowledge from integration fabric. |

OPQ K-symbol interpretation follows the post-OPQ mu3e stream convention:
`s_axis_opq_tdata[35:32]` is the byte-wise K flag field, K28.5/SOP commonly
appears as byte `0xBC`, and K28.4/EOP commonly appears as byte `0x9C`.
The subsystem writes the 32-bit OPQ data bytes verbatim into host buffers; it
does not build MIDAS events and does not translate the OPQ frame format.

### 3.2 AXI4-Lite CSR slave

Standard AXI4-Lite channel signals are omitted here; the top-level port names
use `s_axil_*`.

| Constraint | Value |
|---|---|
| Data width | 32 bits |
| Address width | 8 byte-address bits; decoded as `addr[7:2]` word addresses |
| Aperture | `0x00..0x48` used; reads outside the aperture return `0x00000000`; writes outside are dropped |
| Outstanding model | Single read response and single write response; AW and W may arrive independently and are joined internally |
| Byte strobes | `s_axil_wstrb` is honored for RW registers; doorbell writes pulse when any strobe bit is set |
| Ordering | In-order AXI4-Lite semantics; no out-of-order IDs |
| JTAG alias | No RTL port. System-level JTAG masters must alias the same AXI4-Lite CSR aperture if used for debug. |

### 3.3 Host AXI4 master

Standard AXI4 channel signals are omitted here; the top-level port names use
`m_axi_*`.

| Constraint | Value |
|---|---|
| Role | AXI4 full master toward host DRAM or a Phase-2 AXI4-to-Avalon-MM PCIe bridge |
| Address width | 64 bits |
| Data width | 256 bits at the external `host_axi` port |
| ID width | 4 bits; current sibling writers/readers drive ID 0, and the xbar preserves the 4-bit field |
| Burst type | INCR only |
| External `arsize` / `awsize` | 5, meaning 32 bytes per 256-bit host beat |
| SQE reads | One 64-byte SQE is requested as two 256-bit host beats; external `arlen=1` |
| CQE writes | One 64-byte CQE is split into two 256-bit host beats; external `awlen=1`, full byte strobes |
| DMA writes | 256-bit beats, `MAX_BURST_BEATS=16`, capped at 4 KB page boundaries |
| Max outstanding | The Phase-1 xbar serializes writes to one AW/W/B transaction at a time and accepts one SQ read transaction at a time; one read and one write may be live in the separate read/write FSMs |
| Write arbitration | DMA and CQ writes share one host write channel; simultaneous AW requests alternate with a last-grant round-robin bit |
| Byte strobes | DMA writes use per-byte `WSTRB` for partial final beats; CQ writes use all byte lanes |
| Ordering | Per-channel ordering is preserved by the xbar state machines; no interleaved write responses are expected |

### 3.4 Internal AXIS streams

| Stream | Width | Producer -> Consumer | Contract |
|---|---:|---|---|
| SQE | 512 data + 16 user | `rdma_sq_fetcher` -> `rdma_run_manager` | One 64-byte SQE per beat, `tlast=1`, `tuser[15:0]=sqe_id`. |
| CQE | 512 data + 16 user | `rdma_run_manager` -> `rdma_cq_pusher` | One 64-byte CQE per beat, `tlast=1`, `tuser[15:0]=sqe_id`, and `tdata[159:144]` must match the same SQE ID. |

### 3.5 Run-control AVST system contract

`rdma_subsystem_top` does not expose a run-control AVST port. The system-level
FEB/SWB control path still uses `run-control_mgmt/runctl_mgmt_host`, and this
supercore documentation keeps the contract visible because board bring-up
depends on it.

| Signal | Width | Role | Notes |
|---|---:|---|---|
| `aso_runctl_data` | 9 | AVST source | One-hot run-control state word. |
| `aso_runctl_valid` | 1 | AVST source | One-cycle broadcast strobe. |
| ready | 0 | n/a | Readyless contract; downstream agents cannot backpressure run-control fanout. |

| Bit | State | Source command |
|---:|---|---|
| 0 | `IDLE` | abort, stop-reset, enable, unknown/default |
| 1 | `RUN_PREPARE` | `CMD_RUN_PREPARE` (`0x10`) |
| 2 | `RUN_SYNC` | `CMD_RUN_SYNC` (`0x11`) |
| 3 | `START_RUN` | `CMD_START_RUN` (`0x12`) |
| 4 | `END_RUN` | `CMD_END_RUN` (`0x13`) |
| 5 | `LINK_TEST` | `CMD_START_LINK_TEST` (`0x20`) |
| 6 | `SYNC_TEST` | `CMD_START_SYNC_TEST` (`0x24`) or `CMD_TEST_SYNC` (`0x26`) |
| 7 | `RESET` | Defined by decode table; current v26.3 host suppresses reset fanout and handles reset through the hard-reset path |
| 8 | `OUT_OF_DAQ` | `CMD_DISABLE` (`0x33`) |

### 3.6 SQE layout, 64 bytes

All SQEs are exactly one 64-byte host cacheline, little-endian, and move on the
512-bit WQE plane.

| Word | Byte off | Name | Width | Description |
|---:|---:|---|---:|---|
| 0 | `0x00` | `seg0_addr` | 64 | Host physical address for segment 0; 4 KB aligned. |
| 1 | `0x08` | `seg0_span` | 64 | Segment-0 capacity in bytes; 4 KB multiple and nonzero. |
| 2 | `0x10` | `seg1_addr` | 64 | Host physical address for segment 1; 4 KB aligned when `seg1_span != 0`. |
| 3 | `0x18` | `seg1_span` | 64 | Segment-1 capacity in bytes; 4 KB multiple; zero disables segment 1. |
| 4 | `0x20` | `opcode_id` | 64 | `[15:0]=opcode`, `[31:16]=sqe_id`, `[63:32]=flags`. |
| 5 | `0x28` | `reserved0` | 64 | Reserved for future timestamp or key fields. |
| 6 | `0x30` | `reserved1` | 64 | Reserved. |
| 7 | `0x38` | `reserved2` | 64 | Reserved. |

SQE constraints enforced by the DMA writer:

| Constraint | Value |
|---|---|
| Segment address alignment | `seg*_addr[11:0] == 0` for any used segment |
| Segment span alignment | `seg*_span[11:0] == 0` for any used segment |
| Segment 0 span | Must be nonzero |
| Segment 1 | Optional; disabled with `seg1_span=0` |
| Phase-1 opcode | `0x0001` = drain OPQ until EOE or full SQE span |
| Error return | Alignment/span violations return `ALIGN_ERR` in the CQE status |

### 3.7 CQE layout, 64 bytes

| Word | Byte off | Name | Width | Description |
|---:|---:|---|---:|---|
| 0 | `0x00` | `bytes_written_total` | 64 | Total bytes written across both SQE segments. |
| 1 | `0x08` | `seg0_bytes_written` | 32 | Low half: bytes written into segment 0. |
| 1 | `0x0C` | `seg1_bytes_written` | 32 | High half: bytes written into segment 1. |
| 2 | `0x10` | `status_id` | 64 | `[15:0]=status`, `[31:16]=sqe_id`, `[63:32]=flags`. |
| 3 | `0x18` | `event_count` | 64 | Number of OPQ EOE boundaries observed in this drain. |
| 4 | `0x20` | `first_event_ts` | 64 | OPQ-side timestamp of first observed event. |
| 5 | `0x28` | `last_event_ts` | 64 | OPQ-side timestamp of last observed event. |
| 6 | `0x30` | `opq_drop_snapshot` | 64 | OPQ drop-counter snapshot supplied to `rdma_run_manager`; currently tied to zero at supercore level. |
| 7 | `0x38` | `retire_seq` | 64 | Per-run-manager monotonic retire sequence. |

| Status bit | Name | Meaning |
|---:|---|---|
| 0 | `EOE` | Drain ended after OPQ asserted EOP. |
| 1 | `FULL` | Drain ended because the SQE segment capacity was exhausted. |
| 2 | `HALT` | OPQ word was dropped because downstream packing could not accept it. |
| 3 | `SEG_BOUNDARY_HIT` | Drain crossed from segment 0 into segment 1. |
| 4 | `SEG0_ONLY` | Segment 1 was not used. |
| 5 | `ALIGN_ERR` | SQE address/span contract was invalid. |
| 6 | `AXI_ERR` | Host AXI4 write response was not OKAY. |
| 15:7 | reserved | Reserved, read as zero unless a future status bit is added. |

## 4. How to start

### 4.1 Clone + initialize

```bash
git clone https://github.com/yifeng-ethz/rdma_subsystem.git
cd rdma_subsystem
# or as a submodule of mu3e-ip-cores:
git submodule update --init --recursive rdma_subsystem
```

### 4.2 Standalone simulation

This repo has an integration-style `tb_int/uvm` harness rather than a unit
`tb/uvm` tree. The smoke target runs B001 at `DEBUG_LEVEL=1` and
`DEBUG_LEVEL=2`.

```bash
cd tb_int/uvm
make smoke
```

The direct single-case command used by the Makefile is:

```bash
cd tb_int/uvm
make DEBUG_LEVEL=1 TEST=test_b001_catalog CASE_ID=B001 run_one
```

### 4.3 Standalone synthesis

```bash
cd syn/quartus
quartus_sh --flow compile rdma_subsystem_standalone -c rdma_subsystem_standalone
```

The current standalone synthesis report is `syn/SYN_REPORT.md`; it records a
green Quartus 18.1.0 compile for revision `rdma_subsystem_standalone` at the
275 MHz 1.1x signoff corner.

## 5. CSR snapshot

`rdma_subsystem` has no separate `rdma_subsystem.svd` checked in. Its
`rdma_subsystem_hw.tcl` points the Qsys CSR SVD variable at
`../rdma_run_manager/rdma_run_manager.svd`, because the run manager owns the
only host-visible CSR aperture. Defaults below are the values read after reset,
using the reset struct in `rdma_run_manager_csr.sv` plus the SVD identity
metadata. `META` reads the version page at reset because `meta_sel` resets to 0.

| Offset | Name | Access | Width | Default | Description |
|-------:|------|:------:|-------|:--------:|-------------|
| `0x00` | `UID` | RO | 32 | `0x44514F50` | ASCII `DQOP`, DMA-Queue-OPQ subsystem identifier. |
| `0x04` | `META` | RW/RO | 32 | `0x1A0101FE` | Page-muxed metadata; reset page 0 reads VERSION. |
| `0x08` | `CTRL` | RW | 32 | `0x00000000` | Enable, reset-counters pulse, and halt control. |
| `0x0C` | `STATUS` | RO | 32 | `0x00000000` | Dispatch FSM and live worker handshake snapshot. |
| `0x10` | `SQ_BASE_LO` | RW | 32 | `0x00000000` | Low 32 bits of host SQ ring base address. |
| `0x14` | `SQ_BASE_HI` | RW | 32 | `0x00000000` | High 32 bits of host SQ ring base address. |
| `0x18` | `SQ_DEPTH` | RW | 32 | `0x00000000` | Low 16 bits hold SQ ring depth in entries. |
| `0x1C` | `SQ_TAIL_DBL` | WO | 32 | `0x00000000` | Host SQ tail doorbell; readback is debug-only latched tail. |
| `0x20` | `CQ_BASE_LO` | RW | 32 | `0x00000000` | Low 32 bits of host CQ ring base address. |
| `0x24` | `CQ_BASE_HI` | RW | 32 | `0x00000000` | High 32 bits of host CQ ring base address. |
| `0x28` | `CQ_DEPTH` | RW | 32 | `0x00000000` | Low 16 bits hold CQ ring depth in entries. |
| `0x2C` | `CQ_TAIL` | RO | 32 | `0x00000000` | Firmware CQ producer pointer; host polls this. |
| `0x30` | `CQ_HEAD_DBL` | WO | 32 | `0x00000000` | Host CQ head-credit doorbell; readback is debug-only latched head. |
| `0x34` | `CNT_SQE_CONSUMED` | RO | 32 | `0x00000000` | SQEs consumed since last reset-counter baseline. |
| `0x38` | `CNT_CQE_POSTED` | RO | 32 | `0x00000000` | CQEs posted since last reset-counter baseline. |
| `0x3C` | `CNT_BYTES_WRITTEN` | RO | 32 | `0x00000000` | Host-buffer bytes written by DMA engine. |
| `0x40` | `CNT_OPQ_INPUT_W` | RO | 32 | `0x00000000` | OPQ input words observed by DMA packer. |
| `0x44` | `CNT_HALT` | RO | 32 | `0x00000000` | OPQ halt/drop events reported by DMA engine. |
| `0x48` | `CNT_EOE_OBSERVED` | RO | 32 | `0x00000000` | OPQ EOE boundaries observed by DMA packer. |

### 5.1 `META` bit fields, offset `0x04`

| Bits | Field | Default | Description |
|------|-------|---------|-------------|
| `1:0` | `meta_sel` | `0` | Write page select: 0=VERSION, 1=DATE, 2=GIT, 3=INSTANCE_ID. |
| `31:2` | reserved | `0` | Writes ignored; reads as zero in selector view. |

| Page | Reset readback source | Value |
|---:|---|:---:|
| 0 | `{MAJOR[31:24], MINOR[23:16], PATCH[15:12], BUILD[11:0]}` | `0x1A0101FE` |
| 1 | `VERSION_DATE` | `0x0135269E` (`20260510` decimal) |
| 2 | `VERSION_GIT` | `0x0B66A91B` |
| 3 | `INSTANCE_ID` | `0x00000000` |

### 5.2 `CTRL` bit fields, offset `0x08`

| Bits | Field | Default | Description |
|------|-------|---------|-------------|
| `0` | `enable` | `0` | Master enable for SQE consumption and CQ posting. |
| `1` | `reset_counters` | `0` | Write-1 pulse; captures current counter baselines and clears CSR counter shadows. |
| `2` | `halt` | `0` | Soft halt; dispatch FSM stays idle and ignores new SQEs. |
| `31:3` | reserved | `0` | Reads as zero; writes ignored. |

### 5.3 `STATUS` bit fields, offset `0x0C`

| Bits | Field | Default | Description |
|------|-------|---------|-------------|
| `3:0` | `fsm_state` | `0` | Dispatch FSM: 0=IDLE, 1=DECODE, 2=DISPATCH_DMA, 3=BUILD_CQE, 4=RETIRE. |
| `4` | `sqf_sqe_valid` | `0` | Mirrored SQE stream valid from `rdma_sq_fetcher`. |
| `5` | `dma_job_req` | `0` | DMA job request asserted by run-manager FSM. |
| `6` | `dma_job_done` | `0` | DMA job completion observed. |
| `7` | `cqp_cqe_valid` | `0` | CQE stream valid toward `rdma_cq_pusher`. |
| `8` | `cqp_cqe_ready` | `0` | CQE stream ready from `rdma_cq_pusher`. |
| `9` | `halt_status` | `0` | Mirror of `CTRL.halt`. |
| `15:10` | reserved | `0` | Reads as zero. |
| `31:16` | `sq_head` | `0` | Current SQ consumer head from `rdma_sq_fetcher`. |

### 5.4 Ring and doorbell bit fields

| Register | Bits | Field | Default | Description |
|---|---|---|---|---|
| `SQ_DEPTH` | `15:0` | `depth` | `0` | SQ ring depth in SQE entries; host programs a power of two. |
| `SQ_DEPTH` | `31:16` | reserved | `0` | Reads as zero. |
| `SQ_TAIL_DBL` | `15:0` | `tail` | `0` | Host producer pointer; any write strobe creates one `sqf_sq_tail_dbl_pulse`. |
| `SQ_TAIL_DBL` | `31:16` | reserved | `0` | Ignored. |
| `CQ_DEPTH` | `15:0` | `depth` | `0` | CQ ring depth in CQE entries; host programs a power of two. |
| `CQ_DEPTH` | `31:16` | reserved | `0` | Reads as zero. |
| `CQ_HEAD_DBL` | `15:0` | `head` | `0` | Host consumer pointer credit; any write strobe creates one `cqp_cq_head_dbl_pulse`. |
| `CQ_HEAD_DBL` | `31:16` | reserved | `0` | Ignored. |

## 6. Versions + phase status

Current package identity is sourced from `rdma_subsystem_hw.tcl`,
`rdma_subsystem.qsys`, and `rtl/rdma_subsystem_pkg.sv`.

| Item | Value |
|---|---|
| Qsys component version | `26.1.0.0510` |
| RTL version parameters | `VERSION_MAJOR=26`, `VERSION_MINOR=1`, `VERSION_PATCH=0`, `BUILD=510` |
| Version date | `20260510` |
| Version git stamp | `0x0B66A91B` |
| UID | `0x44514F50` (`DQOP`) |
| Default widths | `DMA_DATA_W=256`, `WQE_BUS_W=512`, `DEBUG_LEVEL=0` |

Phase state, following `PHASE_STATUS.md`:

| IP | Phase A | Phase B | Phase C | Phase D | Unique-cov audit |
|---|---|---|---|---|---|
| `rdma_dma_engine` | DONE all 9 | PARTIAL: P bucket complete, X001-X016 done, X017-X128 user-authorized skip | DONE `QUEUE_MATH.md` | DONE `a6523a6` | RUNNING sweep |
| `rdma_sq_fetcher` | DONE all 9 | DONE all 512 evidenced | DONE `QUEUE_MATH.md` | DONE | DONE `6052c07` |
| `rdma_cq_pusher` | DONE all 9 | DONE all 512 evidenced | DONE `QUEUE_MATH.md` | DONE with authorized band relax | DONE `2e1ca03` |
| `rdma_run_manager` | DONE all 9 plus SVD | DONE all 512 evidenced | DONE `QUEUE_MATH.md` | DONE `8e58743` | DONE `64e4db8` |
| `rdma_subsystem` | Wrapper/Qsys/syn present in this repo | `tb_int/DV_REPORT.md` reports 512/512 evidenced and PASS | `test_plan/MATH_REVIEW.md` committed for system CP math | `syn/SYN_REPORT.md` reports GREEN standalone compile | No separate PHASE_STATUS row; generated tb_int scorecards and `make unique_coverage` are the local audit path |

Board-level `PHASE_STATUS.md` also records that 2026-05-11 real-traffic bring-up
is blocked at CP-C1 because FEB emulator run-control does not produce first
stage traffic. That is a system integration blocker, not a replacement for the
standalone `tb_int` and `syn` evidence above.

## 7. Cross-references

| Target | Pointer | Notes |
|---|---|---|
| Parent supercore | This repository | `rdma_subsystem` is the parent post-OPQ RDMA supercore; there is no higher-level `rdma_*` supercore repo. |
| `rdma_dma_engine` | `https://github.com/yifeng-ethz/rdma_dma_engine` | OPQ packer, DMA FIFO, host-buffer AXI4 writer. |
| `rdma_sq_fetcher` | `https://github.com/yifeng-ethz/rdma_sq_fetcher` | Host SQ ring reader and SQE stream source. |
| `rdma_cq_pusher` | `https://github.com/yifeng-ethz/rdma_cq_pusher` | CQE stream sink, CQ ring writer, MSI-X stub. |
| `rdma_run_manager` | `https://github.com/yifeng-ethz/rdma_run_manager` | CSR/SVD owner and SQE-to-DMA-to-CQE coordinator. |
| Run-control readyless fanout | `../run-control_mgmt/doc/RTL_PLAN.md`, `../run-control_mgmt/runctl_mgmt_host_hw.tcl` | System-level run-control AVST contract used by FEB/SWB integration. |
| SWB integration consumer | `/home/yifeng/packages/online_sc/online/switching_pc/a10_board/doc/RDMA_SUBSYSTEM_INTEGRATION_20260511.md` | Active SWB compile notes for replacing the post-OPQ mux/event-builder chain. |
| FEB SciFi style and integration context | `/home/yifeng/packages/online_dpv2/online/fe_board/fe_scifi/README.md` | Style reference and FEB-side run-control/upload context. |
| mu3e-ip-cores IP table | `https://github.com/yifeng-ethz/mu3e-ip-cores/blob/24582494f019ac7c46f3bbb7fe3e482173fee386/README.md` | Parent README auto-tracked IP table and pinned repo pointers. |
| Local architecture plan | `ARCHITECTURE_PLAN.md` | Host/FW SQ/CQ contract and Phase-1/Phase-2 split. |
| Local RTL plan | `RTL_PLAN_INT.md` | Supercore wrapper file set, top ports, xbar, CSR decode, reset plan. |
| Local DV plan | `DV_PLAN_INT.md` | Integration UVM scope and 4 bucket x 128 case plan. |
| Local CSR authority | `../rdma_run_manager/rdma_run_manager.svd`, `../rdma_run_manager/doc/csr_map.md` | SVD and generated CSR map consumed by this supercore package. |
| Relevant Claude memory | `/home/yifeng/.claude/projects/-home-yifeng-packages-mu3e-ip-dev/memory/feedback_swb_datapath_legacy_broken.md` | Records why the legacy post-OPQ event-builder path is replaced. |
| Relevant Claude memory | `/home/yifeng/.claude/projects/-home-yifeng-packages-online-dpv2-online/memory/project_feb_swb_runctl_protocol_mismatch.md` | Records the SWB/FEB run-control protocol mismatch. |
| Relevant Claude memory | `/home/yifeng/.claude/projects/-home-yifeng-packages-online-dpv2-online/memory/project_feb_upload_jtag_master_stalled.md` | Records the FEB upload-subsystem JTAG-master reachability blocker. |
