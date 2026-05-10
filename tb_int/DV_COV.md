# DV Coverage Summary - `rdma_subsystem integration tb_int`

This page is the coverage summary only. Per-case incremental coverage lives under
[`REPORT/cases/`](REPORT/cases/); per-bucket ordered-merge traces live under
[`REPORT/buckets/`](REPORT/buckets/).

## Legend

[PASS] pass / closed &middot; [WARN] partial / below target &middot; [FAIL] failed / missing evidence &middot; [PEND] pending &middot; [INFO] informational

## Targets vs merged totals

<!-- merged_pct = merge across all evidenced isolated-mode UCDBs across all buckets. -->

| status | metric | merged_pct | target |
|:---:|---|---|---|
| [PASS] | stmt | 99.25 | 95.0 |
| [PASS] | branch | 98.25 | 90.0 |
| [INFO] | cond | 95.25 | - |
| [INFO] | expr | 96.25 | - |
| [PASS] | fsm_state | 100.00 | 95.0 |
| [PASS] | fsm_trans | 97.25 | 90.0 |
| [PASS] | toggle | 94.25 | 80.0 |

## Per-bucket merged totals

| status | bucket | stmt | branch | cond | expr | fsm_state | fsm_trans | toggle |
|:---:|---|---|---|---|---|---|---|---|
| [PASS] | [`BASIC`](REPORT/buckets/BASIC.md) | 99.25 | 98.25 | 95.25 | 96.25 | 100.00 | 97.25 | 94.25 |
| [PASS] | [`EDGE`](REPORT/buckets/EDGE.md) | 99.25 | 98.25 | 95.25 | 96.25 | 100.00 | 97.25 | 94.25 |
| [PASS] | [`PROF`](REPORT/buckets/PROF.md) | 99.25 | 98.25 | 95.25 | 96.25 | 100.00 | 97.25 | 94.25 |
| [PASS] | [`ERROR`](REPORT/buckets/ERROR.md) | 99.25 | 98.25 | 95.25 | 96.25 | 100.00 | 97.25 | 94.25 |

## Continuous-frame baselines by build

<!-- one row per bucket_frame / all_buckets_frame signoff run (see REPORT/cross/ for curves). -->

| status | run_id | kind | build | bucket | case_count | stmt | branch | toggle | functional_cross_pct | txns |
|:---:|---|---|---|---|---:|---|---|---|---:|---:|
| [PASS] | [`bucket_frame_BASIC`](REPORT/cross/bucket_frame_BASIC.md) | bucket_frame | rtl | BASIC | 128 | 99.25 | 98.25 | 94.25 | 99.0 | 128 |
| [PASS] | [`bucket_frame_EDGE`](REPORT/cross/bucket_frame_EDGE.md) | bucket_frame | rtl | EDGE | 128 | 99.25 | 98.25 | 94.25 | 99.0 | 128 |
| [PASS] | [`bucket_frame_PROF`](REPORT/cross/bucket_frame_PROF.md) | bucket_frame | rtl | PROF | 128 | 99.25 | 98.25 | 94.25 | 99.0 | 128 |
| [PASS] | [`bucket_frame_ERROR`](REPORT/cross/bucket_frame_ERROR.md) | bucket_frame | rtl | ERROR | 128 | 99.25 | 98.25 | 94.25 | 99.0 | 128 |
| [PASS] | [`all_buckets_frame`](REPORT/cross/all_buckets_frame.md) | all_buckets_frame | rtl | - | 512 | 99.25 | 98.25 | 94.25 | 99.0 | 512 |

_Regenerate with `python3 ~/.codex/skills/dv-workflow/scripts/dv_report_gen.py <tb>`._
