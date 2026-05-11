# `rdma_subsystem` Onboard FEB + SWB Test Plan

Status: **REAL TRAFFIC BLOCKED at CP-C1 on silicon.** The previous
631/631 S0..S9 PASS state was zero-traffic evidence and is no longer a
valid closure criterion. Strict evidence builders now require the
programmed FEB-side first-stage delta to be nonzero and rate-consistent;
`S1_A_M4_R1` currently fails at C1/L1/O4 because the FEB emulator never
accepts RUNNING (`feb_rate_emulator_delta=0`). The SWB `rc_tool` path
only proves the reset-link transmitter echoed the command locally; the
FEB-local `dbg_mm2runctrl_0` path is stuck pending with `sent_after=0`.
See `test_plan/CHECKLIST.md`, `PHASE_STATUS.md`, and
`test_plan/evidence/S1_A_M4_R1/ITERATIVE_DEBUG.md`.

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

These are the dimensions exercised inside cohorts S3-S7 (§4.9). Each
cohort states which slice of the matrix it covers; every test point in
a cohort runs all 5 staged chains (§4.2-§4.6) in order.

### 2.1 Emulator mode (3 modes)

Driven by the FEB-side hit emulator. The three modes exercise the
three statistical regimes the SWB datapath must handle, from purely
deterministic to fully random.

- **Mode A — periodic injection**: each unmasked channel emits one hit
  every `1/rate` seconds, deterministic. Inter-arrival distribution
  is a delta; no Poisson variance. Used to validate exact counter
  conservation (E1) and exact per-channel rate accuracy (E2) without
  statistical bound slack.
- **Mode B — header-sync injection**: each unmasked channel emits
  hits aligned to the header / frame-sync boundary (deterministic,
  but with a different temporal pattern from Mode A — bursts at sync
  edges rather than uniformly spaced). Used to validate rbcam
  behavior when many channels fire in lockstep at sync time, and to
  validate the EOE pipeline can absorb the sync-aligned bursts
  without halt.
- **Mode C — IID per channel (emulator only)**: each unmasked channel
  draws inter-arrival from an exponential distribution with mean
  `1/rate`. Hits are independent across channels. This is the
  Poisson rate model and is **emulator-only** — the real MuTRiG does
  not produce IID hits natively. Used to validate the rbcam under
  realistic random load and to validate the math-expert Poisson
  5-sigma bound (§5).

> Real-MuTRiG drive: as a bonus pass, Modes A and B can be driven
> from a real MuTRiG instead of the emulator (cohort S10, §4.9).
> Real-MuTRiG cannot drive Mode C — it produces correlated hits, not
> IID. The main test for tonight skips the real-MuTRiG bonus and
> uses the emulator for all three modes.

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

### 2.4 Matrix size

3 modes x 8 mask patterns x 4 rates = **96 test points** for the main
emulator-driven pass. Each test point produces 4 evidence artifacts
(counter ledger, ingress hist, egress hist, DMA dump) = 384 evidence
files total. The optional real-MuTRiG bonus (cohort S10) adds Modes A and B
x 8 masks x 4 rates = 64 more points if executed; Mode C is not
applicable to real MuTRiG.

## 3. Evidence categories (every CP that runs traffic produces all four)

### 3.1 E1 - Counter lossless conservation across the full chain

Snapshot before and after the 30 s run window at **every datapath
stage with CSR-visible counters**, not just FEB ingress and SWB BAR1.
The chain (in flow order):

**FEB-side datapath IPs** (read via sc_tool through swb_ring_lock, per
the FEB SciFi sc_hub slave map):

- `rate_emulator` (or charge_injection_pulser if relevant per mode) -
  per-channel programmed-rate counter and emitted-hit counter
- `frame_assembler` / `header_generator` - frames produced, headers
  emitted, EOE markers emitted
- `rbcam` ingress and egress counters (these feed the hist IP's
  pre/post histograms, see §3.3)
- `hist` IP - histogram bin totals (used both as a counter for
  conservation and as the source for the dislin pre/post-rbCAM panels)
- FEB transceiver TX framer - frames sent on link 2

**SWB-side via BAR1** (already enumerated):

- `CNT_OPQ_INPUT_W`, `CNT_RQE_CONSUMED`, `CNT_CQE_POSTED`,
  `CNT_BYTES_WRITTEN`, `CNT_EOE_OBSERVED`, `CNT_HALT`
- legacy `EVENT_SKIP_EVENT_DMA_R` (must read zero with the new
  rdma_subsystem datapath - any non-zero is a bug from the old code
  path leaking through)

PASS criterion (multi-stage conservation): for every adjacent stage
pair (i, i+1), `count_in(i+1) == count_out(i)` exactly for Modes A
and B (deterministic) or within Poisson 5-sigma for Mode C; the
chain end-to-end equality is the existing `CNT_OPQ_INPUT_W * 4 ==
CNT_BYTES_WRITTEN + header_overhead` plus `CNT_HALT == 0`. If any
stage-pair fails, the offending stage is named directly in the E1
evidence JSON.

### 3.2 E2 — Per-channel rate histogram (ingress vs egress-rbcam)

256-bin histograms, one per channel. PASS: `bin[ch]_egress ==
bin[ch]_ingress +/- 5 sigma_Poisson` for every unmasked channel;
`bin[ch]_egress == 0` exactly for every masked channel. Subject to
math expert review (§5).

### 3.3 E3 - 5-panel dislin lifetime histogram

E3 is a **5-checkpoint dislin lifetime histogram** in the exact
reference format committed alongside the existing
`feb_swb_corun/report_*/feb_swb_lifetime_hist.png` artifacts (the
user-supplied reference plots are the visual contract). Each test
point produces ONE PNG with five stacked panels sharing a common
x-axis `hit lifetime [8 ns cycles]`, one panel per checkpoint in flow
order:

1. **pre-rbCAM** - bound `[0, 2000]` cycles; `D_pre =
   wait_910(hit_ts) + s(q) + 18` (virtual MuTRiG model). Silicon
   source: hist IP pre-rbcam histogram CSR readout. Reference example
   (Mode B): p05=753, p50=835, p95=917 cycles.
2. **post-rbCAM** - bound `[2000, 2200]` cycles; `D_post = (GTS_post
   - ts_hit) mod 8192`, window `[2000, 2200]`. Silicon source: hist
   IP post-rbcam histogram CSR readout. Reference example (any
   mode): p05=2012, p50=2070, p95=2128 cycles.
3. **FEB egress** - bound `[2049, 6143]` cycles; `D_feb <= 2F - p +
   20 + eps_clk`. Source: sim only (tb_int scoreboard ledger).
4. **OPQ ingress** - bound `[2049, 6159]` cycles; `D_ing = D_feb +
   adapter_sync`. Source: sim only.
5. **OPQ egress** - bound `[~4300, ~100000]` cycles; `D_opq = D_ing +
   W_n` where `W_n = max(0, W_{n-1} + S_n - A_n)`. Source: sim only.

Annotation rendering follows the dislin reference: green vertical
lines at the bound edges, dashed orange at p05, solid black at p50,
dashed black at p95. Common x-axis caption: `hit lifetime [8 ns
cycles]`.

**Per-mode title line and master equation**:

- Mode A periodic: title `FEB/SWB ASIC0..7 all-channel hit lifetime
  (periodic_phase_staggered)`, alpha master equation
  `alpha_periodic(t) = 32 * (floor(t/156.2) + 1)`.
- Mode B header-sync: title `... (header_sync)`,
  `alpha_h(t) = 256 * (floor(t/910) + 1)`, `phase=100, stagger=16`.
- Mode C IID: title `... (poisson_iid)`,
  `E[alpha_iid(t)] = 256 * t / 1250 hits`.

All three modes share the common D-equation
`D_i = (T_i - GTS_hit) / 8 ns`.

**Reference dislin generator**: the existing tool at
`mu3e_ip_dev/.worktrees/mu3e_ip_cores_hit_type0_mux_20260504/firmware_builds/systems/system_20260504_emulator_type0/tb_int/feb_swb_corun/report_*/`
produced the user-supplied reference plots. The new
`test_plan/scripts/build_latency_histogram.py` REUSES that generator
(imports it or invokes it as a subprocess) - it does NOT reimplement
the dislin rendering.

**Silicon vs sim scope**:

- Silicon test point: pre-rbCAM and post-rbCAM panels (panels 1 and 2)
  produced directly from the hist IP CSR readout, saved as
  `evidence/<cp_id>/E3_silicon_lifetime_hist.png`.
- Matched-sim test point (tb_int cosim with same stimulus seed):
  produces all 5 panels, saved as
  `evidence/<cp_id>/E3_sim_lifetime_hist.png`.

**PASS criterion (per test point, per panel)**:

- The `[bound_lo, bound_hi]` window captures >= 99% of hits (i.e.
  < 1% out-of-bound on either side).
- p05, p50, p95 markers all fall within `[bound_lo, bound_hi]`.
- For each pair (pre-rbCAM, post-rbCAM): the silicon panel matches
  the matched-sim panel to within Poisson 5-sigma at each bin (this
  is the silicon vs sim cross-check).

The per-mode panel bounds shown above are the user-supplied
reference values; the math expert (cohort S8) may tighten them in
MATH_REVIEW.md based on the derived queue model.

### 3.4 E4 — Offline DMA data with offline analysis

Dump rx_buffer contents to `evidence/<cp_id>/dma.bin`, decode into
per-channel hit counts + per-hit records + frame-boundary check.

## 4. Checkpoint chain (staged per test point)

The checkpoint structure has TWO axes:

- **Stage axis (vertical)**: each test point runs through a staged
  chain of sub-stages (counter, rate, latency, offline-data,
  offline-analysis). At each sub-stage the script checks the stage's
  evidence against the previous stage's "truthful" reference; on
  first mismatch it STOPS at that stage, snapshots the stage-local
  evidence, and the debug loop iterates at that stage (STP arm + cosim
  re-run) until that stage PASSes before the script advances.
- **Matrix-slice axis (horizontal)**: §4.9 progresses through cohorts
  of (mode, mask, rate) tuples - bring-up first, then single channel,
  then all channels, then mask sweep, then mode sweep, then rate
  sweep, then full matrix. Each cohort runs the staged inner loop
  per test point.

This section §4 defines the **stage axis**. §4.9 defines the
**matrix-slice axis**.

Snapshot vs full stream: at every stage except the final offline
file, the evidence is a **snapshot** (CSR read, STP capture window,
or histogram aggregate). Only at the offline file
(`evidence/<cp_id>/dma.bin`) is the **full stream** available, and
that is where the per-RUN total count, per-channel rate, and per-hit
inter-arrival time histogram are checked end-to-end.

### 4.1 CP-BU - Bring-up (one-time, not per test point)

- **Goal**: SWB + FEB + host all in known-good state.
- **Action**: program SWB SOF; `sudo -n mudaq_recover_pcie`; confirm
  `/dev/mudaq0`; sc_tool reads `CSR_UID = 0x44514F50` ("DQOP") on the
  rdma_subsystem CSR aperture; FEB SciFi reports bit 2 set in the live
  `online_sc` SWB `LINK_LOCKED_LOW_REGISTER_R` at BAR1 word `0x36`;
  FEB emulator OFF, hold for 30 s to confirm zero leakage (all SWB CSR
  counters and the legacy `EVENT_SKIP_EVENT_DMA_R` stay 0; run_state
  stays IDLE). A `0x00000F00` lock pattern is links 8..11, not SciFi
  link 2.
- **Pass**: all reads succeed; UID matches; link2 bit asserted;
  zero-leakage idle confirmed.
- **STP recipe**: capture on AVMM CSR bus + PCIe BAR1 read-data lanes
  if UID is wrong; capture on link2 status lanes if not locked;
  capture on `s_axis_opq_*`/`m_axi_*` and trigger on any non-zero
  word for the leakage portion.
- **Cosim recipe**: tb_int B001 (reset/idle smoke) with stub-DUT
  swapped to real RTL produces identical zero-CSR snapshots.
- **Snapshot vs full stream**: snapshot only (no traffic to stream).

### 4.2 CP-C - Counter chain (per test point, 9 sub-stages, stop-on-mismatch)

Snapshot the per-IP CSR counter at every datapath stage before t=0
and after t=30s. Stage-pair equality is checked in flow order; first
mismatched pair stops the chain and identifies the offending stage.

| Sub-stage | Source           | What is read                                      |
|-----------|------------------|---------------------------------------------------|
| CP-C1     | FEB rate_emulator (or charge_injection_pulser) | emitted-hit counter per channel |
| CP-C2     | FEB frame_assembler / header_generator         | frames produced, EOE markers   |
| CP-C3     | FEB rbcam ingress | hits accepted into rbcam                         |
| CP-C4     | FEB rbcam egress  | hits dequeued from rbcam (post-mask)             |
| CP-C5     | FEB hist IP       | histogram bin total (truthful pre/post-rbcam)    |
| CP-C6     | FEB TX framer     | frames sent on link 2                            |
| CP-C7     | SWB BAR1 `CNT_OPQ_INPUT_W` | 32b OPQ-ingress word counter             |
| CP-C8     | SWB BAR1 `CNT_BYTES_WRITTEN` + `CNT_RQE_CONSUMED` | DMA-written bytes |
| CP-C9     | SWB BAR1 `CNT_CQE_POSTED`  | CQEs produced                            |

- **Pass at CP-Cn**: `count(Cn) == count(C_{n-1})` (exact for Modes A
  and B; within Poisson 5-sigma for Mode C); `CNT_HALT == 0`;
  `EVENT_SKIP_EVENT_DMA_R == 0`.
- **FAIL_AT_CP-Cn (the per-stage debug loop)**:
  1. snapshot the stage's full CSR block at t=fail
  2. arm STP on the input + output AXI4-Stream / AVST of that stage's
     IP (per the IP's RTL_PLAN.md datapath tap list)
  3. re-run the same test point with STP capturing
  4. re-run tb_int with the captured cycle as a directed sequence
  5. root-cause and FIX in the offending stage's IP (commit [FIX]
     under that IP's submodule); recompile if RTL changed; reflash if
     SWB-side
  6. rerun CP-C from Cn forward (earlier stages already PASSed)
- **Snapshot vs full stream**: snapshots only (counter CSR reads at
  t=0 and t=30s).

### 4.3 CP-R - Rate chain (per test point, 6 sub-stages, cosim-side)

The rate chain is checked **in cosim** (tb_int) at the same stages
as CP-C, plus inferred from the corresponding silicon CSR counters
divided by the run window. The cosim probes the stage's AXI4-Stream
or AVST hit-rate over a sliding window and compares to the programmed
per-channel rate.

| Sub-stage | Probe point                                         |
|-----------|-----------------------------------------------------|
| CP-R1     | FEB rate_emulator output (stream)                   |
| CP-R2     | FEB rbcam ingress (stream)                          |
| CP-R3     | FEB rbcam egress (stream, post-mask)                |
| CP-R4     | FEB TX framer (stream, post-frame-assembly)         |
| CP-R5     | SWB OPQ ingress (s_axis_opq_*, supercore boundary)  |
| CP-R6     | SWB DMA writer (m_axi_* AW/W, post-pack)            |

- **Pass at CP-Rn**: instantaneous rate (over a 1 ms sliding window)
  matches programmed rate to within 1% for Modes A/B (deterministic)
  or within Poisson 5-sigma for Mode C; rate drop or distortion at
  any single sub-stage stops the chain.
- **FAIL_AT_CP-Rn**: re-run the failing tb_int case with full VCD
  dump at the stage; if the cosim itself reproduces the silicon's
  rate distortion, the bug is in the stage's IP; if it does not
  reproduce, the bug is silicon-specific and CP-Cn's STP capture is
  the next step.
- **Snapshot vs full stream**: streaming rate-counters in cosim are
  free; in silicon, the rate is inferred from the corresponding
  CP-Cn counter delta over the 30 s window (snapshot end-to-end).

### 4.4 CP-L - Latency (silicon: 2 sub-stages from hist IP; sim: 5 sub-stages)

Silicon-side hit-lifetime histograms come from the FEB hist IP CSR
readout - two checkpoints, pre-rbCAM and post-rbCAM. Matched-sim
tb_int produces five panels (the three additional sim-only panels
extend deeper into the SWB datapath).

| Sub-stage | Source            | Bound (reference, Mode B header_sync) | Notes |
|-----------|-------------------|---------------------------------------|-------|
| CP-L1     | silicon hist IP, pre-rbCAM panel | `[0, 2000]` cycles | from hist IP CSR |
| CP-L2     | silicon hist IP, post-rbCAM panel | `[2000, 2200]` cycles | from hist IP CSR |
| CP-L3     | sim only, FEB egress panel | `[2049, 6143]` cycles | tb_int |
| CP-L4     | sim only, OPQ ingress panel | `[2049, 6159]` cycles | tb_int |
| CP-L5     | sim only, OPQ egress panel | `[~4300, ~100000]` cycles | tb_int |

- **Pass at CP-Ln**: per-panel >= 99% of hits inside the
  `[bound_lo, bound_hi]` window; p05/p50/p95 markers inside the
  window; silicon CP-L1 and CP-L2 match the matched-sim panels
  within Poisson 5-sigma at each bin.
- **FAIL_AT_CP-L1 or CP-L2**: silicon-side issue at the rbcam or
  hist IP. Arm STP on rbcam ingress / egress / hist write port.
- **FAIL_AT_CP-L3..L5**: sim-only issue. tb_int scoreboard ledger +
  the matched cosim's VCD at the failing checkpoint.
- **Snapshot vs full stream**: hist IP is a snapshot (the histogram
  is aggregated by the IP itself, not a full hit-by-hit dump).

### 4.5 CP-O - Offline data chain (per test point, 4 sub-stages)

The offline-data chain tracks the hit stream from the supercore
boundary to the host memory file. The first three are snapshots
(silicon cannot stream full traffic on these wires - STP depth
is bounded); the fourth is the full stream.

| Sub-stage | Probe point                                                   | Mode |
|-----------|---------------------------------------------------------------|------|
| CP-O1     | OPQ egress AXI4-Stream just before the DMA writer            | STP snapshot |
| CP-O2     | AXI4 m_axi write payload at the supercore output             | STP snapshot |
| CP-O3     | host rx_buffer at a few sampled offsets (read via mudaq_capture during the run) | host-side snapshot |
| CP-O4     | full host rx_buffer dump to `evidence/<cp_id>/dma.bin` after run end | FULL STREAM |

- **Pass at CP-On**: snapshot bytes match the previous-stage payload
  byte-for-byte (modulo frame format additions); frame K28.5 SOP /
  K28.4 EOP markers consistent.
- **FAIL_AT_CP-On**: arm STP at that stage with a deeper trigger
  window; compare to the matched cosim's monitor at the corresponding
  point.
- **Snapshot vs full stream**: O1/O2/O3 snapshots; O4 full stream.

### 4.6 CP-A - Offline full-stream analysis (per test point, 3 sub-stages)

Three end-to-end checks on `evidence/<cp_id>/dma.bin` (the full
stream from CP-O4):

- **CP-A1 active channels correct rate**: per-channel hit count
  divided by 30 s matches programmed rate. PASS: rate within 1% for
  Modes A and B; within Poisson 5-sigma for Mode C.
- **CP-A2 per-RUN count vs first-stage truthful counter**: total
  decoded hit count equals **CP-C1** (rate_emulator) counter delta
  exactly. This is the strictest conservation check - CP-C1 is the
  trustful reference because it is the FEB-side counter closest to
  hit generation. PASS: bit-exact equality (Modes A/B) or within
  Poisson 5-sigma (Mode C).
- **CP-A3 inter-event-time histogram**: per-hit inter-arrival times
  binned and plotted; expected shape per mode:
  - Mode A periodic: a delta at the programmed inter-arrival time
  - Mode B header-sync: a comb at header-sync intervals
  - Mode C IID: exponential distribution with parameter 1/rate
  PASS: chi-squared / Kolmogorov-Smirnov test against the expected
  shape under the mode passes at p > 0.01. Plot saved as
  `evidence/<cp_id>/E4_inter_event_hist.png` in dislin format.

- **FAIL_AT_CP-An**: if A1 or A2 fails, walk backward through CP-O
  to find the snapshot stage where the discrepancy first appears.
  If A3 fails (right rate, wrong distribution), the bug is in
  ordering or timestamping - re-arm STP at the latest passing stage
  with a wider window and look for stride-pattern anomalies.

### 4.7 Iterate-on-fail debug loop (owned by skill `iterative-debug`)

The full operating loop and timing-relaxation rules are owned by the
`iterative-debug` skill (canonical body at
`~/.codex/skills/iterative-debug/SKILL.md`; thin Claude pointer at
`~/.claude/skills/iterative-debug/SKILL.md`). Read that skill before
starting any debug iteration. Short form below for in-context
reference:

```
Pick next pending test point (cohort.cohort_member.matrix_id).
For each staged chain (C, R, L, O, A):
  Run staged sub-stages in order.
  On FAIL_AT_<sub-stage>:
    1. Save stage-local snapshot (CSR, STP, payload).
    2. Arm STP per the sub-stage's recipe (above tables).
    3. Re-run the matching tb_int cosim case with the captured seed.
    4. If cosim reproduces -> fix in the IP that owns that stage,
       commit [FIX] in that IP's submodule, recompile if needed,
       reflash, and re-run the staged chain from the failed sub-stage.
    5. If cosim does not reproduce -> the bug is silicon-specific;
       extend tb_int with a sequence that exercises the same
       silicon-side scenario before fixing.
    6. Loop until PASS_AT_<sub-stage>.
Advance to next staged chain when current chain reaches end-PASS.
Advance to next test point when all 5 staged chains end-PASS.
```

The pass/fail ledger per test point is written by
`scripts/update_checklist.py` from `evidence/<cp_id>/*.json`. Each
row in CHECKLIST.md is keyed by `(cohort, matrix_id, chain)` and the
value is `PASS` or `FAIL_AT_<sub-stage>`.

## 4.8 Cohort vs staged checkpoint matrix

Each cohort runs N test points; each test point runs through all 5
staged chains. The dashboard is then a matrix:

```
Rows    = test points across all cohorts (~1 + 1 + 8 + 8 + 8 + 4 + 96)
Columns = (CP-BU once) + per test point {CP-C, CP-R, CP-L, CP-O, CP-A}
Cells   = PASS or FAIL_AT_<sub-stage>
```

The granularity is intentional: a cohort-level FAIL can be localized
to the failing staged chain and the failing sub-stage by reading the
cell value directly, without re-deriving from logs.

## 4.9 Cohort progression (matrix-slice axis)

This is the order of execution. Each cohort completes (all members
end-PASS on every staged chain) before the next cohort starts.

### Cohort S0 - Bring-up (1 point, CP-BU only)

See §4.1.

### Cohort S1 - Single-channel lowest rate (1 point, Mode A x M4 x R1)

- **Goal**: minimum-traffic round-trip; smoke test of all 5 staged
  chains together.
- **Pass**: all 5 staged chains end-PASS at every sub-stage for this
  one test point.
- **Cosim recipe**: tb_int B002 (single-job hit-only EOE) with
  stimulus seed pinned to 300k hits on the active channel.

### Cohort S2 - All channels at R1 (1 point, Mode A x M0 x R1)

- **Goal**: full-channel low-rate coverage; 256 x 300 k = 76.8 M hits.
- **Cosim recipe**: tb_int PROF case with N=256 channels at 10 kHz.

### Cohort S3 - Mask sweep at R1 (8 points, Mode A x {M0..M7} x R1)

- **Goal**: prove masking applies cleanly at every mask pattern.
- **Cosim recipe**: tb_int BASIC bucket mask cases.

### Cohort S4 - Mode B header-sync at R1 (8 points)

- **Goal**: rbcam absorbs header-sync-aligned bursts without halt.
- **Cosim recipe**: tb_int EDGE bucket sync-aligned burst cases.

### Cohort S5 - Mode C IID at R1 (8 points)

- **Goal**: validate Poisson 5-sigma bound under random load.
- **Cosim recipe**: tb_int PROF bucket P-series IID-Poisson cases.

### Cohort S6 - Rate ramp at M0 (4 points, Mode A x M0 x {R1..R4})

- **Goal**: max-throughput envelope; R4 = 256 MHit/s = ~1 GB/s DMA.
- **Cosim recipe**: tb_int PROF P065-P096 (max-throughput cases).

### Cohort S7 - Full matrix (96 points, {A,B,C} x {M0..M7} x {R1..R4})

- **Goal**: every combination green; this is the main bulk run.

### Cohort S8 - Math review closed

- **Action**: dispatch codex2 5.5 xhigh math expert sub-subagent
  with `test_plan/MATH_REVIEW_BRIEF.md`.
- **Pass**: `test_plan/MATH_REVIEW.md` committed with the math
  expert's derivation block; per-mode panel bounds in CP-L and CP-A3
  are updated to cite MATH_REVIEW.md.

### Cohort S9 - Final signoff (main emulator-driven test)

- **Action**: run `scripts/ci_verify_checklist.sh`.
- **Pass**: all rows PASS; exit 0; CHECKLIST.md sha matches trailer.
- This closes the main emulator-driven onboard test and unblocks
  FEB SciFi production bring-up.

### Cohort S10 - Real-MuTRiG bonus pass (deferred / optional)

- **Goal**: real-MuTRiG-sourced hits, not emulator.
- **Slice**: {A,B} x {M0..M7} x {R1..R4} = 64 additional test points
  (Mode C N/A for real MuTRiG).
- **Action**: configure real MuTRiG via `configure_mutrig_from_xml.py`
  (production path per feedback memory on MuTRiG configure tool);
  switch hit source from emulator to real MuTRiG; run same 30 s
  windows.
- **Skip for tonight**: main test stops at S9.

## 5. Math expert review (codex2 5.5 xhigh)

A separate codex2 sub-subagent acting as math expert produces
`test_plan/MATH_REVIEW.md`. Required outputs:

- **Rate model**: per-channel rate under each of the three emulator
  modes (Mode A periodic deterministic, Mode B header-sync
  deterministic with sync-aligned bursts, Mode C IID Poisson), and
  the Poisson 5-sigma bound used in §3.1, §3.2, and the cohort S5
  pass criterion. Mode A and Mode B are exact (no Poisson slack);
  only Mode C uses the 5-sigma envelope.
- **Conservation invariant**: exact form of
  `CNT_OPQ_INPUT_W * 4 == CNT_BYTES_WRITTEN + header_overhead`, with
  `header_overhead` enumerated per mu3e frame; AND multi-stage
  conservation across the FEB datapath IPs (rate_emulator -> frame
  assembler -> rbcam ingress -> rbcam egress -> hist IP -> FEB TX) +
  SWB-side BAR1 counters as a chain of stage-pair equalities (exact
  for Modes A/B; Poisson 5-sigma for Mode C).
- **Per-checkpoint lifetime bounds**: derive a per-mode per-rate bound
  `[bound_lo, bound_hi]` for each of the 5 dislin checkpoints
  (pre-rbCAM, post-rbCAM, FEB egress, OPQ ingress, OPQ egress). The
  reference values from the user-supplied plots (e.g. header_sync
  pre-rbCAM [0, 2000], OPQ egress [4356, 99133] cycles) are the
  baseline; the math expert refines them per (mode, rate) combination
  and provides closed-form D-equations:
  - `D_pre = wait_910(hit_ts) + s(q) + 18`
  - `D_post = (GTS_post - ts_hit) mod 8192`
  - `D_feb <= 2F - p + 20 + eps_clk`
  - `D_ing = D_feb + adapter_sync`
  - `D_opq = D_ing + W_n; W_n = max(0, W_{n-1} + S_n - A_n)`
- **In-bound hit fraction target**: each panel must contain >= 99% of
  hits within `[bound_lo, bound_hi]`; the math expert justifies why
  99% is the right threshold (vs 99.9%) given the panel's stochastic
  model.

Until MATH_REVIEW.md is committed and approved, the CP-L (latency)
and CP-A3 (inter-event time) checks in cohorts S2/S4/S5/S6 use the
user-supplied reference bounds as placeholders;
those bounds are correct for the reference operating point but may
be loose at other (mode, rate) combinations and are NOT the gate
until the math expert ratifies them.

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
    |-- MATH_REVIEW.md                   (cohort S8 deliverable)
    |-- MATH_REVIEW_BRIEF.md             (cohort S8 dispatch brief)
    |-- scripts/
    |   |-- run_cp.sh                    (single CP runner)
    |   |-- run_cohort.sh                (cohort wrapper; S0..S10)
    |   |-- collect_evidence.py
    |   |-- check_counter_lossless.py    (E1)
    |   |-- build_rate_histogram.py      (E2)
    |   |-- build_latency_histogram.py   (E3)
    |   |-- decode_offline_dma.py        (E4)
    |   |-- update_checklist.py          (the GATE)
    |   |-- ci_verify_checklist.sh
    |   `-- stp_arm.tcl                  (per-CP STP recipes)
    |-- evidence/
    |   |-- S0_BU/
    |   |   |-- meta.json
    |   |   |-- run.log
    |   |   |-- E1.json
    |   |   `-- ...
    |   |-- S1_A_M4_R1/{C,R,L,O,A}/...
    |   `-- ...
    |-- stp_captures/                    (.stp from on-board STP)
    `-- .githooks/pre-commit             (CHECKLIST guard)
```

## 8. Execution order (initial spin-up)

1. **T1 (this commit)**: TEST_PLAN.md + scripts/ stubs + CHECKLIST.md
   banner-only template + pre-commit hook + ci_verify_checklist.sh.
2. **T2**: dispatch cohort S8 math expert codex2 to draft MATH_REVIEW.md.
3. **T3**: compile new SWB SOF with rdma_subsystem (task #38);
   execute cohort S0 (CP-BU) as smoke; run S1 single-point through
   all 5 staged chains.
4. **T4**: advance through cohorts S2..S7 one at a time; per test
   point, run the staged chain (CP-C -> CP-R -> CP-L -> CP-O -> CP-A)
   in order; on FAIL_AT_<sub-stage>, debug loop per §4.7 at that
   sub-stage. Update CHECKLIST.md every test point via the script only.
5. **T5**: cohort S9 signoff when ci_verify_checklist.sh exits 0.

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
