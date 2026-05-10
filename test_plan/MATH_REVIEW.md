# MATH_REVIEW.md - rdma_subsystem S8 math-expert closure

Reviewer: codex2 5.5 xhigh math expert (acting)
Date: 2026-05-11
Scope: cohort S8 of `TEST_PLAN.md`, sections 2.1, 3.1, 3.2, 3.3,
4.4, 4.6, and 5.

This review signs the mathematical contracts used by the onboard
FEB+SWB staged test plan. It is a derivation note, not an execution
log. The executable evidence remains the CP-C/CP-R/CP-L/CP-O/CP-A
JSON, PNG, VCD, and DMA artifacts.

Source documents reviewed:

- `TEST_PLAN.md`
- `ARCHITECTURE_PLAN.md`
- `../rdma_dma_engine/doc/QUEUE_MATH.md`
- `../rdma_sq_fetcher/doc/QUEUE_MATH.md`
- `../rdma_cq_pusher/doc/QUEUE_MATH.md`
- `../rdma_run_manager/doc/QUEUE_MATH.md`
- `../emulator_mutrig/tlm/mutrig_tlm_contract_pkg.sv`
- `../emulator_mutrig/tb/poisson_delay/results/POISSON_DELAY_REPORT.md`

## 1. Notation and fixed constants

All histogram lifetimes in `TEST_PLAN.md` are in 8 ns cycles unless a
formula explicitly states seconds.

| Symbol | Meaning | Value used here |
|---|---|---:|
| `T` | measurement window | generic; main run is 30 s |
| `N_ch` | number of unmasked channels | mask dependent, max 256 for M0 |
| `R1` | per-unmasked-channel rate | 10 kHz |
| `R2` | per-unmasked-channel rate | 100 kHz |
| `R3` | per-unmasked-channel rate | 500 kHz |
| `R4` | per-unmasked-channel rate | 1 MHz |
| `rho_ch` | rate in hits per 8 ns cycle | `rate_hz * 8e-9` |
| `P_r` | period in 8 ns cycles | `1 / rho_ch` |
| `F` | FEB egress/GTS frame quantum used by CP-L3 | 2048 cycles |
| `H` | short MuTRiG frame interval | 910 cycles |
| `G` | rbcam post timestamp modulus | 8192 cycles |
| `adapter_sync_max` | AVST-to-AXIS adapter latency bound | 16 cycles |
| `DMA_DATA_W` | DMA writer data width | 256 b = 32 B |
| `MAX_BURST_BEATS` | DMA writer max AXI4 burst | 16 beats |
| `B_burst` | bytes per max DMA burst | 512 B |

Rate periods:

| Rate ID | `rate_hz` | `P_r` in 8 ns cycles | M0 aggregate bytes/s at 4 B per hit |
|---|---:|---:|---:|
| R1 | 10,000 | 12,500 | 10.24 MB/s |
| R2 | 100,000 | 1,250 | 102.4 MB/s |
| R3 | 500,000 | 250 | 512.0 MB/s |
| R4 | 1,000,000 | 125 | 1.024 GB/s |

Unless stated otherwise, per-mode bounds below are stated for M0
(all 256 channels unmasked). Every other mask has `N_ch <= 256`, so
its aggregate arrival rate and queue pressure are no worse.

## 2. Per-mode rate model

### 2.1 Common per-channel definitions

Let `A_ch` be 1 when channel `ch` is unmasked and 0 when masked. The
programmed rate is:

```
rate(ch) = A_ch * rate_hz
rho(ch)  = rate(ch) * 8e-9        // hits per 8 ns cycle
```

Masked channels have:

```
count(ch, T) = 0
```

for every mode and every run window. The formulas below apply to
unmasked channels.

### 2.2 Mode A - periodic injection

Process:

- one deterministic renewal process per channel;
- inter-arrival time is exactly `P_r = 1 / rho(ch)`;
- per-channel phases are deterministic and fixed by the test seed;
- no statistical slack is allowed.

With time `T` expressed in the unit reciprocal to `rate(ch)`, the exact
count required by `TEST_PLAN.md` is:

```
count(ch, T) = floor(T * rate(ch)) + 1
```

Equivalently, in 8 ns cycles:

```
count(ch, T_cycles) = floor(T_cycles * rho(ch)) + 1
```

The `+1` is the hit at the deterministic start phase inside the closed
measurement interval. Because the process is deterministic, CP-C,
CP-R, CP-A1, and CP-A2 use exact equality for Mode A, not a sigma band.

The aggregate count for a mask with `N_ch` active channels is:

```
N_A(T) = sum_ch count(ch, T)
       = N_ch * (floor(T * rate_hz) + 1)
```

when all active channels share the same rate and the run starts on the
same closed interval convention.

### 2.3 Mode B - header-sync injection

Process:

- deterministic hits aligned to short MuTRiG frame/header boundaries;
- short frame interval is `H = 910` byte-clock cycles;
- the header-sync injector waits `phase = 100` cycles after the frame
  marker before the injection point;
- channel launch order is staggered by 16 channel slots to avoid
  an artificial single-cycle fan-in while still preserving sync-burst
  semantics.

For the reference all-boundary header-sync point, the eligible header
epochs are:

```
h_k = 100 + k * 910,  k = 0, 1, 2, ...
```

At each eligible epoch, all 256 unmasked channels contribute one hit
inside the deterministic 16-slot stagger window. Counting cumulative
hits up to local time `t` after the first eligible boundary gives:

```
alpha_h(t) = sum_{k=0}^{floor(t / 910)} 256
           = 256 * (floor(t / 910) + 1)
```

This is the required `TEST_PLAN.md` master equation:

```
alpha_h(t) = 256 * (floor(t / 910) + 1), phase=100, stagger=16
```

For a rate-controlled Mode B matrix point, the hardware/software
driver must choose a deterministic sub-sequence of header epochs
(or a deterministic header multiplicity) so the per-channel count
still satisfies the exact programmed-rate count:

```
count(ch, T) = floor(T * rate(ch)) + 1
```

subject to the constraint that every emitted hit is placed on a
header-sync epoch plus the fixed channel stagger. The raw envelope
`alpha_h(t)` is therefore the burst-capacity upper envelope. The
statistical model is still deterministic; no Poisson slack is allowed.

### 2.4 Mode C - IID per channel

Process:

- one independent Poisson counting process per unmasked channel;
- inter-arrival time is exponential with mean `1 / rate(ch)`;
- independent across channels and independent across disjoint windows;
- emulator-only; real MuTRiG is not IID.

For each channel:

```
count(ch, T) ~ Poisson(lambda_ch)
lambda_ch    = T * rate(ch)
```

Therefore:

```
E[count(ch, T)]   = T * rate(ch)
Var[count(ch, T)] = T * rate(ch)
sigma_ch          = sqrt(T * rate(ch))
```

The 5-sigma CP-C/CP-R/CP-A tolerance per channel is:

```
abs(count(ch, T) - T * rate(ch)) <= sqrt(25 * T * rate(ch))
```

For an aggregate of `N_ch` independent unmasked channels:

```
lambda_total = N_ch * T * rate_hz
sigma_total  = sqrt(lambda_total)
5sigma_total = sqrt(25 * N_ch * T * rate_hz)
```

Only Mode C uses this statistical envelope. Modes A and B are exact.

## 3. Multi-stage conservation invariant

### 3.1 Hit-equivalent stage variables

`TEST_PLAN.md` section 4.2 names the CP-C stages. Some stages expose
raw frame or byte counters, not a literal hit counter, so the evidence
ledger must convert each stage to a common hit-equivalent or
payload-byte-equivalent count before comparing adjacent stages.

Definitions:

| Stage | Raw source | Common variable used for equality |
|---|---|---|
| CP-C1 | FEB rate emulator | `H1 = sum emitted_hit_counter[ch]` |
| CP-C2 | frame assembler/header generator | `H2 = decoded hit payloads inserted into frames` |
| CP-C3 | rbcam ingress | `H3 = hits accepted into rbcam` |
| CP-C4 | rbcam egress | `H4 = hits dequeued post-mask` |
| CP-C5 | hist IP | `H5 = sum histogram bins` |
| CP-C6 | FEB TX framer | `H6 = decoded hit payloads sent on link 2` |
| CP-C7 | `CNT_OPQ_INPUT_W` | `B7 = 4 * CNT_OPQ_INPUT_W` bytes at OPQ ingress |
| CP-C8 | `CNT_BYTES_WRITTEN`, `CNT_SQE_CONSUMED` | `B8 = CNT_BYTES_WRITTEN` host payload bytes |
| CP-C9 | `CNT_CQE_POSTED` | `Q9 = CNT_CQE_POSTED` retired drains |

The CP-C hit chain checks adjacent equalities in hit units through
CP-C6, then byte-conservation and job-retire equality at the RDMA
boundary.

### 3.2 Adjacent stage-pair equalities

For Modes A and B, each equality below is exact. For Mode C, the
same equalities are checked within the Poisson 5-sigma envelope from
section 2.4, using the upstream stage as the expected mean when the
comparison is count-based.

```
CP-C1 -> CP-C2:  H2 == H1
CP-C2 -> CP-C3:  H3 == H2
CP-C3 -> CP-C4:  H4 == H3
CP-C4 -> CP-C5:  H5 == H4
CP-C5 -> CP-C6:  H6 == H5
```

The frame/link boundary then becomes a payload-byte equality. Let
`B_hit` be decoded hit-payload bytes. For the current test-plan hit
payload this is 4 B per counted hit:

```
B_hit = 4 * H6
```

The OPQ input byte count includes all 32-bit OPQ words observed by
the DMA packer. Therefore:

```
CP-C6 -> CP-C7:  B7 == B_hit + header_overhead
```

and the RDMA writer conservation equation is:

```
CP-C7 -> CP-C8:  CNT_OPQ_INPUT_W * 4 == CNT_BYTES_WRITTEN + header_overhead
```

under the CP-C gate condition:

```
CNT_HALT == 0
EVENT_SKIP_EVENT_DMA_R == 0
```

The generalized DMA-engine identity from
`../rdma_dma_engine/doc/QUEUE_MATH.md` is:

```
CNT_OPQ_INPUT_W * 4 == CNT_BYTES_WRITTEN + bytes_padding + halt_bytes
halt_bytes = CNT_HALT * 4
```

For this subsystem-level CP-C gate, `CNT_HALT == 0`. The term
`header_overhead` is the decoded-frame overhead that is included in
the OPQ word stream but excluded from hit-payload byte accounting.
When the downstream artifact intentionally stores the full mu3e
frame byte stream rather than decoded hit payload only, the analyzer
must set `header_overhead = 0` for that comparison and check the
non-hit bytes separately. The CP-C equation in `TEST_PLAN.md` uses
the decoded-hit-payload convention.

Finally:

```
CP-C8 -> CP-C9:  CNT_CQE_POSTED == CNT_SQE_CONSUMED
```

after the drain completes, and every consumed SQE must have exactly
one CQE with the same `sqe_id`.

### 3.3 Framing overhead form

For each mu3e frame `f`, define:

```
header_overhead_f =
    sop_k28_5_bytes(f)
  + mu3e_header_bytes(f)
  + crc_bytes(f)
  + eop_k28_4_bytes(f)
  + eoe_pack_padding_bytes(f)
```

The fixed short-frame contract reviewed here is:

- SOP comma: K28.5, byte value `0xBC`, 1 byte when included in the
  counted OPQ stream.
- Frame header: K28.0 plus frame counter high byte, frame counter
  low byte, flags/event high byte, flags/event low byte, 5 bytes.
- CRC: 2 bytes.
- EOP trailer: K28.4, byte value `0x9C`, 1 byte.
- EOE pack padding: the DMA packer pads a final partial 256-bit
  AXI4 beat with zero-strobed bytes; this term is predicted from the
  last valid byte count and is zero for an exact beat boundary.

Thus, if the SOP comma is inside `CNT_OPQ_INPUT_W`, the fixed
non-hit frame overhead is:

```
H_fixed = 1 + 5 + 2 + 1 = 9 bytes/frame
```

If the TX-framer counter convention excludes the idle/SOP comma from
`CNT_OPQ_INPUT_W`, use:

```
H_fixed = 5 + 2 + 1 = 8 bytes/frame
```

The evidence JSON must record which convention it used. The exact
header term over a run is:

```
header_overhead =
  sum_f (H_fixed(f) + eoe_pack_padding_bytes(f))
```

and the host-output conservation check is:

```
CNT_OPQ_INPUT_W * 4 == CNT_BYTES_WRITTEN + header_overhead
```

for the halt-free CP-C gate. If `CNT_HALT != 0`, the run is a CP-C
failure for this test plan and the diagnostic identity becomes:

```
CNT_OPQ_INPUT_W * 4 ==
  CNT_BYTES_WRITTEN + header_overhead + 4 * CNT_HALT
```

## 4. Per-checkpoint lifetime D-equations

All five CP-L panels use the common definition:

```
D_i = (T_i - GTS_hit) / 8 ns
```

where `T_i` is the checkpoint timestamp and `GTS_hit` is the hit
timestamp in the same 8 ns cycle domain after modulo conversion.

### 4.1 Pre-rbCAM: `D_pre = wait_910(hit_ts) + s(q) + 18`

Let:

```
wait_910(hit_ts) = (H - ((hit_ts - phase) mod H)) mod H
H                = 910 cycles
phase            = 100 cycles for header-sync injection
```

The 910-cycle constant is the short MuTRiG frame interval. The raw
MuTRiG frame-marker model latches visible hits at a frame boundary
and emits them in the next short frame. Therefore a hit first waits
for the next eligible 910-cycle frame boundary.

Let `q` be the ordered set of hits already ahead of the current hit
at the frame marker. The service addend is:

```
s(q) = sum_{j in q} service_cycles(j)
```

For the compact short-hit model, `service_cycles(j)` is the
deterministic serializer/payload service contribution of the hits
ahead of the current hit, including the 3/4-byte alternating
short-hit packing rule. This is the queueing term that makes the
pre-rbCAM panel a bounded queue rather than a pure uniform
`0..909` box.

The fixed `18` cycles are the virtual MuTRiG wrapper latency after
the marker decision: two local capture/output flops plus the
16-cycle serializer/parser margin used by the emulator coverage
contract. Thus:

```
D_pre = wait_910(hit_ts) + s(q) + 18
```

The standalone Poisson delay characterization confirms the shape:
at low load, `true_ts -> frame_start` stays in one 910-cycle box,
and `true_ts -> output` adds bounded serializer overhead; at full
raw load, accepted hits remain below two frames. The CP-L bound
`[0, 2000]` is therefore conservative and contains the deterministic
Modes A/B and the Mode C 99% target for the accepted-hit population.

### 4.2 Post-rbCAM: `D_post = (GTS_post - ts_hit) mod 8192`

The post-rbCAM histogram compares the hit timestamp to the rbcam
post timestamp in the GTS modulus:

```
D_post = (GTS_post - ts_hit) mod 8192
```

The `8192` modulus prevents a normal post-rbCAM delay near 2048
cycles from aliasing across the counter wrap. The rbcam post path
is aligned to the next GTS slice around `2048` cycles after the hit.
The reference p05/p50/p95 values (`2012/2070/2128`) show the local
pipeline and phase spread around that slice.

The accepted window:

```
[2000, 2200]
```

is the 2048-cycle GTS step plus deterministic rbcam/pipeline slack:
48 cycles below the nominal anchor and 152 cycles above it. This is
well inside the 8192-cycle modulo, so wrap cannot turn a late hit
into an in-bound hit.

### 4.3 FEB egress: `D_feb <= 2F - p + 20 + eps_clk`

Let `F = 2048` cycles be the FEB egress/GTS frame quantum. Let `p`
be the payload-ready phase inside the two-frame readout opportunity,
with:

```
0 <= p < 2F
```

After rbcam post, the TX path waits until the next legal egress
opportunity that can carry the already stable payload. The residual
wait is therefore bounded by:

```
wait_feb(p) <= 2F - p
```

The fixed `20` cycles cover the TX-framer launch, local register
handoff, and marker/trailer bookkeeping after the egress opportunity
opens. Clock tolerance is:

```
eps_clk = eps_jitter + eps_ppm + eps_cdc + eps_quant
```

with components:

- `eps_jitter`: PLL and local clock jitter, less than one 8 ns bin
  after histogram binning.
- `eps_ppm`: bounded frequency offset between FEB/SWB timestamp
  domains over the short CP-L interval; for typical 50 ppm clocks
  this is less than one cycle over a 20,000-cycle lifetime and is
  still explicitly budgeted.
- `eps_cdc`: synchronizer/sample uncertainty when timestamps cross
  the AVST/AXIS boundary, budgeted at two cycles.
- `eps_quant`: histogram bin quantization and inclusive edge
  convention, one cycle.

The compact equation is:

```
D_feb <= 2F - p + 20 + eps_clk
```

The CP-L3 panel uses the derived conservative bound:

```
[2049, 6143] = [F + 1, 3F - 1]
```

which covers the post-rbCAM anchor plus up to two egress-frame waits
and the fixed/pipeline slack.

### 4.4 OPQ ingress: `D_ing = D_feb + adapter_sync`

The SWB OPQ-ingress timestamp is the FEB-egress lifetime plus the
AVST-to-AXIS adapter synchronization latency:

```
D_ing = D_feb + adapter_sync
```

The adapter has no unbounded queue in this contract. Its latency is
a bounded synchronizer/elastic alignment term:

```
0 <= adapter_sync <= 16 cycles
```

Therefore CP-L4 uses:

```
[2049, 6159]
```

which is CP-L3 with the upper edge relaxed by 16 cycles.

### 4.5 OPQ egress: `D_opq = D_ing + W_n`

At the OPQ/DMA boundary the waiting time is a workload-conservation
queue. Let hit or OPQ-word `n` arrive with inter-arrival time `A_n`
since the previous accepted word. Let `S_n` be the service time
contribution of word `n` through the OPQ egress/DMA service point.
The standard Lindley recursion for a G/G/1 queue is:

```
W_n = max(0, W_{n-1} + S_n - A_n)
```

and the panel lifetime is:

```
D_opq = D_ing + W_n
```

Stability requires:

```
E[S_n] < E[A_n]
```

or, equivalently, aggregate offered rate below service rate. When
that condition is violated, no finite steady-state OPQ-egress bound
exists. A finite 30 s run can still be bounded by a finite backlog
calculation, but that is a diagnostic overload bound, not a
steady-state acceptance window.

## 5. Per-mode, per-rate panel bounds

### 5.1 Bound formula

The first four panels have compact support under the derived
equations above. Mode and rate affect their occupancy shape, but not
the accepted 99% containment window:

```
pre-rbCAM:   [0, 2000]
post-rbCAM:  [2000, 2200]
FEB egress:  [2049, 6143]
OPQ ingress: [2049, 6159]
```

The OPQ-egress panel additionally depends on the queue workload:

```
OPQ egress lower = 4356
OPQ egress upper = max(99134, 6159 + W_99(mode, rate, mask, service))
```

`99134` is the user-supplied reference operating-point upper edge
for the header-sync OPQ-egress panel. It remains the default
non-saturating gate because it covers deterministic burst drain,
SQE/CQE orchestration, and DMA writer startup overhead that are not
visible in the first four panels.

For Mode C, an exponential tail approximation is the conservative
M/M/1 envelope:

```
P(W > x) ~= exp(-(mu - lambda) * x)
W_99     = ln(100) / (mu - lambda)
```

when `lambda < mu`. If `lambda >= mu`, `W_99` is undefined because
the steady-state queue does not exist.

### 5.2 Approved bounds table

The table is for M0. Other masks are no worse. The OPQ-egress column
is approved only under the non-saturating service condition in
section 7: enough DMA outstanding write credit or measured host
credit return to make `lambda < mu` with margin.

| Mode | Rate | pre-rbCAM | post-rbCAM | FEB egress | OPQ ingress | OPQ egress |
|---|---|---|---|---|---|---|
| A periodic | R1 10 kHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| A periodic | R2 100 kHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| A periodic | R3 500 kHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| A periodic | R4 1 MHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| B header-sync | R1 10 kHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| B header-sync | R2 100 kHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| B header-sync | R3 500 kHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| B header-sync | R4 1 MHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| C poisson_iid | R1 10 kHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| C poisson_iid | R2 100 kHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| C poisson_iid | R3 500 kHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134] |
| C poisson_iid | R4 1 MHz | [0, 2000] | [2000, 2200] | [2049, 6143] | [2049, 6159] | [4356, 99134]* |

`*` The Mode C R4 M0 row is approved only with the service fix or
measured service margin in section 7. With the one-outstanding,
1 us BVALID model, the steady-state OPQ-egress bound is not finite;
the diagnostic 30 s p99 upper edge is approximately 3.7 billion
8 ns cycles plus the fixed CP-L4 offset. That point must not be
used as a normal CP-L gate without reducing the offered envelope or
adding DMA write credit.

### 5.3 CP-A3 inter-event distribution bounds

The CP-A3 inter-event histogram does not use the five lifetime bounds
above. It uses distribution-shape tests:

| Mode | Inter-event model | Acceptance |
|---|---|---|
| A periodic | delta at `P_r` for each active channel | exact bin at programmed period, allowing timestamp bin quantization |
| B header-sync | comb on `910`-cycle header epochs, with `phase=100`, `stagger=16` | exact comb support; no Poisson slack |
| C poisson_iid | exponential with rate `rate(ch)` per channel | KS/chi-squared p-value > 0.01 and count within 5 sigma |

For aggregate all-channel Mode C, superposition of independent
Poisson channels is Poisson with rate `N_ch * rate_hz`, so the
aggregate inter-event time is exponential with parameter
`N_ch * rate_hz`. Per-channel CP-A3 must still use `rate(ch)`.

## 6. Why the in-bound target is 99%, not 99.9%

The CP-L containment target is:

```
in_bound_fraction >= 99%
```

This is mathematically appropriate for the panels:

- Modes A and B are deterministic. Their distributions have compact
  support after the fixed queue and frame equations. A 99% target is
  effectively exact for a correct implementation; outliers indicate
  a measurement edge, reset/run-boundary inclusion, or a real bug.
- Mode C count variation is already handled by the Poisson 5-sigma
  rule in CP-C, CP-R, CP-A1, and CP-A2. Requiring 99.9% containment
  again in the latency panel would double-count rare stochastic
  excursions.
- The OPQ-egress Mode C panel under high load has an exponential
  or heavier right tail from the G/G/1 waiting-time recursion. The
  99th percentile is a stable engineering gate for queue containment;
  the 99.9th percentile is dominated by rare burst/backlog episodes
  and becomes a throughput-stress metric, not a panel-shape metric.
- The plan still requires p05, p50, and p95 markers inside the
  window and silicon-vs-sim bin agreement within Poisson 5 sigma, so
  a design cannot pass by hiding a distorted distribution behind the
  1% tail allowance.

Therefore 99% is the correct CP-L panel-containment threshold. 99.9%
belongs in a separate stress/soak tail report, not in the nominal
panel gate.

## 7. [NOTE] R4 M0 Mode C max-rate envelope

This is the only rate/mode point that changes the acceptance
interpretation.

At R4 M0:

```
lambda_hits = 256 channels * 1e6 hits/s = 256e6 hits/s
lambda_bytes = 256e6 * 4 B = 1.024 GB/s
```

The DMA datapath has two different service ceilings:

1. The internal writer bandwidth ceiling from the queue-math signoff:

```
B_out_eff = 32 B * 250e6 * 16/17 = 7.53 GB/s
```

This is not the bottleneck.

2. The host-credit-limited write service. With max bursts of 512 B,
host BVALID/credit return latency `T_BVALID`, and `C_wr`
outstanding write credits:

```
B_credit = C_wr * 512 B / T_BVALID
mu_hits  = B_credit / 4 B
```

For the one-outstanding, 1 us worst-case model:

```
C_wr = 1
B_credit = 512 MB/s
mu_hits = 128e6 hits/s
rho = lambda_hits / mu_hits = 256e6 / 128e6 = 2.0
```

`rho >= 1`, so the Lindley recursion has positive drift:

```
E[S_n - A_n] > 0
```

and no finite steady-state OPQ-egress waiting time exists. The
queue backlog grows linearly during a 30 s run. The overload rate is:

```
lambda_hits - mu_hits = 128e6 hits/s
backlog_30s = 3.84e9 hits
end_wait    = backlog_30s / mu_hits = 30 s
```

That is a diagnostic overload, not an acceptable CP-L operating
point.

If the host bridge returns write credit at `T_BVALID = 200 ns`,
then a single outstanding credit gives:

```
B_credit = 512 B / 200 ns = 2.56 GB/s
mu_hits = 640e6 hits/s
rho = 0.40
```

which is stable. If the worst-case `T_BVALID = 1 us` must be
supported, the required credit is:

```
C_wr > lambda_bytes * T_BVALID / 512 B
     > 1.024e9 * 1e-6 / 512
     > 2.0
```

So `C_wr = 4` is the practical minimum with margin:

```
C_wr = 4, T_BVALID = 1 us -> B_credit = 2.048 GB/s, rho = 0.50
```

Reduced-envelope option:

```
800 kHz/channel -> lambda_bytes = 819.2 MB/s
```

This is stable with `C_wr >= 2` at 1 us credit return (`rho = 0.80`)
or with `C_wr = 1` only if measured/effective `T_BVALID <= 625 ns`.

Conclusion:

- The rdma_dma_writer datapath width and AXI4/PCIe bandwidth are
  sufficient for R4 M0.
- The one-outstanding, 1 us host-credit model is not sufficient for
  R4 M0 Mode C and is not even comfortable at R3 M0.
- The preferred fix for keeping R4 M0 Mode C in the matrix is to add
  at least four outstanding DMA write credits, or otherwise prove
  measured host credit return at or below 200 ns.
- If the writer remains one-outstanding under the 1 us bound, reduce
  the high-rate Mode C envelope. The 800 kHz/channel suggestion is
  approved only with `C_wr >= 2` or measured `T_BVALID <= 625 ns`;
  with strict `C_wr = 1` and 1 us, the stable limit is below
  500 kHz/channel after margin.

The S8 math review therefore approves the derivations and the panel
gate, with this explicit R4 M0 Mode C service-margin note carried
into the CP-L/CP-A3 execution checklist.

## 8. Approval

Reviewer: codex2 5.5 xhigh math expert (acting), Date: 2026-05-11, Status: APPROVED
