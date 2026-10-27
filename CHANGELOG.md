# Changelog

## v1.0.2

Reporting release. No headline value changes.

- New Part C writes every number quoted in the thesis to `results/` from one
  run: `summary_2050.csv` (one row per metric, each labelled S1 vs BAU,
  S2 vs BAU or S2 - S1, with % of GDP or % of national paddy CH4 where
  relevant), `ghg_uplift_bounds.csv`, `ghg_countermeasures.csv`.
- Adds cumulative net GHG (2019-2050, 2019-2100), the first year in which the
  cumulative balance turns positive, the sign of the GHG balance at both ends
  of the methane-uplift band, and a back-of-envelope check of fixed demand
  against the own-price elasticity of Haijima (2021).
- `soc_extend()` takes the green-manure N2O scale `gm0` as an argument so the
  uplift bounds move N2O, soil carbon input and CH4 together.
- Part A: `phi` now scales green-manure N2O and paddy CH4 as it already did in
  `soc_extend()`. No effect at the central `phi = 1`.
- Figure 1 and Figure 3 axis labels state the comparison (vs BAU).
- Comment fix: period 0 is 2018, period 1 is 2019.

## v1.0.1

Fixed the paddy methane equation: the national paddy CH4 baseline
(`ghg_ch4_pad0`) was scaled by the cropland-wide ratio `sA_rice * LAo / LAbar`
instead of the paddy-only ratio `LAo / LAbar` (Part B: `a_rice`). This
affected five sites in `sfc_midori.R` — Part A's `dCH4`, the two CH4 terms
inside `soc_extend()`, `EMperm_ph` in Section 4, and Part B's `dCH4` — plus
the dependent Figure 2 breaks/labels and the removal of the stale "better on
both" annotation on Figure 3. The economic side (CAB, fiscal balance, NFA) is
unchanged; only GHG results are affected.

Headline GHG results, before -> after:

| Metric | v1.0.0 | v1.0.1 |
|---|---|---|
| 2050 dGHG (Mt CO2eq/yr) | -1.45 | -0.05 |
| Annual crossing year | 2069 | 2051 |
| Permanent (equilibrium) dGHG | +1.26 | +2.66 |
| Break-even ch4_uplift (adopted nu_O) | 0.146 | 0.076 |
| Reduction required to reverse sign | 38.6% | 42.4% |

`MODEL_NOTES.md` and `README.md` were updated throughout to match the
corrected run (headline values, sensitivity tables in Sections 7.4/7.4-bis,
and the surrounding explanatory text).

## v1.0.0

Initial release.
