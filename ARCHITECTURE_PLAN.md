# `opq_rdma_subsystem` — Architecture Plan

Status: **ARCHITECTURE — to be reviewed before per-IP RTL_PLAN.md.**
Pinned by user directive: "semi-permanent structural change so we can
validate first, then upgrade to full permanent structure for high performance
RDMA-like semantics".

This document covers the **subsystem**: how the constituent IPs fit
together, the host↔FW contract, register map ownership, and phasing.
Per-IP RTL details live in each IP's own `RTL_PLAN.md`.

## 1. Subsystem scope

`opq_rdma_subsystem` consumes **OPQ egress** (Avalon-ST, 36-bit, 1 source)
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
once Phase 1 cosim PASSes). The supercore `opq_rdma_subsystem/` is also a
top-level submodule alongside them — it integrates the four IPs as a
Qsys subsystem via its own `*.qsys` / `*.tcl` and contains this
`ARCHITECTURE_PLAN.md`.

| Folder (submodule)            | Kind     | Role                                                         | Owns                                            |
|-------------------------------|----------|--------------------------------------------------------------|-------------------------------------------------|
| `opq_rdma_subsystem/`         | supercore | Subsystem assembly + architecture doc. No RTL of its own.    | This plan, `*.qsys`, `*.tcl`, integration TB.   |
| `opq_dma_engine/`             | IP        | Pure data mover. Drains data ring → host buffer (via AVMM).  | OPQ packer, data ring FIFO, write engine.       |
| `opq_sq_fetcher/`             | IP        | SQE puller. Fetches SQE from host SQ ring (via AVMM).        | SQ ring state, doorbell decode, sqe_out stream. |
| `opq_cq_pusher/`              | IP        | CQE pusher. Writes CQE into host CQ ring (via AVMM).         | CQ ring state, MSI-X stub (Phase 2 wire).       |
| `opq_run_manager/`            | IP        | Coordinator. Hooks SQ-fetch → DMA → CQ-push. Owns top CSR.   | SQE.opcode dispatch, sequencing FSM, BAR1 CSR.  |

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

## 4. Inter-IP handshake contracts

All inter-IP boundaries are **Avalon-ST** with simple `valid/ready/data`,
or **simple-pulse req/done** for control. No back-channel-laden bespoke
buses.

### `sq_fetcher → run_manager`

Avalon-ST source, payload = `sqe_t` (128 bits):
```
output [127:0] sqe_data;
output         sqe_valid;
input          sqe_ready;
```
`sqe_data` packs `{opcode_id[31:0], buf_len_bytes[31:0],
buf_addr_hi[31:0], buf_addr_lo[31:0]}`.

### `run_manager → dma_engine`

Simple req/done:
```
output         dma_req;
output [63:0]  dma_buf_addr;
output [31:0]  dma_buf_len_bytes;
output [15:0]  dma_sqe_id;
input          dma_done;
input  [31:0]  dma_bytes_written;
input  [15:0]  dma_status;
```

### `run_manager → cq_pusher`

Avalon-ST sink, payload = `cqe_t` (64 bits) + sqe_id sideband:
```
output [63:0]  cqe_data;
output [15:0]  cqe_sqe_id;
output         cqe_valid;
input          cqe_ready;
```

### `OPQ → dma_engine`

Avalon-ST sink, 36-bit (32b data + 4b datak) + sop/eop:
```
input  [35:0]  opq_data;
input          opq_valid;
input          opq_sop;
input          opq_eop;
output         opq_ready;        // tied 1 in Phase 1
```

## 5. SQE / CQE wire format

### SQE (16 bytes, host endian = little)

```
| 31..0          | 31..0          | 31..0          | 31..0          |
| buf_addr_lo    | buf_addr_hi    | buf_len_bytes  | opcode|sqe_id  |
```
- `opcode_id[15:0]` = `0x0001` = `DRAIN_UNTIL_EOE`
- `opcode_id[31:16]` = `sqe_id` (host-chosen tag)

### CQE (8 bytes)

```
| 31..0           | 31..0                            |
| bytes_written   | sqe_id[31..16] | status[15..0]   |
```
- `status[0]` = EOE (drain ended on end-of-event)
- `status[1]` = FULL (drain ended because buffer ran out)
- `status[2]` = HALT (data was dropped to a backpressure halt — should be 0)

## 6. CSR aperture (BAR1, byte-addressed) — owned by `opq_run_manager`

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
| Phase 1 — semi-permanent | All four (`dma_engine`, `sq_fetcher`, `cq_pusher`, `run_manager`) implemented with **Avalon-MM master stub** for the host side. Phase-1 cosim host model owns memory and responds to AVMM. | Per-IP unit cosim + subsystem-level cosim under `tb_int/feb_swb_corun_rdma/`. |
| Phase 2 — permanent / RDMA | Swap the Avalon-MM master in each IP for the real `altera_pcie_a10_hip` AVMM-to-PCIe completer. Add MSI-X in `cq_pusher`. Add SQ prefetch in `sq_fetcher`. Add scatter-gather SQE format in `dma_engine`. | Hardware integration into `swb_block.vhd`. |

The structural break is Phase 1 → Phase 2 only at the master-side adapter
of each IP. No core FSM changes between phases.

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
  - `opq_dma_engine/RTL_PLAN.md`
  - `opq_sq_fetcher/RTL_PLAN.md`
  - `opq_cq_pusher/RTL_PLAN.md`
  - `opq_run_manager/RTL_PLAN.md`
- Existing OPQ CSR access: `make ip-opq-csr-*` in `musip_2604`.
- Existing SWB datapath being replaced: `swb_block.vhd:347-417`.
- Diagnostic memory: `feedback_swb_datapath_legacy_broken.md`.
