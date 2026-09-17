# MODEL_NOTES — design rationale for `sfc_midori.R`

The code refers to these notes as `[N01]`–`[N25]`. Every number quoted here is
printed by a full run of `sfc_midori.R` (see `results/run_log.txt`) or is
derived in the code comment that cites the note. Index units: 100 = base-period
crop output value; 1 index unit = 0.0579067 trillion JPY.

---

## N01 — BAU current account normalised to zero

The closure anchors the ratio of net foreign assets (NFA) to GDP to data and
sets the BAU current account to zero. This is a zero-growth normalisation, not
a statement about Japan's actual surplus. As a result, net exports outside
agriculture are negative (−232.37 index units): the trade block covers crops
only (fertiliser imports 8.29 + food imports 50.91), while primary income
covers the whole economy (284.20). The normalisation leaves every policy
difference unchanged. Figures therefore report deviations from BAU, not levels.

## N02 — `r_avg` is a net ratio; `r_marg` prices the deviation

`r_avg = primary income / NFA = 0.061921`. Both numerator and denominator are
net positions, so the ratio exceeds the yield on either gross assets or gross
liabilities, and it is not an interest rate. It reproduces BAU primary income
and nothing else. Section 7.3 of the script varies it from 0.02 to 0.10; the
conversion effect moves by at most 1.14e-13.

Interest on the deviation of NFA from BAU is charged at `r_marg = 0.02`, the
rate swept in Section 7.2 (0.005 to 0.062).

## N03 — The closure is re-solved for every behavioural parameter

`kappa0`, `tau` and GDP depend on the behavioural parameters. The invariance
test (Section 7.8) therefore rebuilds the closure with `make_world()` for each
perturbed parameter. Swapping one value without rebuilding would leave BAU
non-stationary, and the test would compare against a drifting baseline.

## N04 — Rice and the residual-import assumption

Imports close the food balance as a residual (N06). For rice this assumption
is weakest: Japanese rice imports are set by the WTO minimum-access commitment
rather than by the gap between demand and output. In BAU, rice imports are
3.30% of rice demand, against 33.7% for the four crops together.

## N05 — The fertiliser KPI is a national tonnage

The fertiliser KPI is a national total, and chemical nitrogen is applied only
on conventional land. The fertiliser rate on conventional land is therefore

```
Fint = (1 − pi_) * Fbar / (1 − a),   F = Fint * (1 − a) = (1 − pi_) * Fbar
```

With `a = 0` this reduces to S1. With `a = 0.25` the organic land already
removes 25 of the 30 percentage points, so conventional land cuts its rate by
only 6.67% (`Fint = 93.333`). The relative yield of conventional land in 2050
is 94.3% in S1 and 98.9% in S2. National fertiliser use is identical in S1 and
S2, so `dF = 0` exactly in the conversion effect.

In the four-crop block, `areaO` is computed before `Fint`.

## N06 — Fixed food demand and residual imports

Food demand is held at its base level `Dbar`, and imports cover the difference
between demand and domestic output:

```
IMfood = Dbar − YA
```

A fall in output raises food imports and worsens the current account. Writing
demand as proportional to output instead (`D = YA/(1 − m)`) would make imports
fall with output and the current account improve.

Holding demand fixed is supported by the price and income inelasticity of
Japanese food demand estimated with a Quadratic Almost Ideal Demand System
(Haijima, 2021, *Keizai Kenkyu* 72(2): 113–127, DOI 10.15057/71666).
Feuerbacher et al. (2018) use endogenous demand with Armington imports, which
is a different closure.

Two consequences follow. `Dbar` cancels from every policy difference, so the
results are unaffected by the path of demand, including population decline.
This holds as long as imports stay positive, which is far from binding for the
four crops together and closer for rice (N04).

## N07 — The greenhouse gas balance over time

S2 relative to BAU (Mt CO₂-eq per year):

```
2030          −0.326
2050          −1.445   (synthetic N2O −0.310, green-manure N2O +0.055,
                        paddy CH4 +1.514, soil carbon −2.705)
2069.1         0       annual balance rises above BAU
2118           0       cumulative balance rises above BAU
equilibrium   +1.260   once soil carbon accumulation has ceased
```

With green manure applied on 29/45 of converted land (`phi = 0.6444`): 2050
−1.042, annual crossing 2072.7, cumulative crossing 2134, equilibrium +0.702.

S1 on its own stays below BAU in every year: with `a = 0`,
`GHGnet = −1.033459 · pi_ < 0`.

Continuing the organic ramp after 2050 at its 2030–2050 slope delays the
annual crossing: to 2072.6 for a terminal share of 0.354 and to 2079.2 for
0.50 (Section 4-ter).

## N08 — Sensitivity design

Table 5 of the thesis carries three blocks, one per causal link: the organic
yield ratio (Section 7.1), the marginal interest rate (7.2) and the paddy
methane uplift (7.4). The remaining checks (7.3, 7.5–7.8) are reported in the
text and in Appendix C.

## N09 — The organic yield ratio band

The band uses coherent source states. The lower end is the adopted vector
(`psi_bar = 0.717319`). The upper end sets all four crops to the values of
de Ponti et al. (2012) at once (rice 0.94, vegetables 0.80, fruit 0.72, other
0.80; `psi_bar = 0.830436`). A vector assembled from the most favourable value
for each crop separately corresponds to no state reported by any source and is
not used.

The conversion effect turns into an improvement at `psi_bar = 0.804529`,
which lies 0.025907 below the upper end. At the upper end the conversion
effect is +0.8023 (+0.046 trillion JPY per year). de Ponti et al. (2012)
themselves caution that plot-level ratios overstate farm-level and regional
performance.

Raising rice alone would require `psi_rice = 1.010241`, above the upper limit
of a yield ratio.

`dGHG` does not depend on `psi_bar`: the ratio enters output and the price
premium only.

## N10 — Robustness of the greenhouse gas result

The permanent increase (N22) is tested on the paddy methane uplift, which
carries most of the uncertainty. The increase disappears only if the uplift
falls below the break-even:

```
green-manure N    uplift    break-even   margin
1.0417 (min)      0.7575    0.149845     5.06x
1.1927 (adopted)  0.8674    0.145822     5.95x
1.6562 (max)      1.2045    0.133477     9.02x
```

The adopted green-manure N₂O emission factor is the least favourable end of
its band: the two alternatives raise the margin to between 6.76x and 14.87x
(Section 7.5).

The paddy decomposition rate `k_paddy` (N20) moves the year of the annual
crossing. It does not change whether the crossing occurs, because the
equilibrium balance is independent of `k`.

## N11 — The conventional yield loss is bounded

The yield response `g(F)` is concave. With the zero-nitrogen yield fixed, the
largest possible loss at −30% nitrogen is the linear limit, 9.3605%. The
calibrated loss is 5.7060%, 61% of that limit. A larger conventional loss
would enlarge S1 and S2 alike; the conversion effect is measured as their
difference.

## N12 — Why the four-crop block exists

The organic KPI fixes how much land converts, not which land. Five
allocations that all meet the same 25% target differ 5.10-fold in their 2050
current-account effect relative to BAU (−2.981 to −15.208). MAFF's 2026 GX
acceleration plan names both the zoning of organic farmland (p.10) and the
conversion of paddy agriculture (p.15) as policy questions.

With every crop converted equally, the four-crop block reproduces the
aggregate model to 5.68e-14.

## N13 — Import value induced per hectare converted

`cost_c = w_c (1 − psi_c) / sA_c` is derived by the author from output-value
shares, area shares and yield ratios. At the adopted yield ratios:

```
other 0.1292 < rice 0.1619 < fruit 0.4776 < veg 0.8013
```

The ranking depends on the yield ratios. With all four crops at de Ponti et
al. (2012) values, rice becomes the cheapest crop. Raising `psi_rice` alone
moves rice to first place at a multiplier of 1.0785, above the bound of 1.05
used in Section 7.6-bis.

## N14 — Reading the allocation table

| Allocation | Rice | Veg. | Fruit | Other | ΔCAB vs BAU | ΔCAB vs S1 |
|---|---|---|---|---|---|---|
| Every crop equally | 0.250 | 0.250 | 0.250 | 0.250 | −7.307 | −2.701 |
| Other arable crops first | 0.133 | 0 | 0 | 0.750 | −2.981 | +1.625 |
| Vegetables and fruit first | 0.136 | 0.750 | 0.750 | 0 | −15.208 | −10.602 |
| Rice only | 0.481 | 0 | 0 | 0 | −3.731 | +0.874 |
| No rice | 0 | 0.079 | 0.750 | 0.750 | −6.053 | −1.447 |

Crop columns are the share of each crop's own area converted. S1 contains no
organic land, so a single S1 run serves all five rows.

"Vegetables and fruit first" still converts some rice: the 75% cap binds on
vegetables and fruit before the target is met, and rice takes the remainder.

Relative to S1, two opposite changes meet. Converted land loses output in
proportion to its output value and yield ratio. Conventional land gains output
because it keeps more fertiliser than in S1 (N05), and the gain is larger when
high-value crops remain conventional. Converting crops with low output value
per hectare, such as rice and other arable crops, makes the gain exceed the
loss.

`dGHG` in this table is the permanent annual change (N23).

## N15 — Paddy methane mitigation

The baseline specification has no paddy methane mitigation. From FY2025 the
direct payment scheme requires one methane countermeasure where compost or
green manure is applied to paddy. Section 7.4-bis maps each countermeasure
into an effective uplift `(1 + u)(1 − m) − 1`:

```
reduction  equilibrium dGHG   annual crossing
10%        +0.934
30%        +0.282             2107.7
34%        +0.151             2124.2
```

A reduction of 38.64% is needed to make the permanent change negative, above
the largest single measure (34%). The scheme covered 84,795 ha in FY2025,
about 2% of Japan's cropland, so applying a countermeasure to the whole
converted area is an upper bound on what the requirement can achieve.

## N16 — The allocation frontier

The frontier varies the rice share of the 25% target and fills the rest with
other arable crops first and then fruit. The current-account loss is smallest
at a rice share of 0.277312 (−2.981), which equals the analytic value
`1 − CAP · sA_other / A50`. Below that share, rice replaces fruit; above it,
rice replaces other arable crops, and the loss rises again. `dGHG` rises
linearly with the rice share, so the curvature comes from the current-account
side alone.

With `CAP = 0.50`, the "No rice" allocation cannot meet the target
(0.240 < 0.25).

## N17 — Caption notes for the frontier figure

"No rice" and "Rice only" are the two endpoints of the frontier (rice share 0
and 1). "Other arable crops first" is the frontier's turning point. These
three points are therefore not independent of the curve.

## N18 — What determines the conversion effect

For the difference S2 − S1 the model reduces to a two-state linear recursion:

```
dCAB = −pF · dF + dYA + r_marg · dNFA[−1]
dNFA = dNFA[−1] + dCAB
```

Agricultural exports and other net exports are exogenous, `IMfood = Dbar − YA`
removes `Dbar`, and output contains no capital term. With `dF = 0` (N05), the
2050 conversion effect of −2.7008 splits into lost output −2.1787 (80.7%) and
lost interest on NFA −0.5222 (19.3%). The split is an identity.

Six parameters determine the result: `Fbar`, `pF`, `beta`, `gamma`,
`psi_bar` and `r_marg`, together with the KPI paths and the unit conversion.
Every behavioural parameter moves the conversion effect by at most 1.14e-13
(Section 7.8).

## N19 — Carbon-to-nitrogen ratio of the green manure

The methane uplift converts the organic nitrogen input into a carbon input.
The nitrogen input is calibrated on Chinese milk vetch trials (Nakayama &
Yoshida, 2005; Nagumo et al., 2014), so the ratio is taken from the same
material: Nagumo et al. (2014) measure C 37.0% and N 2.17%, a C/N of 17.1.

```
green-manure C = 1.1927 × 96 kgN/ha × 17.1 = 1957.9 kgC/ha/yr
uplift (route A) = 0.09458 × 1957.9 / 213.5 = 0.8674
```

## N20 — The soil organic carbon reservoir

The reservoir is written as the deviation from BAU, `s = SOC − SOC_BAU`:

```
s_t = (1 − k) · s_{t−1} + i_t
```

The initial stock cancels, and BAU emissions stay exactly zero. The reservoir
does not feed back into output.

The decay rate `k` comes from published equilibrium pairs, where annual input
equals annual decomposition (`k = I_eq / SOC_eq`):

- **Upland.** Shirato, Hakamata & Taniyama (2004), Table 3, four Andosol
  sites, equilibrium inputs of the modified model: `k_upland = 0.033294`
  (turnover 30.0 years).
- **Paddy.** Shirato & Yokozawa (2005), Table 1, five sites: 0.116831 for the
  original model. Table 3 of the same paper fits the paddy decomposition
  factor; with equal summer and winter factors the best fit is 0.40. Hence
  `k_paddy = 0.40 × 0.116831 = 0.046733` (turnover 21.4 years). The
  neighbouring grid points 0.30 and 0.50 give `k` between 0.035049 and
  0.058416.

Andosols dominate Japanese upland, and their organic matter decomposes more
slowly, which is why `k_upland` is lower than `k_paddy`.

In 2050, S2 holds 9.496 MtC more soil carbon than BAU.

## N21 — Land base and the KPI denominator

The four crops occupy 2,824,246 ha in 2017–2019 (`A_ha = 28,242` ha per index
hectare). Because paddy CH₄ enters as a national total, the rice area implied
by the model must equal the measured one: 1,467,977 ha against 1,468,000 ha.
The 23 ha gap leaves every reported figure unchanged at the precision quoted.

The organic KPI defines 1,000,000 ha against 4.00 Mha of cropland, which
includes grassland outside this model. Applying 25% to the model's base
converts 706,050 ha, 70.6% of the KPI area. Placing the full 1,000,000 ha on
the four crops (`a = 0.354077`) enlarges the conversion effect by a factor of
1.58 (Section 7.9). The reported conversion effect is therefore a lower bound.

## N22 — A constant sequestration rate against emission flows

Soil carbon accumulation is a stock adjustment: the reservoir approaches a new
equilibrium and the annual gain falls to zero. Paddy CH₄ and green-manure N₂O
are flows that continue for as long as the land remains organic.

The direct payment scheme credits organic farming with a constant
1.04 tCO₂/ha/yr of soil carbon (second-period final evaluation, August 2024,
n = 237; carried into the third period unchanged). Applied to the same
policy:

```
                      2050          2100
scheme convention     −0.734        −0.734
this model            −1.445        +0.882
```

The first-period coefficient, 0.93, gives −0.657 in 2050 and is printed for
traceability only.

Two facts from the sources support recording the gases together. RothC does
not separate CH₄ from CO₂ in paddy soils (Shirato & Yokozawa, 2005). MAFF's
own 2007 assessment of soil management deducted paddy methane from the
sequestration gain.

Implementation: the break-evens in Sections 7.4 and 7.5 ask whether conversion
raises emissions permanently, so `ghg_at()` evaluates the flow components
only (`dN2O + dN2Ogm + dCH4`). At equilibrium the soil term is zero, so this
is the equilibrium value of the same balance.

## N23 — The four-crop block is an equilibrium frame

The four-crop block has no SOC reservoir. The allocation question concerns
which land stays organic permanently, and at equilibrium the soil term is
zero, so `dGHG` in the four-crop block is the permanent annual change. Adding
the reservoir would shift all five allocations by almost the same amount,
because total organic area is 25% in each.

`mk_initial()` takes `soc = TRUE/FALSE` because `sfcr_baseline()` rejects
initial values for variables absent from the equation set.

## N24 — `Fbar` is an index, `Fbar_kgN` is a rate

`Fbar_v = 100` is a normalisation; the physical rate is `Fbar_kgN_v = 96`
kgN/ha (Toriyama, 2002, Table 3). Every conversion of nitrogen into carbon,
area or emissions uses the physical rate. An earlier implementation used the
index in `iota_gm`, which inflated the carbon input by 100/96; an independent
recomputation of the results found the error, and it has been corrected. The
derived-aggregates block prints the carbon input in kgC/ha so the unit can be
checked at run time.

## N25 — Residue carbon lost to the yield penalty

Conversion adds green-manure carbon and also removes part of the crop's own
residue carbon, because organic yields are lower. The loss is computed
separately for each pool.

**Paddy.** Roots and stubbles 0.4700 tC/ha/yr: mean of the two winter-fallow
sites in Shirato & Yokozawa (2005), Table 2 (Toyama 0.45, Shimane 0.49); the
two sites with a winter cereal are excluded because their column includes
cereal residue. Rice straw 1.8125 tC/ha/yr (four sites). Share of straw
incorporated: 0.6252 (MAFF, FY2024 crop year, 3,930 of 6,286 kt).

```
(0.4700 + 0.6252 × 1.8125) × (1 − 0.720) = 0.4489 tC/ha/yr
```

**Upland.** Removable residue by crop in Hokkaido (Ogawa, Takeuchi &
Katayama, 1988, Table 15), excluding pasture, green-chop maize, green-chop oat
and rice: 1,400,594 t over 365,844 ha = 3.8284 t DM/ha, at 40% carbon, times
the area-weighted `(1 − psi)` of vegetables, fruit and other crops
(0.251792):

```
3.8284 × 0.40 × 0.251792 = 0.3856 tC/ha/yr
```

The upland figure comes from Hokkaido, whose crop mix differs from the
national one, and contains no orchard crops.
