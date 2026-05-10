# `rdma_subsystem` Phase Status — 2026-05-10

Live status of the 4 sibling IPs that compose the supercore. Snapshots the
HEAD of each independent submodule.

## Phase summary

| IP                  | Phase A | Phase B (RTL+UVM) | Phase C (math) | Phase D (report) | HEAD |
|---------------------|:-------:|:-----------------:|:--------------:|:----------------:|------|
| `rdma_dma_engine`   | ✅ all 9 files | ⏳ pending  | ✅ QUEUE_MATH.md | ⏳ pending | `e86986c` |
| `rdma_sq_fetcher`   | ✅ all 9 files | ✅ RTL+UVM+Qsys+syn | ✅ QUEUE_MATH.md | ⏳ pending | `0156ee2` |
| `rdma_cq_pusher`    | ⚠️ 4/9 files (BASIC/EDGE/PROF + DV_PLAN/HARNESS) | ⏳ pending  | ⏳ pending | ⏳ pending | `375b9b3` |
| `rdma_run_manager`  | ✅ all 9 files + SVD + csr_map | ⏳ pending | ✅ QUEUE_MATH.md | ⏳ pending | `b66a91b` |

`rdma_subsystem/` (supercore): ARCHITECTURE_PLAN.md + README.md committed at
`da87f27`. No RTL of its own.

## Phase A artifact counts

```
rdma_dma_engine     : 11 tracked files  (RTL_PLAN, doc/QUEUE_MATH, tb/9 DV files)
rdma_sq_fetcher     : 53 tracked files  (full RTL + UVM + Qsys + Quartus standalone)
rdma_cq_pusher      :  6 tracked files  (RTL_PLAN, tb/DV_PLAN/HARNESS/BASIC/EDGE/PROF)
rdma_run_manager    : 14 tracked files  (RTL_PLAN, doc/2, svd, script/1, tb/9 DV files)
```

## Phase B leader: `rdma_sq_fetcher`

The SQ fetcher Opus IP-lead successfully dispatched codex2 5.5 xhigh
sub-subagents in parallel (RTL + UVM TB), and they delivered. 11 commits:

```
0156ee2  [NEW] Add DEBUG scorecard cross validation
f4981b2  [NEW] Add rdma sq fetcher smoke tests
8165cd1  [NEW] Add SQ fetcher standalone Quartus project
23150b2  [NEW] Add rdma sq fetcher scoreboard
12af247  [NEW] Add SQ fetcher Qsys package
cef0ecd  [NEW] Add rdma sq fetcher UVM agents
7962a47  [NEW] Add SQ fetcher top RTL
2d05645  [NEW] Add rdma sq fetcher UVM skeleton
79e76c6  [NEW] Add rdma_sq_fetcher DV plan and queue-math sign-off
```

Files include `rtl/rdma_sq_fetcher.sv`, `rtl/rdma_sq_axi_reader.sv`,
`rtl/rdma_sq_ring_state.sv`, `tb/uvm/axi4_completer_agent/...` (full UVM
agent), `tb/uvm/Makefile`, `syn/quartus/rdma_sq_fetcher_standalone.qsf`,
`rdma_sq_fetcher_hw.tcl`. This is the Phase 1 gold standard.

## Gap: `rdma_cq_pusher`

Missing files (DV_ERROR, DV_COV, DV_CROSS, BUG_HISTORY, doc/QUEUE_MATH).
The Opus IP-lead hit usage cap before completing Phase A. The dispatched
codex2 produced bucket drafts (BASIC/EDGE/PROF) that I committed at
`375b9b3` after format-checking. The remaining 5 files will be scaffolded
in a follow-up commit using the patterns from the sibling IPs.

## Quota refresh and next steps

Opus 4.7 quota resets 4:40 pm Europe/Zurich. Priorities for next pass:

1. Complete `rdma_cq_pusher` Phase A gap (5 files).
2. Dispatch codex2 5.5 xhigh for Phase B on `rdma_dma_engine` and
   `rdma_run_manager` (RTL + UVM TB).
3. Final Phase D report consolidation across all 4 IPs.
4. Once Phase B passes per-IP unit cosim, build the subsystem-level
   integration cosim under `rdma_subsystem/tb_int/` (architecture
   plan §9).

## Cross-IP consistency

Common Phase A files passed `dv_bucket_format_check.py` for the IPs that
have them. The DEBUG_LEVEL=1/2 dual-env contract is referenced in every
DV_HARNESS.md. The OPQ + rbcam reference IPs are cited as the style guide
in every DV_PLAN.md. The 64 B WQE / 4 KB-multiple span / 2-segment SQE /
AXI4 internal-bus decisions are unchanged from `ARCHITECTURE_PLAN.md`.

## Independent git histories

Each IP is its own git repo (`.git/` inside each folder). No parent
`mu3e-ip-cores/.gitmodules` entries for the rdma_* IPs yet — those land
once we push to remote.
