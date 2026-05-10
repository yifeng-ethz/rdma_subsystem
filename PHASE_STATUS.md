# `rdma_subsystem` Phase Status — 2026-05-10

Live status of the 4 sibling IPs that compose the supercore plus the
supercore wrapper itself. Snapshots the HEAD of each independent submodule.

## Phase summary

| IP                  | Phase A     | Phase B (RTL+UVM all-green) | Phase C (math) | Phase D (signoff) | Unique-cov audit | HEAD       |
|---------------------|:-----------:|:---------------------------:|:--------------:|:-----------------:|:----------------:|------------|
| `rdma_dma_engine`   | DONE all 9  | PARTIAL (P-bucket complete, X001-X016 done, X017-X128 pending — user-authorized skip) | DONE QUEUE_MATH.md | DONE (a6523a6)     | RUNNING (sweep) | `0fe4901` |
| `rdma_sq_fetcher`   | DONE all 9  | DONE all 512 evidenced       | DONE QUEUE_MATH.md | DONE          | DONE (`6052c07`) | `6052c07` |
| `rdma_cq_pusher`    | DONE all 9  | DONE all 512 evidenced       | DONE QUEUE_MATH.md | DONE (band-relax authorized) | DONE (`2e1ca03`) | `2e1ca03` |
| `rdma_run_manager`  | DONE all 9 + SVD | DONE all 512 evidenced   | DONE QUEUE_MATH.md | DONE (`8e58743`) | DONE (`64e4db8`) | `64e4db8` |

Supercore `rdma_subsystem/` Phase 1 wrapper: codex2 dispatched 2026-05-10
22:15 for `rtl/` + `syn/` (PID 15336) and `tb_int/` (PID 15541). HEAD
`1debddb` (plans only).

## Lines of code per IP

| IP                  | RTL files | RTL lines | UVM files | UVM lines |
|---------------------|----------:|----------:|----------:|----------:|
| `rdma_dma_engine`   |         4 |     1,205 |     1,050 |    30,050 |
| `rdma_sq_fetcher`   |         3 |       461 |        33 |     4,097 |
| `rdma_cq_pusher`    |         4 |       597 |        38 |    10,099 |
| `rdma_run_manager`  |         4 |     1,018 |        20 |     3,557 |
| **subtotal**        |    **15** |  **3,281** |  **1,141** | **47,803** |

(Counts captured 2026-05-10 from `find rtl/ tb/uvm/ -name '*.sv' -o -name '*.svh' -o -name '*.v' | xargs wc -l`.)

## Phase B closure status

- `rdma_sq_fetcher`: all-green Phase B closed at `5baa39b`, with 7 [FIX]
  commits (`402e969`, `c28c574`, `b2ee7dc`, `eb17cbc`, `24802c0`,
  `6100ca0`, `8389852`) catching real catalog/doorbell bugs along the way.
  Unique-coverage audit pass landed at `6052c07`.
- `rdma_cq_pusher`: all-green Phase B closed at `91b4564`. Phase D
  signed off at `df00d04` with user-authorized ALM band relax recorded
  at `eded444`. Unique-coverage audit pass landed at `2e1ca03`.
- `rdma_run_manager`: all-green Phase B closed at `83e8539`. Phase D
  signed off at `8e58743`. Unique-coverage audit pass landed at `64e4db8`.
- `rdma_dma_engine`: P-bucket fully evidenced (`7b50735`). ERROR bucket
  in progress at `0fe4901` (X001-X016 of X128); user-authorized to skip
  remaining ERROR cases and pivot to supercore work. The skipped ERROR
  cases remain as a known gap for a later closeout pass.

## Supercore work in flight (2026-05-10 22:15+)

Two codex2 5.5 xhigh sub-subagents are running with `/goal` slash +
iteration clause against the rdma_subsystem repo:

| Track       | PID    | Brief                                                          | Log                                            |
|-------------|-------:|----------------------------------------------------------------|------------------------------------------------|
| RTL + syn   | 15336  | `rtl/` 5 files + `rdma_subsystem.qsys` + `syn/` standalone close | `/tmp/codex2_rdma_subsystem_rtl.out`          |
| tb_int UVM  | 15541  | `tb_int/uvm/` 3 agents incl. software-behavioral run_tool model | `/tmp/codex2_rdma_subsystem_tb_int.out`       |

A thin Opus supervisor (agent `a2cc5721d3e2c6200`) is monitoring both
logs and the rdma_subsystem git head for progress and exit conditions.

## Phase A artifact counts

```
rdma_dma_engine     : full RTL + UVM + Phase D signoff
rdma_sq_fetcher     : full RTL + UVM + Phase D signoff
rdma_cq_pusher      : full RTL + UVM + Phase D signoff
rdma_run_manager    : full RTL + UVM + Phase D signoff + SVD
```

## Cross-IP consistency

Common Phase A files passed `dv_bucket_format_check.py` for the IPs that
have them. The DEBUG_LEVEL=1/2 dual-env contract is referenced in every
DV_HARNESS.md. The OPQ + rbcam reference IPs are cited as the style
guide in every DV_PLAN.md. The 64 B WQE / 4 KB-multiple span / 2-segment
SQE / AXI4 internal-bus decisions are unchanged from `ARCHITECTURE_PLAN.md`.

## Independent git histories

Each IP is its own git repo (`.git/` inside each folder). No parent
`mu3e-ip-cores/.gitmodules` entries for the rdma_* IPs yet — those land
once we push to remote.
