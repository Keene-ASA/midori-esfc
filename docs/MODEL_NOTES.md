# MODEL_NOTES — design rationale and interpretation notes for `esfc_midori.R`

These notes hold the long-form reasoning that was previously embedded as
comments in the R source. The code references them as `[N01]`–`[N25]`.
Thesis section numbers (§5.x, §7.x) refer to the results chapter structure.

---

## N01 — CAB = 0 normalisation and negative net exports (§5.1 limitation)

The closure anchors NFA*/GDP to data and normalises the BAU current account
to zero. This is a **zero-growth normalisation, not a claim about Japan**,
which in reality runs a surplus. A consequence is that "other net exports"
come out negative (−225.09 index units): the trade block is crop-scope
(fertilizer imports 8.29 + food imports 50.82 = 59.10) while primary income
is economy-wide (284.19). State this as a limitation in §5.1. It is
policy-invariant.

The same normalisation is why every figure panel must be labelled "deviation
from BAU", not as a level — otherwise the CAB panel reads as "Japan's current
account becomes −0.42 tn JPY/yr".

## N02 — r_avg is a net ratio, not a market rate

`r_avg = primary_pct / NFA_pct = 0.0615` exceeds both underlying asset and
liability yields, because numerator and denominator are both **net**: Japan
holds higher-yielding assets against lower-yielding liabilities (e.g. assets
1000 × 4% = 40, liabilities 600 × 1% = 6, net 34/400 = 8.5%). Its only job is
to match BAU primary income; it must never be used as an interest rate, and
it cancels from the policy difference (verified in §7.3).

## N03 — Why the closure is a function of the behavioural block

`kappa0`, `tau` and GDP all depend on the behavioural parameters. The §7.8
invariance test must therefore **re-solve the closure** for each perturbed
parameter, not just swap one external value: perturbing e.g. `zeta` without
recomputing `kappa0` leaves BAU non-stationary, and an "invariance" measured
against a drifting baseline proves nothing.

## N04 — Rice zero-import corner

The residual-import assumption (`IMfood = Dbar − YA`) is structurally weakest
for rice. Japanese rice imports are dominated by the WTO minimum-access
obligation (884 thousand tonnes in FY2024), i.e. they are institutionally
fixed, not a demand residual. The BAU rice import gap is only 3.3% of rice
demand, so the zero-import bound is near for rice while far for the aggregate
(33.7%). Disclose in the limitations.

## N05 — KPI(6) as a national total, and KPI non-independence (§5.2 backbone)

KPI(6) is a **national tonnage target** (chemical fertilizer 0.90 → 0.63 Mt),
not a per-hectare intensity target; MAFF judges attainment on tonnage.
Chemical N is applied only on conventional land, so hitting a national cut of
`pi_` requires scaling the conventional intensity by `1/(1−a)`:

```
Fint = (1 − pi_) * Fbar / (1 − a),   F = Fint * (1 − a) = (1 − pi_) * Fbar
```

At `a = 0` this collapses to the old specification, so S1 is unchanged.
Consequence: at `a = 0.25` the organic KPI alone delivers 25 of the 30
percentage points; conventional land need only cut 6.67% (`Fint = 93.333`).
**The two KPIs are structurally non-independent** — the backbone of §5.2.

In the 4-crop version the dependency order changes: `areaO` must be computed
before `Fint`.

## N06 — The fixed-demand / residual-import closure (`IMfood = Dbar − YA`)

**Label note.** This mechanism was previously called "the Feuerbacher
mechanism". That label is **retired and must not be revived**: Feuerbacher
et al. (2018) use endogenous LES demand with Armington imports, which is a
different closure from the fixed-demand one used here. Cite the closure by
what it does, not by an author.

Food demand is **fixed at the baseline level** and imports absorb the
residual between demand and domestic output. This single line carries the
entire causal mechanism:

- Written as `IMfood = Dbar − YA`, a yield penalty lowers YA, **raises**
  imports, and worsens the CAB.
- "Simplified" to `D = YA/(1−m)`, demand falls with output, imports **fall**,
  and the CAB **improves** — the mechanism reverses sign.

Empirical support for fixing demand rather than letting it fall with output:
Haijima, D. (朏島大樹) (2021), *Keizai Kenkyu* 72(2):113–127,
DOI 10.15057/71666, estimates a QUAIDS system for Japan and finds food demand
price- and income-inelastic over the relevant range. **Romanisation: Haijima,
not "Mikajima"** — confirmed against CiNii and the Hitotsubashi repository
English author name. Any surviving "Mikajima" in drafts, handoffs or
supervisor correspondence is an error and must be replaced.

Two corollaries:

1. `Dbar` cancels from every policy **difference**, so the headline is
   invariant to the demand path — including population decline.
2. That invariance breaks only at the zero-import bound, which is far for the
   aggregate (imports are 33.7% of demand) but near for rice (3.3%; see N04).

PLACEHOLDER_FOR_FULL_CONTENT_SEE_LOCAL_ARTIFACTS
