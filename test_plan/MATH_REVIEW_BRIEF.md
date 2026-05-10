# MATH_REVIEW_BRIEF.md - S8 math review summary

Reviewer: codex2 5.5 xhigh math expert (acting)
Date: 2026-05-11
Status: APPROVED

## User-facing summary

Modes A and B are deterministic. Mode A is periodic, with exact
per-channel count `floor(T * rate(ch)) + 1`. Mode B is header-sync
deterministic; the all-boundary burst envelope is
`alpha_h(t) = 256 * (floor(t/910) + 1)` with `phase=100` and
`stagger=16`. Mode C is IID Poisson per channel, with
`E[count(ch,T)] = T * rate(ch)`, variance `T * rate(ch)`, and
5-sigma count band `sqrt(25 * T * rate(ch))`.

The five lifetime equations are:

```
D_pre  = wait_910(hit_ts) + s(q) + 18
D_post = (GTS_post - ts_hit) mod 8192
D_feb <= 2F - p + 20 + eps_clk
D_ing  = D_feb + adapter_sync
D_opq  = D_ing + W_n,  W_n = max(0, W_{n-1} + S_n - A_n)
```

Approved panel bounds for the non-saturating service envelope are:
pre-rbCAM `[0, 2000]`, post-rbCAM `[2000, 2200]`, FEB egress
`[2049, 6143]`, OPQ ingress `[2049, 6159]`, and OPQ egress
`[4356, 99134]`. These are M0-safe; masked patterns are no worse.

The 99% in-bound threshold is the right CP-L gate: Modes A/B have
compact deterministic support, while Mode C already uses Poisson
5-sigma for counts and has a real exponential queue tail at OPQ
egress. A 99.9% latency-panel target would mostly test rare queue
tail excursions rather than nominal containment.

R4 M0 Mode C needs an explicit service-margin note. At 1 MHz on all
256 channels the offered payload is 1.024 GB/s. The DMA datapath and
PCIe bandwidth are wide enough, but a one-outstanding writer with
1 us BVALID credit return is unstable. Keep R4 M0 Mode C only with
at least four outstanding DMA write credits or measured host credit
return near 200 ns; otherwise reduce the high-rate envelope
(800 kHz/channel is stable only with `C_wr >= 2` at 1 us, or with
`C_wr = 1` and `T_BVALID <= 625 ns`).
