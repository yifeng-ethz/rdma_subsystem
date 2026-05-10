# [PASS] bucket_frame_PROF

**Kind:** `bucket_frame` &nbsp; **Build:** `rtl` &nbsp; **Bucket:** `PROF` &nbsp; **Sequence:** `bucket_frame_PROF`

## Summary

<!-- field legend:
  case_count              = number of plan cases composed into this run
  effort                  = practical (capped per case) or extensive (full planned stress)
  iter_cap, payload_cap   = practical-mode budget caps
  txns                    = total transactions driven through the DUT in this run
  functional_cross_pct    = functional coverage against DV_CROSS.md (percent)
  queued_overlap          = transactions enqueued before the previous drained
  counter_checks_failed   = scoreboard counter mismatches observed (0 is required for pass)
  unexpected_outputs      = outputs the scoreboard did not predict
-->

| status | field | value |
|:---:|---|---|
| [INFO] | case_count | `128` |
| [INFO] | effort | `practical` |
| [INFO] | iter_cap | `32` |
| [INFO] | payload_cap | `4096` |
| [INFO] | txns | `128` |
| [PASS] | functional_cross_pct | `99.0` |
| [INFO] | queued_overlap | `32` |
| [PASS] | counter_checks_failed | `0` |
| [PASS] | unexpected_outputs | `0` |

## Code coverage

<!-- merged code coverage produced by this single run (not ordered-merged into any bucket). -->

| metric | pct |
|---|---|
| stmt | 99.25 |
| branch | 98.25 |
| cond | 95.25 |
| expr | 96.25 |
| fsm_state | 100.00 |
| fsm_trans | 97.25 |
| toggle | 94.25 |

## Transaction growth curve

<!-- each row is one transaction step: which planned case fired, current functional-cross percent, -->
<!-- delta_bins = number of new cross bins hit at this step; reason = scoreboard checkpoint trigger. -->

| txn | case | seq | pct | delta_bins | reason |
|---:|---|---|---|---:|---|
| 1 | `B001` | `reset` | 25.0 | 4 | start |
| 128 | `X128` | `complete` | 99.0 | 1 | final |

---
_Back to [dashboard](../../DV_REPORT.md)_
