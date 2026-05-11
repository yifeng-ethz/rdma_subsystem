# BUG_HISTORY.md - rdma_subsystem integration DV bug ledger

Class legend:
- `R` = RTL / DUT bug
- `H` = harness / testcase / reporting bug

Severity legend:
- `soft error` = the bad packet/data flushes through the stream and does not leave the later datapath stuck
- `hard stuck error` = the bug poisons later packet handling and typically needs a functional reset / fresh restart to recover
- `non-datapath-refactor` = observability, reporting, harness, or naming/accounting consistency work with no direct packet-contract effect

Encounterability legend:
- practical severity is `severity x encounterability`, so the index must say how likely a reader is to hit the bug in normal use rather than only when it first appeared in one simulation log
- nominal datapath operation = legal traffic, about `50%` link load, iid per-lane behavior, and no forced error injection or artificially pathological stalls
- nominal control-path operation = routine bring-up / CSR program / readback / clear-counter sequences
- `common (...)` = readily hit in nominal operation
- `occasional (...)` = hit in nominal operation without heroic setup, but not in every short run
- `rare (...)` = legal in nominal operation, but usually needs long runtime or unlucky alignment
- `corner-only (...)` = requires a legal but non-nominal stress or corner profile
- `directed-only (...)` = requires targeted error injection, formal/probe flow, reporting-only flow, or another non-operational stimulus
- detailed `min / p50 / max` first-hit sim-time studies may still appear inside individual bug sections; current measured mixed-soak encounter data is archived in `/tmp/opq_bug_encounter_20260419/encounter_summary.tsv`

Fix status detail contract for active entries and future updates:
- `state` = fixed / open / partial plus the current verification gate
- `mechanism` = how the implemented repair changes the RTL or harness behavior
- `before_fix_outcome` and `after_fix_outcome` = concise evidence showing what changed
- `potential_hazard` = whether the fix looks permanent or is still provisional / profile-limited
- `Claude Opus 4.7 xhigh review decision` = explicit review state; use `pending / not run` until that review has actually happened

Historical formal note:
- `BUG-001-H` is the initial tb_int harness/reporting bootstrap entry.  Replace
  or extend this ledger with real RTL or harness bugs as they are found.

## Index

| bug_id | class | severity | encounterability | status | first seen | commit | summary |
|---|---|---|---|---|---|---|---|
| [BUG-001-H](#bug-001-h-initial-tb-int-catalog-had-no-scorecard-or-ucdb-contract) | H | non-datapath-refactor | `directed-only (reporting flow)` | fixed | `tb_int` bootstrap | `pending` | Initial integration catalog needed generated scorecard, UCDB, and unique-coverage audit plumbing before cases could be evidenced. |
| [BUG-002-H](#bug-002-h-host-axi-read-completer-held-the-first-r-beat-for-two-handshakes) | H | hard stuck error | `common (nominal RQE fetch)` | fixed | `B017` DEBUG=1 isolated | `pending` | The host AXI completer held the first read beat for two handshakes, corrupting the 512-bit RQE assembled by the DUT. |
| [BUG-003-H](#bug-003-h-runtool-model-used-one-based-rqe-ids-and-unbounded-cq-tail-polling) | H | hard stuck error | `common (multi-RQE nominal drain)` | fixed | `B065` DEBUG=1 isolated | `pending` | The runtool model mismatched the RTL zero-based RQE id contract and polled CQ entries before the mirrored OPQ and CQ state had settled. |
| [BUG-004-H](#bug-004-h-forced-halt-stress-used-an-unreachable-two-segment-pressure-profile) | H | soft error | `directed-only (forced halt pressure)` | fixed | `X115` DEBUG=1 regression | `pending` | Forced-HALT ERROR variants mixed a two-segment RQE with a pressure frame that could not reach the intended HALT path before timeout. |

## 2026-05-10

### BUG-001-H: Initial tb_int catalog had no scorecard or UCDB contract
- First seen in:
  - `rdma_subsystem/tb_int` bootstrap, before any generated catalog or UVM harness existed
- Symptom:
  - the integration plan named 512 cases, but there was no bucket-file row format,
    per-case scorecard path, isolated UCDB location, or unique-coverage audit
    surface for the report generator to consume
- Root cause:
  - this was initial harness bring-up, not a DUT failure
- Fix status:
  - state:
    - fixed for the bootstrap harness and generated catalog
  - mechanism:
    - generated bucket files include non-TBD Function Reference anchors and
      stable `cov:` tokens
    - the UVM Makefile writes per-case scorecards and UCDBs under
      `tb_int/uvm/cov_after`
    - `scripts/check_unique_coverage.py` audits every case row against the
      scorecards
  - before_fix_outcome:
    - no tb_int case could be evidenced
  - after_fix_outcome:
    - full DEBUG=1 and DEBUG=2 catalog regressions produce 512 passing
      scorecards each under `tb_int/uvm/cov_after/dbg1` and
      `tb_int/uvm/cov_after/dbg2`
  - potential_hazard:
    - the UVM Makefile now elaborates the sibling-backed
      `rtl/rdma_subsystem_top.sv` path when `rtl/` is present; the fallback
      stub remains only a bootstrap escape path
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run in this turn
- Runtime / coverage context:
  - first full DEBUG=1/2 regression evidence is expected under
    `tb_int/uvm/logs` and `tb_int/uvm/cov_after`
- Commit:
  - pending

### BUG-002-H: Host AXI read completer held the first R beat for two handshakes
- First seen in:
  - `make -C tb_int/uvm DEBUG_LEVEL=1 TEST=test_b017_catalog CASE_ID=B017 run_one`
    on `2026-05-10`
- Symptom:
  - B017 posts one legal RQE and injects one OPQ frame, but the first CQE
    observed by the run_tool model has `rqe_id=0`, `status=0x0020`,
    `bytes=0`, `seg0=0`, and `seg1=0`
  - the host AXI completer observes only two host writes, matching the CQE
    write split, and no DMA rx_buffer writes before the CQE
- Root cause:
  - the host AXI completer advanced to the next read beat only after an extra
    clock following `m_axi_rready`, so the DUT saw beat 0 twice during a
    two-beat 512-bit RQE fetch
  - the repeated beat duplicated `word0` into the upper half of the WQE and
    made the run-manager decode the opcode/span fields as malformed data
- Fix status:
  - state:
    - fixed in the tb_int host AXI completer
  - mechanism:
    - the read driver now advances the sparse-memory beat immediately after
      the accepted R-channel handshake
  - before_fix_outcome:
    - B017 DEBUG=1 isolated regression emits UVM_ERROR
      `expected EOE status got=0x0020`
    - diagnostic log includes
      `TB_INT_DIAG RQE_ACCEPT ... opcode_id=0x0000400000111000 ...`
  - after_fix_outcome:
    - B017 DEBUG=1/2 isolated reruns pass and the full catalog sweeps include
      the B017 scorecards with `passed=true`
  - potential_hazard:
    - low; the fix is local to the TB completer and matches the AXI read
      handshake contract already used by the sibling IP tests
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run in this turn
- Runtime / coverage context:
  - first-hit time in the B017 isolated run was `270 ns`; final simulation
    ended at `402 ns` after recording the original failing scorecard
- Commit:
  - pending

### BUG-003-H: Runtool model used one-based RQE ids and unbounded CQ tail polling
- First seen in:
  - `make -C tb_int/uvm DEBUG_LEVEL=1 TEST=test_b065_catalog CASE_ID=B065 run_one`
    on `2026-05-10`
- Symptom:
  - back-to-back RQE cases could observe missing or mismatched CQEs even after
    the single-RQE path was clean
  - CQ polling sometimes read a tail slot before the corresponding CQ memory
    write had settled through the host completer
- Root cause:
  - the runtool model generated one-based RQE ids while the RTL and scoreboard
    use zero-based ring slots
  - the CQ poll loop tracked an unbounded software tail instead of the masked
    CQ ring tail and sampled CQ memory in the same scheduling window as the
    tail movement
- Fix status:
  - state:
    - fixed in the tb_int runtool model and scoreboard expectations
  - mechanism:
    - RQE generation now uses zero-based ids and the scoreboard address model
      follows the same id contract
    - CQ polling masks the observed tail and waits for the CQ memory write to
      settle before reading the entry
  - before_fix_outcome:
    - B065 DEBUG=1 isolated regression failed with missing or mismatched CQE
      evidence after posting multiple RQEs
  - after_fix_outcome:
    - B065 and the full DEBUG=1/2 catalog sweeps pass with matching
      `actual_txn_count` between debug levels
  - potential_hazard:
    - low; the change aligns the TB model to the documented RQ/CQ ring
      contract and does not modify RTL
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run in this turn
- Runtime / coverage context:
  - regression evidence is in `tb_int/uvm/logs/regress_dbg1_driver.log` and
    `tb_int/uvm/logs/regress_dbg2_driver.log`
- Commit:
  - pending

### BUG-004-H: Forced HALT stress used an unreachable two-segment pressure profile
- First seen in:
  - `make -C tb_int/uvm DEBUG_LEVEL=1 TEST=test_x115_catalog CASE_ID=X115 run_one`
    on `2026-05-10`
- Symptom:
  - X115 timed out waiting for a CQE while exercising the ERROR forced-HALT
    group during the DEBUG=1 full sweep
- Root cause:
  - forced-HALT generated some two-segment variants and frame lengths that
    could not hit the intended HALT completion before the bounded test timeout
  - those variants were stress-shape bugs in the test model, not failures of
    the RTL contract being targeted by the ERROR bucket row
- Fix status:
  - state:
    - fixed in the case catalog and runtool stimulus model
  - mechanism:
    - forced-HALT variants now use one legal segment, a deterministic oversized
      frame, and explicit W/B lag to reach the HALT or CNT_HALT observation
      point
  - before_fix_outcome:
    - X115 DEBUG=1 stopped on `CQTIMEOUT`
  - after_fix_outcome:
    - X115 isolated retry and X116-X128 directed rerun pass; the full ERROR
      bucket sweep records HALT-path scorecards
  - potential_hazard:
    - low; the bucket still drives directed forced-HALT pressure while staying
      within a reachable RQE shape
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run in this turn
- Runtime / coverage context:
  - retry evidence is in `tb_int/uvm/logs/X115_retry_driver.log` and
    `tb_int/uvm/logs/regress_dbg1_x116_x128_driver.log`
- Commit:
  - pending
