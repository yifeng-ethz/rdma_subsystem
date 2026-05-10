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
| [BUG-002-R](#bug-002-r-legal-single-sqe-eoe-drain-retires-align-err-before-dma-writes) | R | hard stuck error | `common (nominal single SQE drain)` | open | `B017` DEBUG=1 isolated | `pending` | A legal single-SQE EOE drain returns CQE status ALIGN_ERR with zero bytes and no DMA writes in the assembled RTL. |

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
    - pending until the first full regression is run in this worktree
  - potential_hazard:
    - the local fallback DUT is only a testbench bootstrap path; final signoff
      still requires the sibling-owned `rtl/rdma_subsystem_top.sv`
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run in this turn
- Runtime / coverage context:
  - first full DEBUG=1/2 regression evidence is expected under
    `tb_int/uvm/logs` and `tb_int/uvm/cov_after`
- Commit:
  - pending

### BUG-002-R: Legal single-SQE EOE drain retires ALIGN_ERR before DMA writes
- First seen in:
  - `make -C tb_int/uvm DEBUG_LEVEL=1 TEST=test_b017_catalog CASE_ID=B017 run_one`
    on `2026-05-10`
- Symptom:
  - B017 posts one legal SQE and injects one OPQ frame, but the first CQE
    observed by the run_tool model has `sqe_id=0`, `status=0x0020`,
    `bytes=0`, `seg0=0`, and `seg1=0`
  - the host AXI completer observes only two host writes, matching the CQE
    write split, and no DMA rx_buffer writes before the CQE
- Root cause:
  - open
  - localized to the real assembled RTL SQ read / WQE width-adaptation path,
    not the local fallback model
  - TB diagnostic `+TB_INT_DIAG` shows the SQ fetch side requested one 64 B WQE
    at `0x0000100000000000`, but the returned 512-bit WQE had
    `word4=0x0000400000111000` equal to `word0`; the run-manager therefore
    decoded opcode low bits `0x1000` instead of `0x0001`
  - likely owner is the `rdma_subsystem_axi_xbar` 256-bit host-R to 512-bit
    SQ-WQE merge, or the adjacent SQ fetch width contract around that merge
- Fix status:
  - state:
    - open; RTL is sibling-owned and was not modified in this tb_int turn
  - mechanism:
    - pending sibling RTL fix or contract update
  - before_fix_outcome:
    - B017 DEBUG=1 isolated regression emits UVM_ERROR
      `expected EOE status got=0x0020`
    - diagnostic log includes
      `TB_INT_DIAG SQE_ACCEPT ... opcode_id=0x0000400000111000 ...`
  - after_fix_outcome:
    - pending
  - potential_hazard:
    - this blocks every nominal data-path case that expects OPQ bytes to reach
      host rx_buffer; only control-path idle/CSR cases can be green before it
      is fixed
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run in this turn
- Runtime / coverage context:
  - first-hit time in the B017 isolated run was `270 ns`; final simulation
    ended at `402 ns` after recording a failing scorecard
- Commit:
  - pending
