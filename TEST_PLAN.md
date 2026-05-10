# `rdma_subsystem` Onboard FEB + SWB Test Plan

Status: **CHECKPOINT LIST — pending review.**

Hardware target: SWB (Arria 10 DE5 card, `1172:0004`) loaded with the
new `rdma_subsystem` datapath + FEB SciFi at SWB link 2 on teferi.

This is NOT a static spec. It is a **checkpoint list** that drives an
iterative fix-and-debug loop. Each checkpoint (CP) is a gate — when it
PASSes the evidence pipeline advances to the next CP; when it FAILs
the agent runs the documented STP capture and the tb_int cosim recipe
against the same stimulus until the failure is reproduced and root-
caused, then commits the fix (RTL / firmware / host driver / test
plan), reruns the CP, and only advances after PASS.

## 0. Operating loop (the whole point of this document)

```
+----------------------------------------------+
|  pick next pending CP from CHECKLIST.md      |
|  (PASS rows are frozen; do not re-run)       |
+---------------------+------------------------+
                      |
                      v
+----------------------------------------------+
|  run scripts/run_cp.sh <cp_id>               |
|  - drives FEB emulator + SWB run_tool        |
|  - captures CSRs, DMA, on-board STP if armed |
|  - writes evidence/<cp_id>/{E1..E4}.json     |
+---------------------+------------------------+
                      |
                      v
+----------------------------------------------+
|  scripts/update_checklist.py                 |
|  - reads evidence, writes CHECKLIST.md row   |
+---------------------+------------------------+
                      |
              PASS    |    FAIL
              ---------------
              |               |
              v               v
   advance to next CP     +----------------------------------+
                          | DEBUG LOOP                       |
                          | 1. inspect E*.json failure mode  |
                          | 2. arm STP per CP's stp_recipe   |
                          | 3. rerun on-board, capture .stp  |
                          | 4. re-run tb_int with captured   |
                          |    stimulus per cosim_recipe     |
                          | 5. root-cause; commit fix as     |
                          |    [FIX]; bump VERSION if RTL    |
                          | 6. recompile if needed; reflash  |
                          | 7. mudaq_recover_pcie            |
                          | 8. rerun CP                      |
                          +----------------------------------+
```

## 1. Acceptance gate

[`test_plan/CHECKLIST.md`](test_plan/CHECKLIST.md) is the dashboard.
It is **machine-generated only** by `test_plan/scripts/update_checklist.py`
from artifacts under `test_plan/evidence/`. Agents and humans MUST NOT
edit it by hand — a pre-commit hook + CI verifier reject any commit
where the file differs bit-for-bit from a fresh `update_checklist.py`
output against the committed evidence tree. See §6.

Onboard signoff: every CP row is PASS, every dimension row is PASS,
and `ci_verify_checklist.sh` exits 0.

## 2. Test matrix dimensions

These are the dimensions exercised inside CP4-CP7. Each CP states
which slice of the matrix it covers.

### 2.1 Emulator mode (2 modes)

- **Mode A — uniform per-channel rate (rate-emulator)**: the FEB
  rate-emulator drives each unmasked channel at a fixed Poisson-rate
  target. Used to validate steady-state throughput, conservation, and
  per-channel rate accuracy at egress-rbcam.
- **Mode B — skewed rate (single-channel-hot)**: one channel runs at
  the target rate, all other unmasked channels run at the rate / N
  where N = unmasked-channel-count. Used to validate the rbcam
  fairness and queue isolation under non-uniform load.

> If the actual on-FEB emulator distinguishes a different pair of
> modes (e.g. charge-injection-pulser vs MuTRiG-style hit-pattern
> generator), the downstream evidence scripts only key on `mode = A | B`,
> so the semantic mapping can be rebound at deploy time.

### 2.2 Masking pattern (per-channel mask)

- M0: all 256 channels unmasked (control)
- M1: half the channels masked (low half)
- M2: half the channels masked (high half)
- M3: every other channel masked (alternating)
- M4: single channel unmasked (lowest-numbered)
- M5: single channel masked (lowest-numbered, rest unmasked)
- M6: 75% masked (random subset, seed = 1)
- M7: 25% masked (random subset, seed = 1)

### 2.3 Per-unmasked-channel rate

- R1: 10 kHz / channel
- R2: 100 kHz / channel
- R3: 500 kHz / channel
- R4: 1 MHz / channel

Each held for **30 s** per test point.

## 3. Evidence categories (every CP that runs traffic produces all four)

### 3.1 E1 — Counter lossless conservation

Snapshot before and after the run window:

- FEB-side: per-channel emulator-generated hit counter
- SWB BAR1: `CNT_OPQ_INPUT_W`, `CNT_SQE_CONSUMED`, `CNT_CQE_POSTED`,
  `CNT_BYTES_WRITTEN`, `CNT_EOE_OBSERVED`, `CNT_HALT`, plus the
  legacy `EVENT_SKIP_EVENT_DMA_R` (must read zero).

PASS criterion: `CNT_OPQ_INPUT_W * 4 == CNT_BYTES_WRITTEN +
header_overhead`, `CNT_HALT == 0`, FEB ingress count agrees with
SWB-decoded egress count to within Poisson 5-sigma.

### 3.2 E2 — Per-channel rate histogram (ingress vs egress-rbcam)

256-bin histograms, one per channel. PASS: `bin[ch]_egress ==
bin[ch]_ingress +/- 5 sigma_Poisson` for every unmasked channel;
`bin[ch]_egress == 0` exactly for every masked channel. Subject to
math expert review (§5).

### 3.3 E3 — Latency plot

Per-hit (host_rx_ts - FEB_gen_ts). Reported metrics: median, p99,
p99.9, max. PASS: p99.9 < predicted upper bound from MATH_REVIEW.md.

### 3.4 E4 — Offline DMA data with offline analysis

Dump rx_buffer contents to `evidence/<cp_id>/dma.bin`, decode into
per-channel hit counts + per-hit records + frame-boundary check.

## 4. Checkpoint list

Format: each CP has Goal, Slice, Expected, Pass, STP recipe, Cosim
recipe. STP recipes reference the `signaltap-creation-co-debug` skill.
Cosim recipes reference tb_int case IDs.

### CP0 — Pre-test environment alive

- **Goal**: SWB + FEB + host all in known-good state.
- **Slice**: no traffic.
- **Action**: program SWB SOF; `sudo -n mudaq_recover_pcie`; confirm
  `/dev/mudaq0`; sc_tool reads `CSR_UID = 0x44514F50` ("DQOP") on the
  rdma_subsystem CSR aperture; FEB SciFi reports
  `LINK_LOCKED_HIGH_REGISTER_R` bit 2 set (link 2).
- **Pass**: all three reads succeed; UID matches; link2 bit asserted.
- **STP recipe**: capture on AVMM CSR bus + PCIe BAR1 read-data lanes
  if UID is wrong; capture on link2 status lanes if not locked.
- **Cosim recipe**: N/A — pre-traffic environment check.

### CP1 — Datapath idle (no traffic)

- **Goal**: confirm zero leakage in idle.
- **Slice**: all channels masked; FEB emulator OFF.
- **Action**: hold for 30 s; snapshot CSRs at t=0 and t=30.
- **Pass**: CNT_OPQ_INPUT_W, CNT_SQE_CONSUMED, CNT_CQE_POSTED,
  CNT_BYTES_WRITTEN all stay 0; run_state stays IDLE;
  EVENT_SKIP_EVENT_DMA_R == 0.
- **STP recipe**: probe `rdma_subsystem_top` ports `s_axis_opq_*`,
  `m_axi_*`, `s_axil_*`, plus internal `run_state` / `csr_*` busses,
  trigger on any non-zero word.
- **Cosim recipe**: tb_int B001 (reset/idle smoke) with stub-DUT
  swapped to real RTL. The cosim must produce identical zero-CSR
  snapshots.

### CP2 — Single-channel lowest rate (Mode A, M4, R1)

- **Goal**: minimum-traffic round-trip.
- **Slice**: A x M4 (single channel unmasked) x R1 (10 kHz).
- **Action**: 30 s run; expect 300 k hits.
- **Pass**: E1 conservation holds; E2 has bin[ch_active]=300k +/-5sigma,
  all others exactly 0; E3 median < 100 us; E4 decodes 300k hits all
  in channel ch_active.
- **STP recipe**: probe FEB-side rate-emulator output port (the hit
  channel ID + valid signals); SWB-side `s_axis_opq_*`,
  `rdma_dma_packer` 32-bit-to-256-bit accumulator, `rdma_dma_writer`
  `beats_remaining`. Trigger on first non-zero hit, capture 64k cycles.
- **Cosim recipe**: tb_int B002 (single-job hit-only EOE) with
  stimulus seed pinned to 300k hits on ch_active. Compare scoreboard
  ledger against on-board E4 decode word-for-word.

### CP3 — All channels at R1

- **Goal**: full-channel low-rate coverage.
- **Slice**: A x M0 (all unmasked) x R1 (10 kHz).
- **Action**: 30 s run; expect 256 x 300 k = 76.8 M hits.
- **Pass**: E1 conservation; E2 every bin[ch] ~= 300k +/-5sigma.
- **STP recipe**: probe rbcam ingress per-channel valid + the
  multiplexer fairness arbiter; trigger on any channel starving for
  > 1 ms.
- **Cosim recipe**: tb_int P bucket case with N=256 channels at 10 kHz.

### CP4 — Mask sweep at R1

- **Goal**: prove masking applies cleanly.
- **Slice**: A x {M0..M7} x R1; 8 test points.
- **Action**: per-mask 30 s runs.
- **Pass**: for every Mn, E2 bin[ch]=300k if ch unmasked else exactly 0.
- **STP recipe**: on FAIL for Mn, capture FEB-side mask register +
  per-channel emulator-output to prove mask was actually applied at
  FEB; SWB-side rbcam ingress to prove no leak.
- **Cosim recipe**: tb_int BASIC bucket mask cases (B-series cases
  pinned to mask register writes).

### CP5 — Mode B at R1, all masks

- **Goal**: skewed traffic does not break rbcam fairness.
- **Slice**: B x {M0..M7} x R1.
- **Action**: 8 x 30 s runs.
- **Pass**: E2 matches the skewed expectation per §5 math model.
- **STP recipe**: rbcam per-channel FIFO fill-level taps (DEBUG=1
  ports); trigger on any FIFO exceeding 80% depth.
- **Cosim recipe**: tb_int PROF bucket P-series skewed cases.

### CP6 — Rate ramp at M0

- **Goal**: max-throughput envelope.
- **Slice**: A x M0 x {R1..R4}.
- **Action**: 4 x 30 s runs; R4 = 1 MHz x 256 = 256 MHit/s ~= 1 GB/s
  DMA.
- **Pass**: E1 conservation at every rate; E3 p99.9 below MATH_REVIEW
  bound; no E1 CNT_HALT increments.
- **STP recipe**: at R4 specifically, probe `rdma_dma_writer`
  `beats_remaining`, AXI4 AW/W/B outstanding-credit counter, host
  completer backpressure; trigger on B-channel slvErr or any halt
  pulse.
- **Cosim recipe**: tb_int PROF P065-P096 (max-throughput cases).

### CP7 — Full matrix

- **Goal**: every combination green.
- **Slice**: {A,B} x {M0..M7} x {R1..R4} = 64 test points.
- **Action**: scripted matrix run.
- **Pass**: 64 rows PASS in CHECKLIST.md.
- **STP recipe**: only re-arm per CP2-CP6 recipes for the specific
  failing slice.
- **Cosim recipe**: select tb_int case whose stimulus most closely
  matches the failing slice.

### CP8 — Math review closed

- **Goal**: latency upper bound, conservation invariant, and Poisson
  bound are all formally derived (not placeholders).
- **Action**: dispatch codex2 5.5 xhigh math expert sub-subagent
  with the brief `test_plan/MATH_REVIEW_BRIEF.md`.
- **Pass**: `test_plan/MATH_REVIEW.md` committed with the math
  expert's derivation block + name + approval block. Per-CP pass
  criteria that previously used placeholders are updated to cite the
  MATH_REVIEW bounds.

### CP9 — Final signoff

- **Action**: run `scripts/ci_verify_checklist.sh`.
- **Pass**: all rows PASS; exit 0; CHECKLIST.md sha matches trailer.
- This commit closes the rdma_subsystem onboard test plan and unblocks
  the FEB SciFi production bring-up.

## 5. Math expert review (codex2 5.5 xhigh)

A separate codex2 sub-subagent acting as math expert produces
`test_plan/MATH_REVIEW.md`. Required outputs:

- **Rate model**: expected per-channel rate under Mode A and Mode B,
  the Poisson 5-sigma bound used in §3.1, §3.2, and the CP pass
  criteria.
- **Conservation invariant**: exact form of
  `CNT_OPQ_INPUT_W * 4 == CNT_BYTES_WRITTEN + header_overhead`, with
  `header_overhead` enumerated per mu3e frame.
- **Latency upper bound**: closed-form or empirical bound on
  99.9th-percentile end-to-end latency given (rbcam depth, DMA SQE
  prefetch depth, AXI4 outstanding write credit, host completer
  service rate).

Until MATH_REVIEW.md is committed and approved, CP3/CP5/CP6 latency
PASS uses placeholder qualitative thresholds (median < 1 ms) which
are NOT the real gate.

## 6. Machine-only checklist contract

### 6.1 Banner and trailer

`test_plan/CHECKLIST.md` begins with:

```
<!--
DO NOT EDIT BY HAND. This file is generated by
test_plan/scripts/update_checklist.py from artifacts under
test_plan/evidence/. Any hand-edit is overwritten and rejected by CI.
-->
```

and ends with:

```
<!-- evidence_sha256: <hex>; checklist_sha256: <hex>; generated_at: <ISO8601> -->
```

### 6.2 CI verifier (the gate)

`test_plan/scripts/ci_verify_checklist.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
tmp="$(mktemp)"
python3 test_plan/scripts/update_checklist.py \
    --out "$tmp" --evidence test_plan/evidence
diff -u test_plan/CHECKLIST.md "$tmp" >&2
```

Returns nonzero on any mismatch. Wire into pre-push and the bring-up
gate.

### 6.3 Pre-commit guard

`test_plan/.githooks/pre-commit` rejects any commit modifying
`CHECKLIST.md` unless the working tree also includes a fresh
`update_checklist.py` invocation whose output bit-matches the staged
file. Agents cannot legitimately edit CHECKLIST.md.

## 7. Repo layout

```
rdma_subsystem/
|-- TEST_PLAN.md                         (this file)
`-- test_plan/
    |-- CHECKLIST.md                     (machine-only)
    |-- MATH_REVIEW.md                   (CP8 deliverable)
    |-- MATH_REVIEW_BRIEF.md             (CP8 dispatch brief)
    |-- scripts/
    |   |-- run_cp.sh                    (single CP runner)
    |   |-- run_matrix.sh                (CP7 wrapper)
    |   |-- collect_evidence.py
    |   |-- check_counter_lossless.py    (E1)
    |   |-- build_rate_histogram.py      (E2)
    |   |-- build_latency_histogram.py   (E3)
    |   |-- decode_offline_dma.py        (E4)
    |   |-- update_checklist.py          (the GATE)
    |   |-- ci_verify_checklist.sh
    |   `-- stp_arm.tcl                  (per-CP STP recipes)
    |-- evidence/
    |   |-- CP0/
    |   |   |-- meta.json
    |   |   |-- run.log
    |   |   |-- E1.json
    |   |   `-- ...
    |   |-- CP1/...
    |   `-- ...
    |-- stp_captures/                    (.stp from on-board STP)
    `-- .githooks/pre-commit             (CHECKLIST guard)
```

## 8. Execution order (initial spin-up)

1. **T1 (this commit)**: TEST_PLAN.md + scripts/ stubs + CHECKLIST.md
   banner-only template + pre-commit hook + ci_verify_checklist.sh.
2. **T2**: dispatch CP8 math expert codex2 to draft MATH_REVIEW.md.
3. **T3**: compile new SWB SOF with rdma_subsystem (task #38);
   execute CP0 + CP1 as smoke.
4. **T4**: advance through CP2..CP7 one at a time; debug loop per §0
   when a CP fails. Update CHECKLIST.md every CP via the script only.
5. **T5**: CP9 signoff when ci_verify_checklist.sh exits 0.

## 9. Risks

- **Mode semantics**: §2.1 modes A/B are uniform/skewed in this draft.
  If the actual emulator distinguishes a different pair (e.g.
  charge-injection-pulser vs hit-pattern generator), only the
  evidence-script's `mode` enum needs to track the deployed semantic.
- **Counter aliasing at R4**: at 1 MHz x 256 ch x 30 s = 7.68 G hits,
  a 32-bit CNT_OPQ_INPUT_W wraps. The collect script must take two
  snapshots inside the window or use the 64-bit variant; enforced by
  `check_counter_lossless.py`.
- **Host DMA pressure at R4**: 256 MHit/s x 4 B ~= 1 GB/s. Well within
  Gen3 x8 capacity, but assumes host completer keeps up. R4 may need
  hugepage-backed rx_buffers; `run_cp.sh` flags it.
- **STP capture depth**: 64 k cycles at 156.25 MHz ~= 400 us window.
  For rare-event triggers (e.g. CNT_HALT pulse) use STP segment-trigger
  mode per `signaltap-creation-co-debug` skill.

## 10. Acceptance

This plan is accepted when:

- All evidence scripts produce real artifacts under `test_plan/evidence/`.
- `MATH_REVIEW.md` is committed with math expert's name and approval.
- `CHECKLIST.md` shows PASS in every row.
- `ci_verify_checklist.sh` exits 0 against the committed evidence tree.
- All CPs are crossed in order without re-opening a previously closed CP.
