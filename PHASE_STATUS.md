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

## 2026-05-11 onboard real-traffic status

- The prior `TEST_PLAN.md`/`CHECKLIST.md` all-PASS state was an idle
  zero-traffic artifact and is no longer accepted. The evidence builders
  now require programmed traffic to produce a nonzero FEB-side first-stage
  delta and per-mode rate-consistent channel counts.
- Current live status is **blocked at CP-C1**. `S1_A_M4_R1` was rerun
  with 30 s windows and fails with `feb_rate_emulator_delta=0`; the
  counter and rate chains report `FAIL_AT_C1`, latency reports
  `FAIL_AT_L1`, and offline DMA reports `FAIL_AT_O4`.
- Slow control to the FEB datapath CSR window is known-good: `sc_tool 2
  diag` completes with OK replies, and emulator CSR writes read back
  correctly. The failing boundary is run-control into the FEB emulator.
  A short liveness sweep of reset-link destinations 0..7 kept the lane-0
  emulator status at `0x00000000` for every destination.
- Generated FEB v3 wiring shows `dbg_mm2runctrl_0` is not a usable
  fallback path in the archived pipe image: its CSR responds at
  `0x08880`, but the local self-run script never gets accepted
  (`sent_after=0`, `target=5`, status `0x00000807`/`0x0000080F`).
  A generated-VHDL debug image that wired this source into the v3
  splitter compiled and programmed, but broke FEB slow-control replies,
  so the board was restored to the archived pipe SOF
  (`top_nostp_pipe.sof`, checksum `0x13192DBC`). The next hardware probe
  must be at `runctl_mgmt_host` -> data-path `run_control_splitter.out15`
  -> `emulator_ctrl_splitter` -> `emulator_mutrig_0.ctrl_state_q`.
- Link-lock reporting was corrected to the live `online_sc` SWB map:
  `RESET_LINK_STATUS_REGISTER_R=0x35`, `LINK_LOCKED_LOW_REGISTER_R=0x36`,
  and `LINK_LOCKED_HIGH_REGISTER_R=0x37`. Per `/home/yifeng/CLAUDE.md`,
  `0x00000F00` is links 8..11, not the SciFi FEB at SWB link 2; CP-BU
  now requires bit 2 in `LINK_LOCKED_LOW_REGISTER_R`.
- The AXI4-W -> DMA-FIFO bridge remains a later CP-O4 dependency, but it
  is not the current blocker. The run stops before RDMA because the FEB
  emulator never produces first-stage traffic.
- `test_plan/MATH_REVIEW.md` committed at `dcc3d24` with the full S8
  derivation (rate models per mode, conservation chain, five lifetime
  D-equations, panel bounds table, 99% containment justification, and the
  R4 M0 Mode C max-rate envelope note).
- `test_plan/scripts/` committed at `d43b1f6` with the executable
  cohort/CP runners, four evidence builders, the deterministic
  `update_checklist.py` gate, the CI verifier, the pre-commit hook, and
  the STP recipe lookup TCL.

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
