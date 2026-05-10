# `opq_dma_engine` — Submission/Completion-Queue DMA engine for OPQ egress

## What this IP replaces

The legacy SWB datapath after OPQ
(`musip_event_builder` + `musip_mux_4_1` + `ingress_egress_adaptor egress_mux`
in `online_sc/online/common/firmware/a10/swb/swb_block.vhd:347-417`) is
unusable: on hardware it skipped 100% of events
(`EVENT_SKIP_EVENT_DMA_R = 45 M`) while OPQ delivered 191 M hits with zero
drops. See `feedback_swb_datapath_legacy_broken.md`.

`opq_dma_engine` replaces all of that with a single IP block that consumes
OPQ egress and writes hits into host memory under host-controlled
**Submission Queue / Completion Queue** semantics. Same model as NVMe and
RDMA: the host owns its buffers and tells the FW where to drain into.

## Architecture (SQ/CQ + host-model contract)

```
                                                    +---------------+
                  Host memory (PCIe BAR0 master)    |   Host driver |
                                                    | (mu3e_capture)|
   +------------------+                             |               |
   |  SQ ring         | <---- post SQE, ring tail   |               |
   |  CQ ring         | ----> CQE arrives, ring head|               |
   |  Data buffers    | <---- DMA writes from FW    |               |
   +------------------+                             +---------------+
        ^   |                                              ^
        |   v                                              |
        |  +--- sq_fetcher (read SQEs via PCIe BAR1) ---+  |
        |  |                                            |  |  doorbells
        |  v                                            |  |  via BAR1
   +-------------------------------------------------+  |  |  CSR
   |              opq_dma_engine                     |  |  |
   |                                                 |  |  |
   |  +------+   +-----------+   +---------------+   |  |  |
   |  | OPQ  |->| dma_packer |->| dma_writer    |---+--+  |
   |  |egress|  | (32b->256b)|  | (PCIe master) |       (CQ)
   |  +------+   +-----------+   +---------------+
   |                              | + cq_writer ---->----+
   +-------------------------------------------------+
```

## Host ↔ FW contract

### Submission Queue Entry (SQE) — 16 bytes

```
| 31..0          | 31..0          | 31..0          | 31..0          |
| buf_addr_lo    | buf_addr_hi    | buf_len_bytes  | opcode|sqe_id  |
```

- `buf_addr` — 64-bit host physical address (PCIe-visible)
- `buf_len_bytes` — maximum bytes FW may write into this buffer
- `opcode` — `0x01 = drain_until_eoe_or_full`
- `sqe_id` — host-chosen tag echoed back in CQE

### Completion Queue Entry (CQE) — 8 bytes

```
| 31..0           | 31..0                |
| bytes_written   | status (15..0) | sqe_id (31..16) |
```

- `bytes_written` — actual bytes FW wrote to the SQE buffer (≤ buf_len_bytes)
- `status` — 0=ok, bit 0=eoe (end-of-event reached), bit 1=full (buffer full),
            bit 2=halt (backpressure dropped data — should never happen with
            correct sizing)
- `sqe_id` — echo of submitting SQE's tag

### Doorbells

- Host posts SQE: write SQ ring at host pointer, then `SQ_TAIL_DBL <- new_tail`
  (single MMIO write to FW CSR).
- FW reports CQE: writes CQE to host CQ ring, then atomically updates
  `CQ_TAIL` field in CSR (host polls or uses MSI-X interrupt later).

## CSR aperture (BAR1, byte-addressed)

| Offset | Name              | Access | Description |
|-------:|-------------------|:-----:|-------------|
| 0x00   | UID               | RO    | 0x44514F50 = "DQOP" (DMA-Queue-OPQ) |
| 0x04   | META              | RW    | meta_sel + read mux: VERSION/DATE/GIT/INSTANCE |
| 0x08   | CTRL              | RW    | bit0=enable, bit1=reset_counters, bit2=halt |
| 0x0C   | STATUS            | RO    | bits[3:0]=fsm_state, bit4=sq_busy, bit5=cq_busy, bit6=halted |
| 0x10   | SQ_BASE_LO        | RW    | host SQ ring base addr [31:0] |
| 0x14   | SQ_BASE_HI        | RW    | host SQ ring base addr [63:32] |
| 0x18   | SQ_DEPTH          | RW    | # of SQEs in ring (power of 2; mask = depth-1) |
| 0x1C   | SQ_TAIL_DBL       | WO    | host doorbell — write new tail to kick FW |
| 0x20   | CQ_BASE_LO        | RW    | host CQ ring base addr [31:0] |
| 0x24   | CQ_BASE_HI        | RW    | host CQ ring base addr [63:32] |
| 0x28   | CQ_DEPTH          | RW    | # of CQEs in ring |
| 0x2C   | CQ_TAIL           | RO    | FW's CQ producer pointer (host poll target) |
| 0x30   | CQ_HEAD_DBL       | WO    | host doorbell — write new head to credit FW |
| 0x34   | CNT_SQE_CONSUMED  | RO    | count of SQEs FW has fetched |
| 0x38   | CNT_CQE_POSTED    | RO    | count of CQEs FW has written |
| 0x3C   | CNT_BYTES_WRITTEN | RO    | total bytes FW wrote into host buffers |
| 0x40   | CNT_OPQ_INPUT_W   | RO    | count of 32b OPQ egress words seen |
| 0x44   | CNT_HALT          | RO    | count of beats dropped due to backpressure |
| 0x48   | CNT_EOE_OBSERVED  | RO    | count of OPQ end-of-event boundaries |

Reachable both via:
- The SWB-side embedded **Avalon-MM JTAG master** (same one that already
  serves OPQ CSRs at SWB phy_1) — for debug/bring-up access by `mu3e_capture`.
- The PCIe BAR1 register window — for production driver access.

## Phase plan

**Phase 1 — semi-permanent (this commit):**
- IP scaffolding under `mu3e-ip-cores/misc/opq_dma_engine/` matches house
  conventions (rtl/, tb/uvm/, syn/quartus/, hw.tcl, svd, README,
  Makefile target).
- RTL with the SQ/CQ FSM but **dummy PCIe master** stubs (read/write
  Avalon-MM, not real PCIe TLPs). The cosim TB models the host with a
  SystemVerilog process that owns "host memory" arrays.
- Validates end-to-end: host posts SQE, FW drains OPQ into the host buffer,
  FW writes CQE, host reads bytes back, conservation: bytes_written ==
  hits·4 + framing bytes.
- Drops in as a Qsys IP (hw.tcl). Wired into a new SWB Qsys system in a
  later commit.

**Phase 2 — full RDMA-like (future):**
- Replace dummy PCIe-master Avalon stubs with real PCIe DMA write requests
  (in-flight TLP credits, write combining).
- Add MSI-X interrupt on CQ producer.
- Add SQ prefetch (FW pulls multiple SQEs ahead).
- Add gather-scatter SQE format (multiple buffer fragments per descriptor).
- Add memory-region keys (R_KEY) for security if used outside trusted DMA.
- Optional: NIC-bypass / GPU-direct destinations.

## Files

```
opq_dma_engine/
├── README.md                         (this file)
├── doc/
│   └── csr_map.md                    (auto-generated from svd)
├── rtl/
│   ├── opq_dma_engine.sv             top
│   ├── opq_dma_packer.sv             (32b -> 256b accumulator, no-skip)
│   ├── opq_dma_sq_fetcher.sv         (SQE fetch + parser)
│   ├── opq_dma_writer.sv             (host-buffer write engine)
│   ├── opq_dma_cq_writer.sv          (CQE producer)
│   └── opq_dma_engine_csr.sv         (BAR1 register file)
├── tb/uvm/
│   ├── opq_dma_engine_tb_top.sv      cosim with software-model host
│   ├── host_model_pkg.sv             SQ/CQ ring + buffer model
│   └── Makefile                      vsim QuestaOne 2026.1
├── syn/quartus/
│   └── opq_dma_engine_standalone.qsf standalone fitter for sign-off
├── opq_dma_engine.svd                CSR map (CMSIS-SVD)
├── opq_dma_engine_hw.tcl             Qsys IP definition
└── Makefile                          standard mu3e-ip-cores targets
```
