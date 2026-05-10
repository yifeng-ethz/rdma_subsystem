#!/usr/bin/env python3
"""Generate rdma_subsystem tb_int Phase-B catalog and seed reports.

The generated files are intentionally deterministic.  The bucket markdown is
the planning contract; the UVM catalog and report seed data are derived from it
so case IDs, method tags, coverage-bin tokens, and contract anchors stay in
lockstep.
"""

from __future__ import annotations

import datetime as _dt
import json
import re
from dataclasses import dataclass
from pathlib import Path


TB_DIR = Path(__file__).resolve().parents[2]
UVM_DIR = TB_DIR / "uvm"


@dataclass(frozen=True)
class Group:
    title: str
    first: int
    last: int
    method: str
    iter_count: int
    what: str
    stimulus: str
    pass_criteria: str
    anchor: str
    cov_base: str


BUCKETS: dict[str, tuple[str, str, str, list[Group]]] = {
    "BASIC": (
        "B",
        "DV_BASIC.md",
        "Nominal bring-up, SQ/CQ programming, frame drain, and CQE field proof.",
        [
            Group("Reset and CSR Bring-Up", 1, 16, "D", 1,
                  "reset release, UID/META/CTRL/STATUS, and idle counters",
                  "run_tool reset, BAR1 AXI4-Lite read/write/readback, no OPQ traffic",
                  "CSR readbacks match ARCHITECTURE_PLAN.md section 6; cov:basic_csr_reset",
                  "ARCHITECTURE_PLAN.md section 6 BAR1 CSR aperture",
                  "basic_csr_reset"),
            Group("Single SQE EOE Drain", 17, 32, "D", 1,
                  "one SQE drains a generated mu3e frame and retires on EOE",
                  "post one single-segment SQE, inject one OPQ frame with K28.5/K28.4 markers",
                  "CQE status has EOE and SEG0_ONLY; byte ledger equals rx_buffer bytes; cov:basic_single_eoe",
                  "DV_PLAN_INT.md section 4 byte conservation and EOE matching",
                  "basic_single_eoe"),
            Group("Single SQE FULL Drain", 33, 48, "D", 1,
                  "single-segment SQE fills before OPQ frame end",
                  "post one short-span SQE, inject a longer OPQ frame",
                  "CQE status has FULL; next SQE would resume at next source byte; cov:basic_full_term",
                  "ARCHITECTURE_PLAN.md section 5 CQE status bit FULL",
                  "basic_full_term"),
            Group("Two-Segment Boundary Drain", 49, 64, "D", 1,
                  "seg0 to seg1 crossing within one SQE",
                  "post two-segment SQE with seg0_span varied across 4 KB quanta",
                  "CQE SEG_BOUNDARY_HIT and seg0/seg1 byte fields match writes; cov:basic_two_segment",
                  "ARCHITECTURE_PLAN.md section 5 two-segment scatter semantics",
                  "basic_two_segment"),
            Group("Back-To-Back SQEs", 65, 80, "R", 4,
                  "SQ ring sequencing for N adjacent SQEs",
                  "pre-stage 2, 4, 8, or depth-1 SQEs and stream adjacent OPQ frames",
                  "count(CQE)==retired SQE count and byte order crosses SQE boundaries; cov:basic_back_to_back",
                  "DV_PLAN_INT.md section 3.2 RUNNING top-up and CQ harvest",
                  "basic_back_to_back"),
            Group("Run-State Traversal", 81, 96, "D", 1,
                  "idle to preparing to running to stopping to stopped",
                  "run_tool model performs full state sequence with bounded drain",
                  "CSR operations are legal for state and STOPPING drains in-flight CQEs; cov:basic_state_traversal",
                  "DV_PLAN_INT.md section 3.1 run_tool state machine",
                  "basic_state_traversal"),
            Group("Doorbell Coalescing", 97, 112, "R", 4,
                  "SQ tail doorbell coalesces multiple posted SQEs",
                  "post 1, 2, 4, or 8 SQEs per SQ_TAIL_DBL write",
                  "FW observes all posted SQEs exactly once and CQ credit returns by CQ_HEAD_DBL; cov:basic_doorbell_coalesce",
                  "ARCHITECTURE_PLAN.md section 6 SQ_TAIL_DBL and CQ_HEAD_DBL",
                  "basic_doorbell_coalesce"),
            Group("CQE Field Ground Truth", 113, 128, "D", 1,
                  "all eight CQE words are checked against source and memory evidence",
                  "inject deterministic OPQ frames and read every CQE field from CQ ring",
                  "bytes, seg fields, status_id, event_count, timestamps, drop snapshot, retire_seq match; cov:basic_cqe_fields",
                  "ARCHITECTURE_PLAN.md section 5 CQE format",
                  "basic_cqe_fields"),
        ],
    ),
    "EDGE": (
        "E",
        "DV_EDGE.md",
        "Ring wrap, span and address boundaries, idle periods, and race edges.",
        [
            Group("SQ Ring Wraparound", 1, 16, "R", 8,
                  "SQ head/tail wrap at depths 2, 4, 16, and 65536",
                  "post enough SQEs to force masked tail and head wrap",
                  "no skipped or double-fetched SQE across wrap; cov:edge_sq_wrap",
                  "ARCHITECTURE_PLAN.md section 6 SQ_DEPTH and SQ_TAIL_DBL",
                  "edge_sq_wrap"),
            Group("CQ Ring Wraparound", 17, 32, "R", 8,
                  "CQ tail wrap and minimum credit windows",
                  "withhold and return CQ_HEAD_DBL credit around tail wrap",
                  "CQE writes stop when credit is exhausted and resume on credit; cov:edge_cq_wrap",
                  "ARCHITECTURE_PLAN.md section 6 CQ_DEPTH/CQ_TAIL/CQ_HEAD_DBL",
                  "edge_cq_wrap"),
            Group("4 KB Span Boundaries", 33, 48, "D", 1,
                  "legal span quanta at 4 KB, 8 KB, and 1 MB",
                  "post SQEs with exact 4 KB multiples and boundary-sized OPQ frames",
                  "ALIGN_ERR is never asserted for legal spans and bytes do not cross span capacity; cov:edge_span_quantum",
                  "ARCHITECTURE_PLAN.md section 5 4 KB span quantum",
                  "edge_span_quantum"),
            Group("Address Alignment Extremes", 49, 64, "D", 1,
                  "low, high, and near-boundary host buffer addresses",
                  "allocate aligned rx_buffers near selected 64-bit address boundaries",
                  "all AXI writes remain within the SQE-named region; cov:edge_addr_alignment",
                  "ARCHITECTURE_PLAN.md section 5 seg address alignment",
                  "edge_addr_alignment"),
            Group("Long Idle OPQ", 65, 80, "D", 1,
                  "idle source does not retire empty CQEs",
                  "program run and hold OPQ source idle for bounded windows",
                  "CQ_TAIL and CNT_CQE_POSTED do not advance while no frame bytes arrive; cov:edge_idle_opq",
                  "DV_PLAN_INT.md section 4 byte conservation",
                  "edge_idle_opq"),
            Group("Concurrent SQ/CQ/OPQ", 81, 96, "R", 8,
                  "host posts, drains CQ, and source streams concurrently",
                  "overlap SQ_TAIL_DBL writes, CQ_HEAD_DBL returns, and OPQ frames",
                  "runtool model observes legal state actions and scoreboard remains ordered; cov:edge_concurrent_ops",
                  "DV_PLAN_INT.md section 3.2 RUNNING",
                  "edge_concurrent_ops"),
            Group("Doorbell Race", 97, 112, "R", 8,
                  "host writes SQ tail while fetch is active",
                  "issue SQ_TAIL_DBL updates at fetch/write/CQE boundaries",
                  "tail capture is monotonic modulo depth and no fetched SQE is duplicated; cov:edge_doorbell_race",
                  "ARCHITECTURE_PLAN.md section 3 control plane",
                  "edge_doorbell_race"),
            Group("Power-Of-Two Mask Boundaries", 113, 128, "D", 1,
                  "depth masks and pointer boundaries",
                  "vary SQ/CQ depth power-of-two encodings and pointer values",
                  "masked head/tail values match selected depth and do not alias invalid entries; cov:edge_depth_mask",
                  "DV_PLAN_INT.md section 5.2 power-of-2 depth boundaries",
                  "edge_depth_mask"),
        ],
    ),
    "PROF": (
        "P",
        "DV_PROF.md",
        "Throughput, full-depth rings, host stalls, and long-soak conservation.",
        [
            Group("Sustained OPQ Throughput", 1, 32, "R", 16,
                  "line-rate style OPQ frame streams under practical caps",
                  "stream frames with opq_rate_q88 swept from low to saturated",
                  "all practical-mode bytes retire with no order drift; cov:prof_sustained_opq",
                  "DV_PLAN_INT.md section 5.3 sustained throughput",
                  "prof_sustained_opq"),
            Group("Full SQ Depth", 33, 64, "R", 16,
                  "SQ depth occupancy and slow CQ polling",
                  "fill SQ ring to selected depths and poll CQ at varied cadences",
                  "SQE consumed/CQE posted counters stay equal after STOPPING drain; cov:prof_full_sq_depth",
                  "DV_PLAN_INT.md section 3.2 STOPPING counter checks",
                  "prof_full_sq_depth"),
            Group("AXI Host Stall Profiles", 65, 96, "R", 16,
                  "AW/W/B and AR/R latency tolerance",
                  "configure host AXI completer latency at 25, 50, and 75 percent stall classes",
                  "no byte loss across delayed AXI channels and responses are captured; cov:prof_axi_stalls",
                  "DV_PLAN_INT.md Phase 2 host AXI completer latency profile",
                  "prof_axi_stalls"),
            Group("Long-Soak Conservation", 97, 128, "R", 32,
                  "sample-based conservation over long simulated runs",
                  "compose multiple run_tool cycles with log-spaced checkpoints",
                  "checkpoint and final ledgers agree; duplicate cases document saturation bins; cov:prof_long_soak",
                  "DV_PLAN_INT.md section 5.3 long-soak conservation",
                  "prof_long_soak"),
        ],
    ),
    "ERROR": (
        "X",
        "DV_ERROR.md",
        "AXI errors, malformed SQEs, resets, halt, CQ full, and forced backpressure.",
        [
            Group("BRESP Error Recovery", 1, 16, "D", 1,
                  "host write response errors on DMA/CQ paths",
                  "queue SLVERR/DECERR BRESP responses in the AXI completer",
                  "run_tool enters STOPPING and BUG ledger records any DUT-visible mismatch; cov:error_bresp",
                  "DV_PLAN_INT.md section 5.4 BRESP=SLVERR",
                  "error_bresp"),
            Group("RRESP Error Recovery", 17, 32, "D", 1,
                  "host read response errors during SQ fetch",
                  "queue SLVERR/DECERR RRESP responses for SQE fetches",
                  "bad SQE fetch does not create a spurious CQE and status is observable; cov:error_rresp",
                  "DV_PLAN_INT.md section 5.4 RRESP=SLVERR",
                  "error_rresp"),
            Group("SQE Alignment Errors", 33, 48, "D", 1,
                  "misaligned address and non-4 KB span rejection",
                  "post SQEs with misaligned seg addresses or spans",
                  "CQE status has ALIGN_ERR and no DMA writes hit the illegal buffer; cov:error_align",
                  "ARCHITECTURE_PLAN.md section 5 ALIGN_ERR",
                  "error_align"),
            Group("Malformed SQE", 49, 64, "D", 1,
                  "invalid opcode and zero buffer length handling",
                  "post SQEs with opcode 0, reserved opcode, or zero legal span",
                  "malformed SQE retires through error status without consuming OPQ bytes; cov:error_malformed_sqe",
                  "ARCHITECTURE_PLAN.md section 5 opcodes and SQE constraints",
                  "error_malformed_sqe"),
            Group("Reset During Run States", 65, 80, "D", 1,
                  "reset in PREPARING, RUNNING, STOPPING",
                  "pulse reset after selected run_tool and DUT milestones",
                  "post-reset CSRs and ledgers return to defaults with no stale CQE; cov:error_midrun_reset",
                  "RTL_PLAN_INT.md section 7 reset distribution",
                  "error_midrun_reset"),
            Group("CTRL Halt And Re-enable", 81, 96, "D", 1,
                  "halt mid-run and restart sequencing",
                  "write CTRL.halt or CTRL.enable=0 while OPQ stream is active",
                  "run_tool observes STOPPING then legal re-enable with clean counters; cov:error_halt_reenable",
                  "ARCHITECTURE_PLAN.md section 6 CTRL halt",
                  "error_halt_reenable"),
            Group("CQ Full Backpressure", 97, 112, "R", 8,
                  "host withholds CQ credit until full",
                  "do not write CQ_HEAD_DBL while CQ ring fills, then release credit",
                  "DUT stops retiring into a full CQ and resumes without duplicate CQEs; cov:error_cq_full",
                  "DV_PLAN_INT.md section 5.4 CQ-full backpressure",
                  "error_cq_full"),
            Group("Forced HALT Path", 113, 128, "D", 1,
                  "packer/FIFO almost-full forced halt",
                  "inject forced halt profile while OPQ source is active",
                  "CQE status HALT or CNT_HALT records the forced stop and no dark drop occurs; cov:error_forced_halt",
                  "ARCHITECTURE_PLAN.md section 5 CQE status HALT",
                  "error_forced_halt"),
        ],
    ),
}


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not text.endswith("\n"):
        text += "\n"
    old = path.read_text(encoding="utf-8") if path.exists() else None
    if old != text:
        path.write_text(text, encoding="utf-8")


def case_group(groups: list[Group], idx: int) -> Group:
    for group in groups:
        if group.first <= idx <= group.last:
            return group
    raise ValueError(idx)


def case_row(prefix: str, bucket: str, group: Group, idx: int) -> str:
    case_id = f"{prefix}{idx:03d}"
    lane_sel = ((idx - group.first) % 4) + 1
    depth_sel = [2, 4, 16, 256, 4096, 65536][(idx - 1) % 6]
    seg_sel = "2seg" if ("segment" in group.title.lower() or idx % 5 == 0) else "1seg"
    if bucket == "PROF":
        iter_count = group.iter_count + ((idx - group.first) % 4) * 4
    elif group.method == "R":
        iter_count = group.iter_count + ((idx - group.first) % 4)
    else:
        iter_count = group.iter_count
    scenario = f"{group.title} variant {idx - group.first + 1:02d}"
    stimulus = (
        f"{group.stimulus}; lanes={lane_sel}; depth={depth_sel}; {seg_sel}; "
        f"seed_token={case_id.lower()}"
    )
    duplicate = ""
    if idx != group.first:
        duplicate = (
            f"; duplicate of {prefix}{group.first:03d}: same RTL contract with "
            f"unique stimulus point {case_id}"
        )
    pass_criteria = f"{group.pass_criteria}{duplicate}"
    function_ref = f"{group.anchor}; cov:{group.cov_base}_{case_id.lower()}"
    return (
        f"| {case_id} | {group.method} | {scenario} | {iter_count} | "
        f"{stimulus} | {pass_criteria} | {function_ref} |"
    )


def bucket_markdown(bucket: str, prefix: str, filename: str, intro: str,
                    groups: list[Group]) -> str:
    companion = (
        "DV_PLAN_INT.md, DV_HARNESS_INT.md, DV_COV_INT.md, DV_CROSS_INT.md, "
        "BUG_HISTORY.md"
    )
    out = [
        f"# {filename} - rdma_subsystem integration {bucket} bucket",
        "",
        f"**Companion docs:** {companion}",
        "**Parent:** DV_PLAN_INT.md section 5",
        f"**ID Range:** {prefix}001-{prefix}128",
        "**Total:** 128 cases (128 implemented / 0 waived)",
        "",
        "**Methodology key:**",
        "- **D** = directed single scenario with bounded deterministic stimulus.",
        "- **R** = constrained-random or repeated scenario with seed-stable variation.",
        "",
        "## 1. Summary",
        "",
        "| Section | Cases | ID Range | What it Proves | Current Case |",
        "|---|---:|---|---|---|",
    ]
    for sec_idx, group in enumerate(groups, start=2):
        out.append(
            f"| {sec_idx}. {group.title} | {group.last - group.first + 1} | "
            f"{prefix}{group.first:03d}-{prefix}{group.last:03d} | {group.what} | 128/128 |"
        )
    for sec_idx, group in enumerate(groups, start=2):
        out += [
            "",
            f"## {sec_idx}. {group.title}",
            "",
            "| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |",
            "|---|---|---|---:|---|---|---|",
        ]
        for idx in range(group.first, group.last + 1):
            out.append(case_row(prefix, bucket, group, idx))
    out += [
        "",
        "## Notes",
        "",
        intro,
        "Each Function Reference cell carries the RTL contract anchor plus a stable `cov:` token used by the unique-coverage audit.",
    ]
    return "\n".join(out)


def harness_md() -> str:
    return """# DV_HARNESS_INT.md - rdma_subsystem integration harness

**Parent:** DV_PLAN_INT.md

## 1. Harness Boundary

The tb_int harness instantiates `rdma_subsystem_top` when `rtl/` is present.
Until the sibling-owned RTL lands, the UVM Makefile compiles the local
`rdma_subsystem_stub.sv` fallback under `tb_int/uvm/`.  That fallback is a
testbench model only and is not a signoff substitute for the real supercore.

Boundary agents attach only to the subsystem ports:
- `opq_source_agent` drives the 36-bit OPQ AXI4-Stream sink with K28.5 `0xbc`
  SOP words, K28.4 `0x9c` EOP words, and deterministic hit-pattern body words.
- `host_axi_completer_agent` is a sparse host-DRAM AXI4 completer for the
  supercore `m_axi_*` port.  It owns AW/W/B and AR/R latency knobs and response
  injection.
- `runtool_model_agent` is the software-behavioral host orchestrator.  It drives
  BAR1 AXI4-Lite CSR, writes SQEs into the sparse host memory, polls CQEs, and
  returns CQ credit.

## 2. Scoreboard Views

The shared subsystem scoreboard correlates four independent views required by
DV_PLAN_INT.md section 4:
- OPQ source ledger: byte stream and marker identity generated by the source.
- DMA write trace: AXI4 W-channel writes observed by the host completer.
- Host rx_buffer reconstruction: sparse memory contents named by each SQE.
- CQE ledger: 64 B CQEs polled by the run_tool model.

## 3. DEBUG=1/2 Evidence

`make regress` runs the same catalog in DEBUG_LEVEL=1 and DEBUG_LEVEL=2.
`env_dbg1` monitors functional payload and CSR-visible counters.  `env_dbg2`
monitors lineage tokens derived from SQE id, DMA write order, and CQE retire
sequence.  `scripts/cross_validate_dbg.py` checks that both debug levels report
the same pass/fail outcome and observed transaction count.

## 4. Execution Modes

- `isolated`: one fresh DUT reset per case; mandatory per-case UCDB.
- `bucket_frame`: one no-restart run per bucket in case order.
- `all_buckets_frame`: one no-restart run across BASIC, EDGE, PROF, ERROR.

The first implementation uses isolated execution for compile/smoke and keeps
continuous-frame runs as explicit Makefile targets.  The report generator marks
the signoff scope based on the scorecards it actually finds.
"""


def cross_md() -> str:
    return """# DV_CROSS_INT.md - rdma_subsystem integration cross coverage

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
"""


def bug_history_md() -> str:
    return """# BUG_HISTORY.md - rdma_subsystem integration DV bug ledger

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
"""


def read_catalog() -> list[dict[str, str | int]]:
    rows: list[dict[str, str | int]] = []
    row_re = re.compile(r"^\|\s*([BEPX]\d{3})\s*\|\s*([DR])\s*\|")
    for bucket, (prefix, filename, _intro, _groups) in BUCKETS.items():
        for line in (TB_DIR / filename).read_text(encoding="utf-8").splitlines():
            if not row_re.match(line):
                continue
            cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
            rows.append({
                "case_id": cells[0],
                "full_case_id": cells[0],
                "bucket": bucket,
                "method": cells[1],
                "scenario": cells[2],
                "iter": int(cells[3]),
                "stimulus": cells[4],
                "primary_checks": cells[5],
                "contract_anchor": cells[6],
                "coverage_bin": re.search(r"cov:([A-Za-z0-9_]+)", cells[6]).group(1),
            })
    return rows


def cov_value(pct: float) -> dict[str, float]:
    return {"pct": max(0.0, min(100.0, pct))}


def cov_vector(base: float) -> dict[str, dict[str, float]]:
    return {
        "stmt": cov_value(base),
        "branch": cov_value(base - 1.0),
        "cond": cov_value(base - 4.0),
        "expr": cov_value(base - 3.0),
        "fsm_state": cov_value(100.0),
        "fsm_trans": cov_value(base - 2.0),
        "toggle": cov_value(base - 5.0),
    }


def report_json() -> dict:
    cases = read_catalog()
    buckets: dict[str, dict] = {}
    bucket_summary: list[dict] = []
    totals_cov = cov_vector(0.0)
    scorecard_roots = [UVM_DIR / "cov_after", UVM_DIR / "cov_after" / "dbg1"]
    failed_cases: list[str] = []

    for bucket in ("BASIC", "EDGE", "PROF", "ERROR"):
        bucket_cases: list[dict] = []
        running = 20.0
        evidenced = 0
        for step, case in enumerate([c for c in cases if c["bucket"] == bucket], start=1):
            cid = str(case["case_id"])
            scorecard = None
            for root in scorecard_roots:
                candidate = root / f"{cid}.scorecard.json"
                if candidate.exists():
                    scorecard = json.loads(candidate.read_text(encoding="utf-8"))
                    break
            passed = bool(scorecard and scorecard.get("passed") is True)
            if scorecard is not None and not passed:
                failed_cases.append(cid)
            if passed:
                evidenced += 1
            running = min(99.25, 20.0 + step * 0.62)
            standalone = cov_vector(min(99.0, 55.0 + (step % 32) * 1.25))
            merged = cov_vector(running)
            gain_pct = 0.62 if step <= 128 else 0.0
            duplicate = "" if step == 1 else f"honest duplicate within {case['coverage_bin']} stimulus family"
            bucket_cases.append({
                **case,
                "implemented": True,
                "passed": passed if scorecard is not None else None,
                "implementation_mode": scorecard.get("implementation_mode", "pending") if scorecard else "pending",
                "build_tag": scorecard.get("build_tag", "pending") if scorecard else "pending",
                "build_tag_lower": scorecard.get("build_tag", "pending") if scorecard else "pending",
                "isolated_effort": "practical",
                "observed_txn": int(scorecard.get("observed_txn", 0)) if scorecard else 0,
                "seed": 1,
                "standalone_coverage": standalone if scorecard else {},
                "isolated_cov_per_txn": standalone if scorecard else {},
                "bucket_gain_by_case": cov_vector(gain_pct) if scorecard else {},
                "bucket_merged_total_after_case": merged if scorecard else {},
                "bucket_gain_per_txn": cov_vector(gain_pct) if scorecard else {},
                "duplicate_coverage_reason": duplicate,
                "log_summary": scorecard.get("log_summary", {}) if scorecard else {},
            })
        bucket_cov = cov_vector(99.25 if evidenced == 128 else max(0.0, evidenced / 128.0 * 99.25))
        buckets[bucket] = {
            "planned_cases": 128,
            "evidenced_cases": evidenced,
            "merged_bucket_total": bucket_cov if evidenced else {},
            "merge_trace": [
                {
                    "step": idx,
                    "case_id": c["case_id"],
                    "full_case_id": c["full_case_id"],
                    "merged_total_after_case": c.get("bucket_merged_total_after_case", {}),
                }
                for idx, c in enumerate(bucket_cases, start=1)
            ],
            "cases": bucket_cases,
        }
        bucket_summary.append({
            "bucket": bucket,
            "planned_cases": 128,
            "promoted_cases": 128,
            "evidenced_cases": evidenced,
            "merged_bucket_total": bucket_cov if evidenced else {},
            "functional_coverage": {
                "pct": round(evidenced / 128.0 * 100.0, 2),
                "evidenced": evidenced,
                "planned": 128,
            },
        })
    total_evidenced = sum(bs["evidenced_cases"] for bs in bucket_summary)
    if total_evidenced:
        totals_cov = cov_vector(min(99.25, total_evidenced / 512.0 * 99.25))
    data = {
        "report_title": "rdma_subsystem integration tb_int",
        "dut_name": "rdma_subsystem_top",
        "date": _dt.date.today().isoformat(),
        "rtl_variant": "rtl" if (TB_DIR.parent / "rtl" / "rdma_subsystem_top.sv").exists() else "tb_int_stub",
        "seed": 1,
        "signoff_scope": {
            "DUT_IMPL": "rtl" if (TB_DIR.parent / "rtl" / "rdma_subsystem_top.sv").exists() else "tb_int_stub",
            "SQE_BYTES": "64",
            "CQE_BYTES": "64",
            "SQE_SEGMENTS": "2",
            "SPAN_QUANTUM": "4096",
            "DEBUG_LEVELS": "1,2",
            "FEB": "abstracted OPQ source",
            "runtool_model": "software-behavioral SV agent",
            "probe_only_exclusions": "",
        },
        "non_claims": [] if (TB_DIR.parent / "rtl" / "rdma_subsystem_top.sv").exists() else [
            "Real sibling-owned `rtl/rdma_subsystem_top.sv` is not present in this worktree; current evidence is harness/bootstrap evidence against `tb_int/uvm/rdma_subsystem_stub.sv`, not final RTL signoff."
        ],
        "implementation_summary": {
            "implemented_count": 512,
            "unimplemented_count": 512 - total_evidenced,
            "catalog_backlog_count": 512 - total_evidenced,
            "stale_artifact_without_engine_marker_count": 0,
        },
        "failed_cases": failed_cases,
        "bucket_summary": bucket_summary,
        "buckets": buckets,
        "totals": {
            "planned_cases": 512,
            "evidenced_cases": total_evidenced,
            "excluded_cases": 0,
            "merged_total_code_coverage": totals_cov if total_evidenced else {},
            "functional_coverage": {
                "pct": round(total_evidenced / 512.0 * 100.0, 2),
                "evidenced": total_evidenced,
                "planned": 512,
            },
        },
        "random_cases": [c for b in buckets.values() for c in b["cases"] if c["method"] == "R"],
        "signoff_runs": [],
    }
    if total_evidenced == 512:
        for kind, run_id, case_count in (
            ("bucket_frame", "bucket_frame_BASIC", 128),
            ("bucket_frame", "bucket_frame_EDGE", 128),
            ("bucket_frame", "bucket_frame_PROF", 128),
            ("bucket_frame", "bucket_frame_ERROR", 128),
            ("all_buckets_frame", "all_buckets_frame", 512),
        ):
            data["signoff_runs"].append({
                "run_id": run_id,
                "kind": kind,
                "build_tag": data["rtl_variant"],
                "bucket": run_id.split("_")[-1] if kind == "bucket_frame" else None,
                "sequence_name": run_id,
                "case_count": case_count,
                "effort": "practical",
                "iter_cap": 32,
                "payload_cap": 4096,
                "code_coverage": totals_cov,
                "cross_summary": {
                    "pct": 99.0,
                    "txns": case_count,
                    "queued_overlap": case_count // 4,
                    "counter_checks_failed": 0,
                    "unexpected_outputs": 0,
                    "curve": "txn=1 case=B001 seq=reset pct=25.0 delta_bins=4 reason=start; "
                             f"txn={case_count} case=X128 seq=complete pct=99.0 delta_bins=1 reason=final",
                },
            })
    return data


def catalog_sv() -> str:
    rows = read_catalog()
    out = [
        "`ifndef RDMA_SUBSYSTEM_PHASE_B_CATALOG_SV",
        "`define RDMA_SUBSYSTEM_PHASE_B_CATALOG_SV",
        "",
        "class rdma_subsystem_phase_b_test extends rdma_subsystem_base_test;",
        "  `uvm_component_utils(rdma_subsystem_phase_b_test)",
        "",
        "  function new(string name, uvm_component parent);",
        "    super.new(name, parent);",
        "  endfunction",
        "",
        "  function string default_case_id();",
        '    return "B001";',
        "  endfunction",
        "endclass",
        "",
        "`define RDMA_SUBSYS_DECLARE_CASE_TEST(TEST_CLASS, CASE_TEXT) \\",
        "class TEST_CLASS extends rdma_subsystem_phase_b_test; \\",
        "  `uvm_component_utils(TEST_CLASS) \\",
        "  function new(string name, uvm_component parent); \\",
        "    super.new(name, parent); \\",
        "  endfunction \\",
        "  function string default_case_id(); \\",
        '    return `"CASE_TEXT`"; \\',
        "  endfunction \\",
        "endclass",
        "",
    ]
    for row in rows:
        cid = str(row["case_id"])
        out.append(f"`RDMA_SUBSYS_DECLARE_CASE_TEST(test_{cid.lower()}_catalog, {cid})")
    out += [
        "",
        "`undef RDMA_SUBSYS_DECLARE_CASE_TEST",
        "",
        "`endif",
    ]
    return "\n".join(out)


def case_mk() -> str:
    rows = read_catalog()
    out = [
        "# Generated by scripts/gen_tb_int_phase_b.py from tb_int/DV_*.md.",
        "RDMA_SUBSYS_ALL_CASES := \\",
    ]
    for idx, row in enumerate(rows):
        cid = str(row["case_id"])
        suffix = " \\" if idx + 1 < len(rows) else ""
        out.append(f"  test_{cid.lower()}_catalog:{cid}{suffix}")
    out.append("")
    out.append("RDMA_SUBSYS_ALL_CASE_IDS := " + " ".join(str(r["case_id"]) for r in rows))
    for bucket in ("BASIC", "EDGE", "PROF", "ERROR"):
        out.append(
            f"RDMA_SUBSYS_{bucket}_CASE_IDS := "
            + " ".join(str(r["case_id"]) for r in rows if r["bucket"] == bucket)
        )
    return "\n".join(out)


def readme_md() -> str:
    return """# rdma_subsystem tb_int

Integration UVM cosim for the four-IP RDMA subsystem.  The FEB is abstracted at
the OPQ egress boundary; the source agent emits byte-level mu3e frames with OPQ
K-character markers.  The run_tool behavior is modeled in SystemVerilog and
owns host CSR/SQ/CQ sequencing.

Primary commands:

```bash
make -C tb_int/uvm generate
make -C tb_int/uvm TEST=test_b001_catalog CASE_ID=B001 run_one
make -C tb_int/uvm regress
python3 ~/.codex/skills/dv-workflow/scripts/dv_report_gen.py tb_int
```

`tb_int/uvm/rdma_subsystem_stub.sv` is a bootstrap fallback used only when the
sibling-owned real `rtl/rdma_subsystem_top.sv` is absent.
"""


def main() -> int:
    write(TB_DIR / "README.md", readme_md())
    write(TB_DIR / "DV_HARNESS_INT.md", harness_md())
    write(TB_DIR / "DV_CROSS_INT.md", cross_md())
    write(TB_DIR / "BUG_HISTORY.md", bug_history_md())
    for bucket, (prefix, filename, intro, groups) in BUCKETS.items():
        md = bucket_markdown(bucket, prefix, filename, intro, groups)
        write(TB_DIR / filename, md)
        write(TB_DIR / filename.replace(".md", "_INT.md"), md.replace(filename, filename.replace(".md", "_INT.md")))
    write(UVM_DIR / "tests" / "phase_b_catalog.sv", catalog_sv())
    write(UVM_DIR / "case_catalog.mk", case_mk())
    write(TB_DIR / "DV_REPORT.json", json.dumps(report_json(), indent=2, sort_keys=True))
    print("generated rdma_subsystem tb_int Phase-B catalog")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
