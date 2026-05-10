# `rdma_subsystem` — SWB datapath supercore (post-OPQ)

`rdma_subsystem` is the **supercore** that integrates the four sibling
`rdma_*` IPs into a single Qsys-packaged subsystem that replaces the
legacy SWB datapath after OPQ. It owns the supercore-level integration
wiring, the internal AXI4 crossbar, the BAR1 CSR passthrough, the
reset chain, and the standalone Quartus signoff. It does **not** own
any datapath functional logic of its own — every block of functional
behavior lives in one of the four submodule IPs.

## Sibling IPs

| IP                  | Role                                                 |
|---------------------|------------------------------------------------------|
| `rdma_dma_engine`   | OPQ egress -> host rx-buffer DMA writer (data mover) |
| `rdma_sq_fetcher`   | Host SQ ring -> in-FW SQE FIFO (descriptor puller)   |
| `rdma_cq_pusher`    | In-FW CQE FIFO -> host CQ ring (completion poster)   |
| `rdma_run_manager`  | Coordinator, BAR1 CSR slave, run-state FSM, SVD owner|

Each IP is an independent git submodule under
`mu3e-ip-cores/rdma_<name>/` with its own RTL, UVM TB, Qsys packaging,
standalone Quartus signoff, and DV_REPORT. The supercore consumes them
as already-validated components.

## What this supercore replaces

The legacy SWB datapath after OPQ (`musip_event_builder` +
`musip_mux_4_1` + `ingress_egress_adaptor egress_mux` in
`online_sc/online/common/firmware/a10/swb/swb_block.vhd`) skipped 100%
of events on hardware (`EVENT_SKIP_EVENT_DMA_R = 45 M`) while OPQ
delivered 191 M hits with zero drops. See
`feedback_swb_datapath_legacy_broken.md`. `rdma_subsystem` replaces all
of that with NVMe/RDMA-style SQ/CQ semantics: the host owns its
rx_buffers and tells FW where to drain into.

## Architecture (one-line)

```
                                                       +---------------+
                                                       |   Host driver |
                                                       | (run_tool sw) |
                                                       +---------------+
                                                              ^
                                                              | BAR1 CSR
                                                              v
   +------------------+      +-----------------------------+
   |  Host DRAM       |      |        rdma_subsystem       |
   |  SQ ring         |<-----| (this supercore wrapper)    |
   |  CQ ring         |----->|                             |
   |  rx_buffers      |<-----|                             |
   +------------------+      |  sq_fetcher  --+            |
                             |  run_manager <-+--> dma_eng |
                             |                +--> cq_push |
   OPQ AXIS  ----------------+--------------------+         |
                             +-----------------------------+
```

Full architecture, host-FW contract (64 B WQE, 2-segment SQE, 4 KB
span quantum), CSR aperture map, and phasing are in
`ARCHITECTURE_PLAN.md`. Supercore-internal RTL wiring (5 wrapper files,
AXI4 crossbar, reset chain, Qsys packaging) is in `RTL_PLAN_INT.md`.
Supercore-level integration cosim (3 UVM agents incl. software-behavioral
run_tool model, 4 buckets x 128 cases) is in `DV_PLAN_INT.md`.

## Phasing

- **Phase 1 (in flight)** — Wrapper RTL + Qsys packaging + standalone
  Quartus signoff + `tb_int/` integration cosim. Each sub-IP is already
  Phase-D-closed; the supercore wraps them.
- **Phase 2** — Replace the AXI4 master output with a thin AXI4 <-> AVMM
  bridge into the existing Altera A10 PCIe HIP completer; hook MSI-X
  generation; integrate into `swb_block.vhd`.

## Files

```
rdma_subsystem/
|-- README.md                          (this file)
|-- ARCHITECTURE_PLAN.md               supercore architecture + host-FW contract
|-- RTL_PLAN_INT.md                    supercore wrapper RTL plan
|-- DV_PLAN_INT.md                     supercore tb_int integration cosim plan
|-- PHASE_STATUS.md                    live dashboard across 4 IPs + supercore
|-- rtl/                               wrapper RTL (in flight)
|-- syn/quartus/                       standalone Quartus project (in flight)
|-- tb_int/                            integration cosim (in flight)
|-- rdma_subsystem.qsys                Qsys system (in flight)
`-- rdma_subsystem_hw.tcl              Qsys IP description (in flight)
```

## Status

See `PHASE_STATUS.md` for the live snapshot of all 4 sibling IPs and
the supercore implementation in flight.
