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
| [WARN] | stmt | 0.19 | 95.0 |
| [WARN] | branch | 0.00 | 90.0 |
| [INFO] | cond | 0.00 | - |
| [INFO] | expr | 0.00 | - |
| [PASS] | fsm_state | 100.00 | 95.0 |
| [WARN] | fsm_trans | 0.00 | 90.0 |
| [WARN] | toggle | 0.00 | 80.0 |

## Per-bucket merged totals

| status | bucket | stmt | branch | cond | expr | fsm_state | fsm_trans | toggle |
|:---:|---|---|---|---|---|---|---|---|
| [WARN] | [`BASIC`](REPORT/buckets/BASIC.md) | 0.78 | 0.00 | 0.00 | 0.00 | 100.00 | 0.00 | 0.00 |
| [WARN] | [`EDGE`](REPORT/buckets/EDGE.md) | n/a | n/a | n/a | n/a | n/a | n/a | n/a |
| [WARN] | [`PROF`](REPORT/buckets/PROF.md) | n/a | n/a | n/a | n/a | n/a | n/a | n/a |
| [WARN] | [`ERROR`](REPORT/buckets/ERROR.md) | n/a | n/a | n/a | n/a | n/a | n/a | n/a |

## Continuous-frame baselines by build

<!-- one row per bucket_frame / all_buckets_frame signoff run (see REPORT/cross/ for curves). -->

| status | run_id | kind | build | bucket | case_count | stmt | branch | toggle | functional_cross_pct | txns |
|:---:|---|---|---|---|---:|---|---|---|---:|---:|

_Regenerate with `python3 ~/.codex/skills/dv-workflow/scripts/dv_report_gen.py <tb>`._
