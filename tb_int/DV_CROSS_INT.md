# DV_CROSS_INT.md - rdma_subsystem integration cross coverage

**Parent:** DV_PLAN_INT.md

## 1. Functional Coverpoints

| Coverpoint | Bins | Contract |
|---|---|---|
| run_state | idle, preparing, running, stopping, stopped | DV_PLAN_INT.md section 3.1 |
| sq_depth | 2, 4, 16, 256, 4096, 65536 | ARCHITECTURE_PLAN.md section 6 |
| cq_depth | 2, 4, 16, 256, 4096, 65536 | ARCHITECTURE_PLAN.md section 6 |
| seg_mode | single, two_segment, boundary_hit | ARCHITECTURE_PLAN.md section 5 |
| termination | EOE, FULL, ALIGN_ERR, HALT | ARCHITECTURE_PLAN.md section 5 |
| axi_profile | no_stall, read_stall, write_stall, mixed_stall, error_resp | DV_PLAN_INT.md Phase 2 |
| debug_level | dbg1_payload, dbg2_lineage | dv-workflow OoO datapath rule |

## 2. Crosses

| Cross | Intent |
|---|---|
| run_state x termination | legal stop and error outcomes in each host state |
| seg_mode x termination | EOE/FULL/error behavior across segment layouts |
| sq_depth x cq_depth x doorbell_coalesce | ring pointer and credit interaction |
| axi_profile x termination | host latency/error influence on completion status |
| debug_level x case_bucket | dbg1/dbg2 parity for every bucket |

## 3. Continuous-Frame Baselines

`bucket_frame_BASIC`, `bucket_frame_EDGE`, `bucket_frame_PROF`,
`bucket_frame_ERROR`, and `all_buckets_frame` are the required no-restart
baselines.  They must not overwrite isolated per-case UCDBs.
