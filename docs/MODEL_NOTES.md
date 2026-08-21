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

## N07 — The sign of dGHG is a function of the evaluation date (§5.6 headline)

**Superseded.** Earlier versions of this note reported a sign reversal at
2031.5 (later 2032.10) and treated that date as the §5.6 headline. That
figure was computed **without the soil-carbon reservoir**, i.e. counting
CH4 and N2O but not the CO2 removal driven by the same organic carbon input.
It is the mirror image of the error the thesis criticises MAFF for, and it is
retired. See N22 for the argument that replaces it.

With the reservoir in place (`esfc_midori_20260817.R`):

```
2030            dGHG  −35.19      (organic area 1.6%)
2050            dGHG −172.90      (−1.729 Mt-CO2eq/yr)  KPI target year
2070.1          annual dGHG crosses back to POSITIVE
2122            cumulative dGHG crosses to positive
equilibrium     dGHG +139.78      (+1.398 Mt-CO2eq/yr, permanent)
```

Two things survive from the old note and should still be stated:

- **S1 alone can never cross.** With `a = 0`, `GHGnet = −103.3459·pi_ < 0`
  for all t. The organic KPI is what makes a reversal possible at all.
- **dCAB is still negative in the terminal period**, i.e. the NFA gap is
  *widening, not stabilising* at 2050. Report this as a property of the path;
  never quote a level read off an arbitrary post-2050 year.

## N08 — Sensitivity design: two sweeps in the body

The body carries exactly **two** sweeps — §7.1 (`psi_bar`) and §7.2
(`r_marg`) — one per causal link (yield penalty → imports; NFA snowball).
§7.3–7.8 are robustness checks for a footnote or appendix. Monte Carlo and
global sensitivity analysis are deliberately **not** done: in earlier drafts,
proliferation of sweeps blurred the argument.

## N09 — psi_bar: band construction and the three-pillar argument (§5.7)

**Band construction.** The band uses coherent source states, not per-crop
cherry-picking: the upper endpoint sets all four crops to de Ponti et al.
(2012) values simultaneously (rice 0.94, veg 0.80, fruit 0.72, other 0.80 →
psi_bar = 0.8305). A corner assembled from the most organic-favourable value
per crop (0.8667) corresponds to no state any source supports and
double-counts source uncertainty — it is not used. The baseline **is** the
lower endpoint (0.7176); disclose this rather than calling it a "central"
value.

**The break-even (0.8045) sits below the band's upper end (0.8305)**, so "the
sign holds at both endpoints" is not available. §5.7 argues instead on four
legs:

1. Every Japanese anchor sits below the break-even: Tottori 0.72 →
   psi_bar 0.7176; Nagumo et al. (2014) 0.792 on rice → 0.7392; even Saito
   et al. (2001) 0.895 → 0.770 < 0.8045. Crossing requires **all four crops
   at de Ponti's plot-level values simultaneously**.
2. de Ponti et al.'s own §4.2 rejects that state: plot/crop-level results do
   not extrapolate upward, and at farm/regional level the organic gap can
   exceed 20%, i.e. psi_bar ≤ 0.80 < 0.8045.
3. The margin is thin (0.026) — say so explicitly.
4. The psi_rice ladder (0.94 → 0.90 → 0.79 → 0.72: N-source substitution
   only → near-zero pesticides → national on-farm variability) explains
   **why** de Ponti's rice 0.94 sits so high: it is the top rung.

## N10 — GHG robustness: what is robust is *that* it crosses, not *when*

Two earlier claims are retired. The first, "an effectively unconditional
reversal", was made on a satellite that omitted soil carbon. The second,
"the crossover is 2070 ± 3 years", was computed before the residue-loss
correction of N25 and before the seasonal factor `f` was swept. What survives
is stronger than either, because it is a statement about the *sign* rather
than the date.

**Central case** (C/N 17.1, phi 1.0, f 0.40): `dGHG` 2050 = −1.390 Mt-CO2eq/yr,
annual crossover **2067.5**, cumulative **2112**, equilibrium **+1.398 Mt/yr**.

### (a) Emission parameters: tight

| C/N | phi | dGHG 2050 (Mt) | crossover | cumulative | equilibrium |
|---|---|---|---|---|---|
| 13.0 | 1.000 | −0.917 | 2066.2 | 2108 | +103.81 |
| 13.0 | 0.644 | −0.701 | 2070.9 | 2127 | +55.87 |
| 15.0 | 1.000 | −1.148 | 2067.0 | 2111 | +121.35 |
| **17.1** | **1.000** | **−1.390** | **2067.5** | **2112** | **+139.78** |
| 17.1 | 0.644 | −1.006 | 2070.9 | 2126 | +79.06 |
| 20.0 | 1.000 | −1.725 | 2068.1 | 2114 | +165.22 |
| 20.0 | 0.644 | −1.222 | 2070.9 | 2125 | +95.45 |

Span 4.7 years. The reason is the proportionality noted throughout: `dCH4`
and the sink are both strictly proportional to the same organic-carbon input,
so C/N scales both. `nu_O` is the cleanest case — moving it across its full
field range [1.0417, 1.6562] shifts the crossover by **less than 0.1 years**,
because it enters the green-manure N2O, the CH4 uplift and the carbon input
together.

### (b) The seasonal factor `f` dominates

`k_paddy = f × 0.11683`, with `f` bounded by the [0.2, 0.6] of Shirato &
Yokozawa's submerged/non-submerged factors (N20):

| f | k_paddy | turnover | dGHG 2050 | crossover | cumulative |
|---|---|---|---|---|---|
| 0.20 | 0.02337 | 42.8 yr | −167.46 | 2077.5 | 2138 |
| 0.30 | 0.03505 | 28.5 yr | −152.19 | 2071.2 | 2122 |
| **0.40** | **0.04673** | **21.4 yr** | **−139.05** | **2067.5** | **2112** |
| 0.50 | 0.05842 | 17.1 yr | −127.70 | 2065.0 | 2106 |
| 0.60 | 0.07010 | 14.3 yr | −117.87 | 2063.2 | 2102 |

Span **14.3 years** — three times the emission parameters combined. `f` is the
single largest remaining uncertainty in §5.6, and it is a soil-science
quantity, not an economic one. Resolving it means running RothC-26.3 with the
0.2/0.6 modification under representative Japanese monthly weather and reading
off the decomposition-weighted annual mean. Until then the date must be
reported as an interval.

### (c) Everything else

```
straw incorporation  0.759 (H18, adopted)     2067.5
                     0.777 (R6-implied)       2067.5   -0.1
                     1.000 (all incorporated) 2066.7   -0.9
                     0.000 (all removed)      2070.0   +2.4
upland residue       2.0 t DM/ha (Ogawa)      2067.5
                     0.0 (no upland loss)     2069.4   +1.8
                     4.0 (double)             2065.6   -1.9
nu_O                 1.0417 .. 1.6562         2067.5   +/-0.1
```

### (d) The claim that can be defended

Running all 32 combinations of the **extreme corners** of C/N {13, 20},
phi {0.644, 1.0}, f {0.2, 0.6}, straw incorporation {0, 1} and upland residue
{0, 4 t DM/ha}:

```
crossover range  2058.6 .. 2090.8    median 2070.3   IQR 2065.5 .. 2081.4
every combination crosses            YES
equilibrium dGHG positive in all     YES
```

So the defensible statement is:

> Under every parameter combination examined, the annual GHG balance turns
> positive and the equilibrium balance is a permanent increase. The date of
> the turn lies between the late 2050s and the early 2090s, and its
> uncertainty is dominated by the paddy soil-carbon decomposition rate rather
> than by any emission parameter.

That is weaker on the date and stronger on the mechanism, which is the right
trade: the paper's claim is that a stock adjustment cannot be netted against a
flow (N22), and that claim does not depend on when the two curves cross.

Two checks that survive unchanged, both evaluated on the *permanent*
components (N22):

- **Least favourable corner (§7.5).** `epsN_gm = 0.00195`, the measured
  green-manure EF (Xie et al. 2016): margin still 8.36×.
- **C/N break-even.** Route A is `0.050723 × C/N` at the adopted `nu_O` and
  the break-even uplift is 0.059273, so a permanent increase would be avoided
  only at **C/N = 1.17**. Microbial biomass itself is ~6–8 and plant residues
  13–80. Routes B/C/D (0.99–1.52) do not depend on `nu_O` at all.

## N11 — The −30% conventional yield loss is bounded (§7.7)

`g(F)` is strictly concave, so with `m0` pinned the largest attainable loss
at −30% N is the **linear limit** (9.36%) — which is exactly what Toriyama's
own Discussion asserts holds up to ~500 g/m². Reporting the bound removes the
need to defend either Li et al.'s manure-contaminated N variable or the
choice to evaluate at 96 kgN/ha; both push the loss **down** and the headline
**up**, so this check runs against the argument — which is why it belongs in
the paper. The calibrated loss (5.71%) is 61% of the bound.

Over the admissible gamma interval the conversion effect spans −5.22 to −4.1
(a 21% range) while S1 spans −4.61 to −10.1 (a 2.2× range): **splitting S1
from the conversion effect is what protects the headline** from the gamma
uncertainty.

## N12 — Part B motivation: allocation is a lever the KPI omits (§5.5)

KPI(7) fixes **how much** area converts but not **which**, and the outcome
differs by ~5× across allocations that all satisfy the same 25% area target.
The government itself flags allocation as a lever — MAFF (2026), Midori GX
Acceleration Plan: p.10 proposes promoting the clustering of organic farmland
through zoning (「ゾーニング等により有機農業の団地化を推進」); p.15 states
that the key challenge is how far Japan's paddy agriculture can be converted
to organic (「日本の水田農業をいかに有機へ転換できるかが課題」) — yet the
allocation dimension is simply absent from the KPI. That is the section's
argument in one line.

## N13 — Per-area import cost ranking is source-conditional

`cost_c = w_c(1 − psi_c)/sA_c` is an authors' derivation from three primary
sources (output-value shares, area shares, yield ratios), not a published
statistic — label it as such. Under the baseline psi vector the ranking is
other 0.1275 < rice 0.1634 < fruit 0.4830 < veg 0.8031; under an
all-de-Ponti psi vector it becomes rice < other < veg < fruit, a full
reversal. This does not damage §5.5 — whose claim is that an area-only KPI
does not determine the outcome — but any statement about **which** crop is
cheapest must be reported as source-conditional.

## N14 — Reading the allocation table

CAB-worst ("veg first") still carries a positive organic rice share because
the veg and fruit caps (75% of own area) bind before the 25% target is met
and rice absorbs the remainder — which is why its dGHG is positive rather
than negative.

## N15 — Mandatory caveat: no paddy CH4 mitigation channel

The model has **no** channel for paddy CH4 mitigation (extended mid-season
drainage / AWD). The conclusion of Part B is therefore **not** "do not
convert paddy". It is: an area-only KPI does not determine the outcome; the
design lacks either a specification of which land converts, or a pairing of
paddy conversion with CH4 mitigation.

## N16 — Frontier: non-monotonicity and where the curvature lives

The frontier is non-monotonic: pushing everything onto the cheapest crop is
not optimal because the 75% cap binds and forces spillover into more
expensive crops. The **smallest** CAB loss occurs at a rice share of 0.25 of
the area target, not at 0 — "minimum" means minimum loss; phrase it that way.

Asymmetry: dGHG is exactly linear in organic rice area (increments of 48.796,
because dN2O and dN2Ogm are both pinned once areaO = 0.25), while dCAB is
not. The frontier's curvature therefore comes entirely from the CAB side.

## N17 — Trade-off figure: caption notes

The two labelled points "Paddy-sparing" and "Rice-focused" **are** the dashed
curve's endpoints by construction — not independent observations.
"CAB-optimal" appears to sit on the dashed curve but does not: its rice share
of the area target is 0.256 against the curve's node at 0.250. Say so in the
caption so the five points are not read as five independent runs.

## N18 — What decides the headline: the six-parameter reduction

The policy difference collapses to a two-state linear recursion:

```
dCAB = −pF·dF + dYA + r_marg·dNFA[−1]
dNFA = dNFA[−1] + dCAB
```

because `X_ag` and `NX_other` are exogenous constants, `IMfood = Dbar − YA`
removes `Dbar`, and `YA` contains no capital — so the demand, investment,
government and non-agricultural blocks drop out entirely. Of 31 equations,
only **six parameters** matter: `Fbar`, `pF`, `beta`, `gamma`, `psi_bar`,
`r_marg` (plus the KPI paths and the unit conversion `CROP_OUT`). All six are
either official statistics or swept. And since `m0` is quasi-invariant,
`beta`/`gamma` effectively reduce to `m70` alone.

This reduction is what makes the invariance results of §7.8 (all behavioural
parameters, all import-dependency parameters) exact rather than approximate.

## N19 — C/N 13 → 17.1: a compost constant used for a green-manure flow

`ch4_uplift` route A converts the model's organic **nitrogen** flow into a
**carbon** input via a C/N ratio. The retired value 13.0 was Katayanagi et
al. (2016)'s own assumption **for compost**; the ledger's own annotation said
so ("C/N=13 は Katayanagi 自身の堆肥仮定"). But the model's organic N flow is
green manure: `nu_O` is calibrated on Chinese milk vetch trials (Nakayama &
Yoshida 2005; Nagumo et al. 2014), `psi_rice` comes from the same
"milk vetch + zero synthetic N" system, and `epsN_gm` is the green-manure
N2O EF. Using a compost C/N there was a category error.

The correct value was already in the ledger, verified against the original
PDF: Nagumo et al. (2014) measure the incorporated milk vetch at C 37.0%,
N 2.17%, i.e. **C/N = 17.1**.

Consequences:

- green-manure C input 1488.5 → **1957.9 kgC/ha/yr**
- `ch4_uplift` route A 0.6594 → **0.8674**
- agreement with the independent routes improves: B = 1.005 and D = 0.986
  were 1.5× away from the old value and are 13% away from the new one. This
  is the same direction as the ledger's note that the retired assumed value
  0.99 "had no derivation but turned out reasonable".
- the §7.4 margin improves from 11.12× to **14.63×**.

Further improvement available: Nagumo measures C 37.0% directly, so the
carbon input can be obtained from incorporated dry matter × carbon fraction
without passing through C/N at all. C/N is only an auxiliary for going from
nitrogen to carbon.

## N20 — The SOC reservoir: deviation form, and where `k` comes from

**Deviation form.** The reservoir is written on `s = SOC − SOC_BAU`:

```
s_t = (1 − k)·s_{t−1} + i_t
```

so the initial stock **cancels algebraically** and never has to be pinned.
This removes one unresolved input, keeps BAU's `GHGnet` exactly zero, and is
why `SOC0_paddy = 73.2 MgC/ha` (Matsui et al. 2021) is carried in the ledger
as reporting only. The block is strictly one-way: SOC never re-enters `YA`
(see N23 and the exclusion rows in the ledger).

**Where `k` comes from.** Not from RothC internals. At steady state annual C
input equals annual decomposition, so `k = I_eq / SOC_eq`, and both papers
publish `I_eq` and `SOC_eq` for the same sites at the same depth, making the
ratio internally consistent:

- **Upland** — Shirato, Hakamata & Taniyama (2004) Table 3 publishes the
  *modified*-model equilibrium input directly for four Andosol sites:
  2.5/110, 2.7/85, 2.9/85, 4.1/92 → **k = 0.033294 /yr** (turnover 30.0 yr).
- **Paddy** — Shirato & Yokozawa (2005) Table 1 publishes the *original*-model
  equilibrium input for five sites → 0.11683, to which the modification's
  seasonal factors (0.2 submerged / 0.6 otherwise) apply. The annual
  effective factor is a decomposition-weighted average bounded by [0.2, 0.6];
  **f = 0.40 is this paper's derivation** (the rice season is ~5 months but
  warm and wet, so it carries the larger share of annual decomposition) →
  **k = 0.046733 /yr** (turnover 21.4 yr). The band moves `k` over
  [0.0234, 0.0701] and the crossover by roughly ±5 years.

`k_paddy > k_upland` looks backwards but is right: Japanese upland is
Andosol-dominated (57.2% of area) and Al-humus complexes give H(f) = 2.70–3.93,
i.e. HUM decomposes 2.7–3.9× more slowly than in the original RothC.

**Input quality is not an escape route.** One might hope that green manure,
being labile, is retained far less than the straw and root input from which
`k` was derived, which would shrink the sink. It does not. Using Rothamsted's
own published equilibrium pools (Coleman, Prout & Milne 2024: Hoosfield
pre-1852, I = 1.70, clay 23.4%, DPM 0.1533 / RPM 4.4852 / BIO 0.6671 /
HUM 25.8576) the analytic steady state is verified — the rate modifier backed
out of BIO (0.5054) and out of HUM (0.5051) agree to 0.0003, and those two
pools are 85% of the active stock. Varying DPM:RPM from the RothC default
1.44 to an extreme 9.0 changes equilibrium SOC by only **11%**, because HUM
holds 83% of the active stock and receives carbon from the decomposition
cascade regardless of which pool it entered through. Overturning the sink
would require a 55% reduction. RothC's own guidance also assigns 1.44 to
"most agricultural crops", and green manure is agricultural plant material;
there is no separate green-manure ratio in RothC.

## N21 — `A_ha`, and the two denominators behind KPI(7)

`ghg_ch4_pad0` is Japan's **national total** rice-cultivation CH4 and enters
as `dCH4 ~ ghg_ch4_pad0·(sA_rice·LAo/LAbar)·ch4_uplift`. Therefore
`sA_rice · LAbar ≡ Japan's rice cultivation area` is an identity of the
model's construction, not an assumption: 1.47 Mha / 0.515 = 2.854 Mha =
LAbar, hence **A_ha = 28,544 ha per index-ha**. It is used only for the
physical conversion inside the SOC block; `dCAB` and the emission indices do
not touch it.

This exposes an internal inconsistency worth disclosing. KPI(7)'s 1.00 Mha is
defined against **arable land, 4.00 Mha** (recorded in the ledger's `A_2050`
note). The model's LAbar is the **four crops' planted area, 2.854 Mha**.
So `a = 0.25` corresponds to 0.714 Mha, i.e. 71.4% of the KPI's stated area.
The difference is grassland and other arable land, for which the model has no
organic-conversion channel, so excluding it is correct by design; what is not
automatic is applying the 25% rate to a smaller base.

**The direction is conservative.** Placing the full 1.00 Mha on the four
crops requires `a = 0.3503` and gives a conversion effect of **−4.2171**
(−0.2442 tn JPY/yr), 1.57× the reported headline. The reported −2.6925 is
therefore a **lower bound**, and should be stated as such.

## N22 — A stock adjustment cannot be netted against a flow (§5.6 headline)

This is the argument that replaces the old "the reversal has a date" framing
(N07) and the old "unconditional reversal" claim (N10).

Soil carbon is a **stock adjustment**: the reservoir fills, approaches a new
equilibrium, and the annual gain goes to zero. By 2050 the reservoir is only
34% of the way to equilibrium and the marginal annual gain has already fallen
to 68% of the gross input. Paddy CH4 and green-manure N2O are **flows**: they
persist for as long as the land stays organic. Therefore:

```
2050            −1.729 Mt-CO2eq/yr   the policy looks like a success
2070.1           0                   annual balance turns
2122             0                   cumulative balance turns
equilibrium     +1.398 Mt-CO2eq/yr   permanent
```

MAFF applies **0.93 tCO2/ha/yr as a constant annual rate** over the policy
horizon (11th Third-Party Committee, Table 3-1, n = 45). Netting a constant
sequestration rate against an emission flow is netting a stock adjustment
against a flow. Stock-flow consistent accounting does not permit it; a
single-period LCA or a Tier-1 inventory cannot detect it. `fig_soc_crossover`
plots both conventions on the same policy: MAFF's line is flat forever at
−0.664 Mt/yr while the reservoir's contribution decays, and at 2050 MAFF's
convention is actually the *less* favourable of the two (−0.664 vs −1.729),
so the result cannot be dismissed as a harsher accounting choice.

Two supporting facts, both from the model's own sources:

- The developer of the modified RothC states that RothC **cannot separate CH4
  from CO2**, so in paddy soils carbon loss is not CO2 alone (Shirato &
  Yokozawa 2005, Discussion). Any RothC-based soil-carbon figure therefore
  inherits a CO2-only scope from the model structure.
- MAFF itself **did subtract paddy methane** in 2007 when evaluating compost:
  3.10 gCH4/m²/yr net for lowland soils, deducted from the sequestration gain
  to give a national balance of ~1.93–2.04 MtC/yr (Bureau of Agricultural
  Production, December 2007, shiryo-2, p.28, citing Japan's GHG Inventory
  Report). The 2019 CO2-only evaluation is a **retreat from the ministry's
  own earlier framework**, not a methodological limitation.

**Implementation consequence.** The §7.4/§7.5 break-evens ask whether
conversion raises GHG *permanently*, so `ghg_at()` is evaluated on the flow
components only (`dN2O + dN2Ogm + dCH4`). At equilibrium the sink is
identically zero, so this is not a convenience: it **is** the equilibrium
value of the same object. Evaluating on `GHGnet` instead makes `uniroot`
fail, because with a −312 sink the sign never changes over the search range.

## N23 — Part B is the equilibrium frame, and needs no reservoir

Part B carries no SOC reservoir. This is deliberate, not an omission. The
allocation question is *which land is organic permanently*, and at equilibrium
the sink is identically zero, so Part B's `dGHG` **is** the permanent annual
change. Label the axis "Permanent annual GHG change", not "2050".

Practical note: `mk_initial()` therefore takes `soc = TRUE/FALSE`, because
`sfcr_baseline()` errors when handed initial values for variables absent from
the equation set.

Adding the reservoir to Part B would also make the trade-off figure
misleading: total organic area is fixed at 25% in every allocation, so the
sink shifts all five points left by nearly the same amount and every
allocation appears to reduce GHG at 2050.

## N24 — `Fbar` is an index, `Fbar_kgN` is a rate

`Fbar_v = 100` is a normalisation index; the physical quantity is
`Fbar_kgN_v = 96` kgN/ha (Toriyama 2002, Table 3). Anything that converts
nitrogen into carbon, area or emissions must use the physical one.

This is not hypothetical. The first implementation of `iota_gm` used
`Fbar_v`, producing a 100/96 = 1.041667 systematic error that inflated the
2050 soil-carbon sink from 312.68 to 327.16 and moved the crossover from
2070.1 to 2071.2. It was caught only by the standing R-vs-Python
cross-check — the R run alone was internally consistent and looked fine.
`ch4_route_A`, `nu_O_band` and `iota_gm` now all reference `Fbar_kgN_v`, and
the derived-aggregates block prints the green-manure carbon input in kgC/ha
so the units are auditable at run time.

Two lessons worth keeping: normalisations should be named so they cannot be
mistaken for measurements, and the Python cross-check earns its cost on
exactly this class of error, which no internal consistency test can find.

## N25 — Residue loss is crop-specific, and Japanese rice straw is incorporated

Organic conversion adds green-manure carbon but also **loses** residue carbon,
because the yield penalty shrinks the crop's own residue. Two things had to be
fixed here.

### (a) The loss is crop-specific

The first implementation applied a single `iota`, net of a **rice** residue
loss, to *both* reservoir pools. The upland pool — vegetables, fruit and other
crops — was therefore charged with paddy rice's residue loss. Vegetables have
no rice straw; this was simply wrong. It shrank the sink on 48.5% of the
converted area, which brings the crossover **earlier**, i.e. it favoured this
paper's own conclusion. Corrected:

```
PADDY   Shirato & Yokozawa (2005) Tab.2, NPK+straw plots, n=4:
        roots+stubbles 0.7125 + rice straw 1.8125 tC/ha/yr
        MAFF H18 crop year (9,049 kt straw): 75.9% incorporated
        returned C = 0.7125 + 0.759 x 1.8125 = 2.0882
        resid_loss_paddy = 0.28 x 2.0882 = 0.5847 tC/ha/yr

UPLAND  Ogawa, Takeuchi & Katayama (1988), the same source Shirato uses for
        the paddy residue split: average crop residue production in Hokkaido
        2 t DM/ha; at 40% C = 0.80 tC/ha/yr
        (1 - psi) area-weighted over veg/fruit/other = 0.250862
        resid_loss_upland = 0.250862 x 0.80 = 0.2007 tC/ha/yr
```

The upland loss is 34.3% of the paddy loss, which is the expected direction:
Ogawa reports stubble and root dry matter of only 0.01–0.07 t/ha for carrots,
Chinese cabbage and cabbage, and IPCC (2006) Table 5.5 classifies vegetables
as a *low residue* crop.

Effect on the headline dates:

```
resid_p  resid_u   dGHG2050    annual cross  cumulative
 0.5847   0.5847   -1.039 Mt       2063.8       2100    WRONG (rice loss on both)
 0.5847   0.2007   -1.390 Mt       2067.5       2112    CORRECT
 0.5847   0.0000   -1.574 Mt       2069.4       2118    upland loss = 0 (bound)
phi = 29/45, corrected: -1.006 Mt, crossover 2070.9, cumulative 2126
```

⚠️ Caveats on the upland figure, all to be stated: Ogawa's survey is
**Hokkaido**, whose crop mix (potato, sugarbeet, maize, beans) differs from the
national vegetable and fruit mix; it contains **no orchard crops** at all; and
"2 t DM/ha" is residue *production*, some of which is removed for composting.
Setting the upland loss to zero moves the crossover only 1.9 years, so the
result does not hinge on it.

### (b) Rice straw is incorporated, not removed

The retired value 0.196 corresponds to `0.28 x 0.70`, i.e. roots and stubbles
only — it implicitly assumed straw removal. MAFF's straw utilisation table for
the H18 crop year (production 9,049 kt) gives: feed 10.3%, bedding 4.0%,
compost 6.4%, processing 0.7%, burning 2.7%, **incorporation and other 75.9%**.
Removal is the minority practice.

Only the H18 table gives a full breakdown. The R6 (2024) briefing reports
national straw arising of 7,718 kt with 636 kt to feed, i.e. **8.24%** against
10.3% in 2006, and states that non-feed uses are "mainly bedding, compost and
incorporation". Holding the non-feed composition fixed implies an incorporation
share of 77.7%. The structure is stable, and the adopted 0.759 is the
directly measured value; using the 2024-implied 0.777 would *raise* the residue
loss and bring the crossover forward, so 0.759 is also the more conservative
of the two. Note the composting share (6.4%) and bedding share (4.0%) do return
carbon to farmland eventually, but via livestock and to other fields, so
counting them here would double-count against the organic amendment channel.

Bounds on the paddy side: with **no** residue loss the crossover is 2072.7;
with **all** straw incorporated (100% rather than 75.9%) it is 2061.5.
