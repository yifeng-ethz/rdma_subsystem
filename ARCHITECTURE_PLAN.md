# `rdma_subsystem` — Architecture Plan

Status: **ARCHITECTURE — to be reviewed before per-IP RTL_PLAN.md.**
Pinned by user directive: "semi-permanent structural change so we can
validate first, then upgrade to full permanent structure for high performance
RDMA-like semantics".

This document covers the **subsystem**: how the constituent IPs fit
together, the host↔FW contract, register map ownership, and phasing.
Per-IP RTL details live in each IP's own `RTL_PLAN.md`.

## 1. Subsystem scope

`rdma_subsystem` consumes **OPQ egress** (Avalon-ST, 36-bit, 1 source)
and pushes hits into **host DRAM** under a Submission-Queue / Completion-Queue
contract (NVMe / RDMA-style):

- Host posts SQEs that name a target host DRAM region and capacity.
- The subsystem fetches SQEs from host DRAM, packs OPQ words, writes them
  as bursts into the named host buffer.
- When the buffer is filled or an end-of-event arrives, the subsystem
  writes a CQE into host DRAM and updates a CQ-tail register.
- Host polls `CQ_TAIL` or, in Phase 2, takes an MSI-X interrupt.

Replaces in `online_sc/online/common/firmware/a10/swb/swb_block.vhd`:
- `e_ingress_egress_adaptor.egress_mux` (keep ingress, replace egress)
- `e_musip_mux_4_1`
- `e_event_builder` (`musip_event_builder`)

OPQ itself is **NOT** modified.

## 2. IP partitioning

Each IP is a top-level git submodule under `mu3e-ip-cores/`, with its own
`RTL_PLAN.md`, its own `rtl/` `tb/uvm/` `syn/quartus/` `Makefile` `*.svd`
`*_hw.tcl`, and its own git repo (initialized locally Phase 1; pushed to
GitHub `yifeng-ethz` org and registered in `mu3e-ip-cores/.gitmodules`
once Phase 1 cosim PASSes). The supercore `rdma_subsystem/` is also a
top-level submodule alongside them — it integrates the four IPs as a
Qsys subsystem via its own `*.qsys` / `*.tcl` and contains this
`ARCHITECTURE_PLAN.md`.

| Folder (submodule)            | Kind     | Role                                                         | Owns                                            |
|-------------------------------|----------|--------------------------------------------------------------|-------------------------------------------------|
| `rdma_subsystem/`         | supercore | Subsystem assembly + architecture doc. No RTL of its own.    | This plan, `*.qsys`, `*.tcl`, integration TB.   |
| `rdma_dma_engine/`             | IP        | Pure data mover. Drains data ring → host buffer (via AVMM).  | OPQ packer, data ring FIFO, write engine.       |
| `rdma_sq_fetcher/`             | IP        | SQE puller. Fetches SQE from host SQ ring (via AVMM).        | SQ ring state, doorbell decode, sqe_out stream. |
| `rdma_cq_pusher/`              | IP        | CQE pusher. Writes CQE into host CQ ring (via AVMM).         | CQ ring state, MSI-X stub (Phase 2 wire).       |
| `rdma_run_manager/`            | IP        | Coordinator. Hooks SQ-fetch → DMA → CQ-push. Owns top CSR.   | SQE.opcode dispatch, sequencing FSM, BAR1 CSR.  |

This split lets each IP be developed and signed off independently. The
**run manager** is the only IP that knows about the SQ→DMA→CQ orchestration;
the other three are stateless workers that obey simple handshakes.

## 3. Subsystem dataflow

```
                           +--------------------+
                           | host DRAM (PCIe)   |
                           |  SQ ring           |
                           |  CQ ring           |
                           |  Data buffers      |
                           +--------------------+
                              ^   |       ^
                              |   v       |
                AVMM read --> sq_fetcher --+
                                          |
                                          v
                                  +-----------------+
              run_manager <-------|  SQE stream     |
                  |               +-----------------+
                  | program(buf_addr, len, sqe_id)
                  v
         OPQ ---> dma_engine ---------------> AVMM write to host buffer
                  | done(bytes_written, status, sqe_id)
                  v
         CQE ---> cq_pusher  ---------------> AVMM write to host CQ ring
                                              + update csr.CQ_TAIL
```

Data plane (high BW, OPQ-side cycles): `OPQ → dma_engine.packer → fifo →
dma_engine.writer → AVMM`.

Control plane (low BW, request/response): `host → csr.SQ_TAIL_DBL → sq_fetcher
→ run_manager → dma_engine → run_manager → cq_pusher → host`.

## 4. Bus protocols (AXI4 throughout)

All inter-IP and external-memory interfaces use **AXI4 family** so the
supercore can be assembled with non-Merlin / custom (or no) interconnect.
- **AXI4-Lite** for the BAR1 CSR slave (run_manager).
- **AXI4 (full)** for masters into host DRAM (sq_fetcher reads,
  dma_engine writes, cq_pusher writes).
- **AXI4-Stream** for point-to-point inter-IP streams (SQE bus, CQE bus,
  OPQ→dma_engine data bus).

A thin **AXI4 ↔ Avalon-MM bridge** sits between the IP block and the
existing PCIe HIP completer (Phase 2 — Altera/Intel A10 HIP exposes
Avalon-MM; the bridge wraps it as AXI4 for the IP-internal buses). Phase
1 stubs the AXI4 master with a SV `host_model_pkg.sv` AXI4 completer.

Default data widths:
- **Data plane** (OPQ → dma_writer → AXI4 master): `DMA_DATA_W = 256` bits
  (matches Altera A10 HIP TLP path; one beat = 32 B = ½ cacheline).
- **WQE plane** (sq_fetcher AXI4-Stream, cq_pusher AXI4-Stream, AXI4
  master read/write to SQ/CQ rings): `WQE_BUS_W = 512` bits — one beat
  carries one full 64 B WQE atomically.
- **CSR**: AXI4-Lite `S_AXIL_DATA_W = 32`, `S_AXIL_ADDR_W = 8` (256-byte
  aperture).

### `sq_fetcher → run_manager` (AXI4-Stream)

```
output [511:0] m_axis_sqe_tdata;     // one full SQE per beat
output         m_axis_sqe_tvalid;
input          m_axis_sqe_tready;
output         m_axis_sqe_tlast;     // always 1
output [15:0]  m_axis_sqe_tuser;     // sqe_id sideband (also in tdata)
```

### `run_manager → dma_engine` (job request — simple req/done)

```
output         job_req;
output [63:0]  job_seg0_addr;
output [63:0]  job_seg0_span;        // bytes, 4 KB multiple
output [63:0]  job_seg1_addr;        // 0 if unused
output [63:0]  job_seg1_span;        // 0 if unused
output [15:0]  job_sqe_id;
output [15:0]  job_opcode;
input          job_done;
input  [63:0]  job_bytes_written_total;
input  [31:0]  job_seg0_bytes_written;
input  [31:0]  job_seg1_bytes_written;
input  [15:0]  job_status;
input  [15:0]  job_sqe_id_echo;
input  [31:0]  job_event_count;
input  [63:0]  job_first_event_ts;
input  [63:0]  job_last_event_ts;
```

### `run_manager → cq_pusher` (AXI4-Stream)

```
output [511:0] s_axis_cqe_tdata;     // one full CQE per beat
output         s_axis_cqe_tvalid;
input          s_axis_cqe_tready;
output         s_axis_cqe_tlast;     // always 1
output [15:0]  s_axis_cqe_tuser;     // sqe_id (also in tdata)
```

### `OPQ → dma_engine` (AXI4-Stream, 36-bit)

```
input  [35:0]  s_axis_opq_tdata;     // {datak[3:0], data[31:0]}
input          s_axis_opq_tvalid;
output         s_axis_opq_tready;    // tied 1 in Phase 1
input          s_axis_opq_tlast;     // = OPQ eop
input  [1:0]   s_axis_opq_tuser;     // [0]=sop, [1]=reserved
```

### Host-DRAM AXI4 masters (sq_fetcher, dma_engine, cq_pusher)

Standard AXI4 (full) signals: AW/W/B, AR/R channels with 64-bit address,
configurable data width per IP (sq_fetcher 512b, dma_engine 256b,
cq_pusher 512b). Burst lengths capped to align with PCIe MPS (typically
4-8 beats at 256 B or 512 B per burst).

## 5. WQE wire format (64 bytes = one host cacheline)

All work-queue entries (SQE and CQE) are exactly **64 bytes** = the host
PC's L1/L2/L3 cacheline width (verified on the deployment box, AMD
Ryzen 9 3950X: 64 B coherency line at all levels). One WQE = one
cacheline = atomic visibility across host/FW with no false sharing.

### SQE (64 B, 8 × 64-bit words, host little-endian)

```
| word | byte off | name        | width | description |
|------|---------|-------------|-------|-------------|
| 0    | 0x00    | seg0_addr   | 64    | host phys addr of segment 0, **4 KB-aligned** |
| 1    | 0x08    | seg0_span   | 64    | seg-0 span in bytes, **4 KB multiple**, ≥ 4096 |
| 2    | 0x10    | seg1_addr   | 64    | host phys addr of segment 1, **4 KB-aligned** (0 if unused) |
| 3    | 0x18    | seg1_span   | 64    | seg-1 span in bytes, **4 KB multiple**, 0 if unused |
| 4    | 0x20    | opcode_id   | 64    | `[15:0]=opcode`, `[31:16]=sqe_id`, `[63:32]=flags` |
| 5    | 0x28    | reserved0   | 64    | reserved (timestamps / mr_keys / future) |
| 6    | 0x30    | reserved1   | 64    | reserved |
| 7    | 0x38    | reserved2   | 64    | reserved |
```

**Two-segment scatter semantics.** A single SQE may name 1 or 2
contiguous host-DRAM segments. The FW fills `seg0` first, and if the
drain produces more bytes than `seg0_span` AND `seg1_span > 0`, it
continues into `seg1`. This handles the case where the host's rx_buffer
pool is non-contiguous and a 4 KB-multiple SQE crosses one boundary,
without forcing the host to post 2 separate SQEs.

Constraints (FW asserts these, returns `ALIGN_ERR` in CQE if violated):
- `seg{0,1}_addr & 0xFFF == 0` (4 KB-aligned)
- `seg{0,1}_span & 0xFFF == 0` AND `seg{0,1}_span ≥ 0x1000` if non-zero
- Total span (`seg0_span + seg1_span`) ≤ 4 GiB in Phase 1

Opcodes:
- `0x0001` `DRAIN_UNTIL_EOE` — drain OPQ into the segments until end-of-event
  arrives or both segments are filled.
- (Phase 2) `0x0002` `DRAIN_FIXED_BYTES` — drain exactly `seg0_span+seg1_span`
  regardless of EOE.

### CQE (64 B, 8 × 64-bit words)

```
| word | byte off | name                  | width      | description |
|------|---------|-----------------------|------------|-------------|
| 0    | 0x00    | bytes_written_total   | 64         | total bytes written across both segments |
| 1    | 0x08    | seg0_bytes_written    | 32 (low)   | bytes actually written into seg0 |
|      |         | seg1_bytes_written    | 32 (high)  | bytes actually written into seg1 |
| 2    | 0x10    | status_id             | 64         | `[15:0]=status`, `[31:16]=sqe_id`, `[63:32]=flags` |
| 3    | 0x18    | event_count           | 64         | # of OPQ end-of-event boundaries observed in this drain |
| 4    | 0x20    | first_event_ts        | 64         | OPQ-side timestamp of first event in drain (debug) |
| 5    | 0x28    | last_event_ts         | 64         | OPQ-side timestamp of last event in drain (latency) |
| 6    | 0x30    | opq_drop_snapshot     | 64         | snapshot of OPQ FT_DROP_HIT counter at retire |
| 7    | 0x38    | retire_seq            | 64         | per-engine monotonic CQE sequence number |
```

Status bits (16):
- `[0]` `EOE`              — drain ended on end-of-event
- `[1]` `FULL`             — drain ended because both segments exhausted
- `[2]` `HALT`             — backpressure dropped data; engine should not
  raise this in steady state, host investigates if seen
- `[3]` `SEG_BOUNDARY_HIT` — informational; data spanned the seg0→seg1
  boundary (so host knows to look at both segments)
- `[4]` `SEG0_ONLY`        — informational; only seg0 was used
- `[5]` `ALIGN_ERR`        — refused: misaligned addr or non-4 KB span
- `[6:15]`                 — reserved

## 6. CSR aperture (BAR1, byte-addressed) — owned by `rdma_run_manager`

The run manager owns the only CSR aperture exposed to host. Sub-IPs do
not own host-visible registers; they expose their internal counters via
sideband to the run manager which surfaces them in its CSR.

| Offset | Name              | Access | Description |
|-------:|-------------------|:-----:|-------------|
| 0x00   | UID               | RO    | 0x44514F50 = "DQOP" (DMA-Queue-OPQ) |
| 0x04   | META              | RW    | meta_sel + read mux: VERSION/DATE/GIT/INSTANCE |
| 0x08   | CTRL              | RW    | bit0=enable, bit1=reset_counters, bit2=halt |
| 0x0C   | STATUS            | RO    | sub-IP busy bits + halted bit |
| 0x10   | SQ_BASE_LO        | RW    | host SQ ring base addr [31:0] |
| 0x14   | SQ_BASE_HI        | RW    | host SQ ring base addr [63:32] |
| 0x18   | SQ_DEPTH          | RW    | # of SQEs in ring (power of 2) |
| 0x1C   | SQ_TAIL_DBL       | WO    | host doorbell — write new tail |
| 0x20   | CQ_BASE_LO        | RW    | host CQ ring base addr [31:0] |
| 0x24   | CQ_BASE_HI        | RW    | host CQ ring base addr [63:32] |
| 0x28   | CQ_DEPTH          | RW    | # of CQEs in ring |
| 0x2C   | CQ_TAIL           | RO    | FW's CQ producer pointer (host poll target) |
| 0x30   | CQ_HEAD_DBL       | WO    | host doorbell — read pointer credit |
| 0x34   | CNT_SQE_CONSUMED  | RO    | from sq_fetcher |
| 0x38   | CNT_CQE_POSTED    | RO    | from cq_pusher |
| 0x3C   | CNT_BYTES_WRITTEN | RO    | from dma_engine |
| 0x40   | CNT_OPQ_INPUT_W   | RO    | from dma_engine.packer |
| 0x44   | CNT_HALT          | RO    | from dma_engine |
| 0x48   | CNT_EOE_OBSERVED  | RO    | from dma_engine.packer |

Aperture reachable both via **embedded JTAG Avalon master** (debug,
already serves OPQ CSRs) and via **PCIe BAR1** (production driver).

## 7. Phasing

| Phase | Sub-IPs touched | Validation surface |
|------:|-----------------|--------------------|
| Phase 1 — semi-permanent | All four (`dma_engine`, `sq_fetcher`, `cq_pusher`, `run_manager`) implemented with **AXI4 master stub** for the host side (SV `host_model_pkg.sv` AXI4 completer in cosim). 64 B WQE, 2-segment SQE, AXI4-Stream inter-IP — all final structural pieces. | Per-IP unit cosim + subsystem-level cosim under `tb_int/feb_swb_corun_rdma/`. |
| Phase 2 — permanent / RDMA | Insert thin **AXI4 ↔ Avalon-MM bridge** between each IP's AXI4 master and the existing Altera A10 PCIe HIP (Avalon-MM-side completer). Add MSI-X in `cq_pusher`. Add SQ prefetch in `sq_fetcher`. Optional: switch to a Vivado/Versal target by replacing the bridge with a native AXI4-PCIe core — IPs unchanged. | Hardware integration into `swb_block.vhd` (or a new Qsys/AXI subsystem). |

The structural break is Phase 1 → Phase 2 only at the master-side adapter
shim. No core FSM changes between phases. Because all internal buses are
AXI4 family, the supercore is portable across Merlin (Qsys), Xilinx
SmartConnect, ARM AMBA fabrics, or pure RTL stitching.

## 8. Per-IP delivery checklist

For each of the four IPs:

```
mu3e-ip-cores/misc/<ip_name>/
├── README.md
├── RTL_PLAN.md                    ← per-IP design plan (this file at parent)
├── doc/
│   └── csr_map.md                 (auto-generated from svd, if applicable)
├── rtl/
│   └── <ip_name>*.sv
├── tb/uvm/
│   ├── <ip_name>_tb_top.sv
│   └── Makefile                   (vsim QuestaOne 2026.1)
├── syn/quartus/
│   └── <ip_name>_standalone.qsf   (1.1× sign-off corner)
├── <ip_name>.svd                  (CSR map if applicable)
├── <ip_name>_hw.tcl               (Qsys IP definition)
├── Makefile                       (mu3e-ip-cores standard targets)
└── .git/                          (local-only Phase 1; remote later)
```

## 9. Subsystem-level integration cosim

Lives at `tb_int/feb_swb_corun_rdma/` (separate from existing
`feb_swb_corun/` so the new structure is validated independently of the
legacy one):

- DUT = subsystem assembly (4 IPs wired per §3-4) + real OPQ instance
  (from `opq_upstream_4lane_native_sv`).
- Host model from `tb/uvm/host_model_pkg.sv` — owns AVMM completer,
  posts SQEs, polls CQ.
- FEB stimulus from existing TB infrastructure (reuse `feb_swb_corun`
  generator helpers).
- Conservation invariants:
  - `sum(injected hit bytes) == sum(host buffer bytes after drain) + halt_bytes`
  - `cnt_sqe_consumed == cnt_cqe_posted` after drain
  - For each (sqe_id) issued, exactly one cqe with that sqe_id observed.

## 10. Risks & open architectural questions

- **Single QP vs N QPs**: Phase 1 = 1 QP. Add `N_QP` parameter on each
  sub-IP from day 1, default 1, so Phase 2 can scale without RTL changes.
- **AVMM data width**: 256b (matches OPQ packer + Altera bridge preference).
- **Per-SQE byte budget**: host-controlled via `buf_len_bytes`. No FW cap
  (simpler semantics; host responsible for sizing).
- **PCIe completer availability**: Phase 2 needs an `altera_avalon_mm_bridge`
  + `altera_pcie_a10_hip` inbound write/read window. Confirm before Phase 2.
- **Reset domains**: single `reset_n`. OPQ has its own reset chain.

## 11. Acceptance for this architecture

Architecture plan reviewed → write per-IP `RTL_PLAN.md` files → review →
implement RTL per IP → unit cosim per IP → subsystem cosim → Phase-2
hardware path.

Each IP folder has its own local git so each can be developed and
versioned independently. Push to remote once Phase 1 is complete.

## 12. Pointers

- Per-IP plans (sibling submodules at `mu3e-ip-cores/<ip>/RTL_PLAN.md`):
  - `rdma_dma_engine/RTL_PLAN.md`
  - `rdma_sq_fetcher/RTL_PLAN.md`
  - `rdma_cq_pusher/RTL_PLAN.md`
  - `rdma_run_manager/RTL_PLAN.md`
- Existing OPQ CSR access: `make ip-opq-csr-*` in `musip_2604`.
- Existing SWB datapath being replaced: `swb_block.vhd:347-417`.
- Diagnostic memory: `feedback_swb_datapath_legacy_broken.md`.
