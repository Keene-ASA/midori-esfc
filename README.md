# Assessment of Japan's MIDORI Food System Strategy: A Stock-Flow Consistent Model with Environmental Satellite Accounts

Replication code and calibration ledger for the master's thesis of the same title
(Asahi Kin, Ecological-Economic Policy Modelling Research Group 420D,
University of Hohenheim, 2026; supervisor Prof. Dr. Arnd Feuerbacher).

## What the model evaluates

The MIDORI Food System Strategy (みどりの食料システム戦略), adopted by Japan's
Ministry of Agriculture, Forestry and Fisheries (MAFF) in 2021, sets two
key performance indicators (KPIs) for farming practice. This repository
evaluates both:

- **Fertiliser KPI**: a 30% reduction in chemical fertiliser use by 2050,
  measured as a national tonnage (0.90 → 0.63 Mt).
- **Organic KPI**: organic farming on 25% of cropland (1 Mha) by 2050.

Three scenarios are simulated from 2018 to 2050: business as usual (BAU),
S1 (fertiliser KPI alone) and S2 (fertiliser KPI and organic KPI). The
difference S2 − S1 isolates the effect of converting farmland to organic
cultivation.

The model is an environmental stock-flow consistent (SFC) model. Four crops
(rice, vegetables, fruit, other arable crops) sit inside a closed set of
sectoral balance sheets and transaction flows. Nitrous oxide (N₂O), paddy
methane (CH₄) and a two-pool soil organic carbon (SOC) reservoir are recorded
in satellite accounts. The satellite is one-way: farming changes emissions,
and emissions do not feed back into production or the current account.

## Main results

- When every crop is converted in equal proportion, conversion worsens the
  2050 current account by 0.16 trillion JPY per year and the fiscal balance by
  0.11 trillion JPY per year.
- In 2050, greenhouse gas emissions under S2 are 1.45 Mt CO₂-eq per year below
  BAU. From 2069 onwards the annual balance lies above BAU, and once soil
  carbon accumulation has ceased the permanent increase is 1.26 Mt CO₂-eq per
  year.
- The direct payment scheme for environmentally friendly agriculture credits
  organic farming with a constant 1.04 tCO₂/ha/yr. Under that convention the
  same policy records −0.73 Mt CO₂-eq per year in both 2050 and 2100; this
  model records +0.88 Mt CO₂-eq per year in 2100.
- Relative to BAU, the 2050 current-account effect ranges from 0.17 to
  0.88 trillion JPY per year across five allocations of the same 25% area
  target (a 5.1-fold difference). Relative to S1, converting crops with low
  output value per hectare, such as rice, improves the current account.

## Repository contents

| Path | Content |
|---|---|
| `sfc_midori.R` | The complete model: calibration, equations, scenarios, sensitivity analyses and figures |
| `data/calibration_ledger.csv` | Every calibrated input with its value, unit, source and provenance tag |
| `MODEL_NOTES.md` | Design rationale referenced from the code as `[N01]`–`[N25]` |
| `results/run_log.txt` | Console output of a full run of `sfc_midori.R` |
| `figures/` | Figures written by the script |
| `LICENSE`, `LICENSE-DATA.md` | Licences (see below) |
| `CITATION.cff`, `.zenodo.json` | Citation metadata |

Figures and thesis numbering:

| File | Thesis |
|---|---|
| `figures/fig_core_headline.png` | Figure 1 |
| `figures/fig_soc_crossover.png` | Figure 2 |
| `figures/fig_allocation_frontier.png` | Figure 3 |

## How to run

```sh
Rscript sfc_midori.R > results/run_log.txt 2>&1
```

The script writes the three figures to `figures/` and prints every number
reported in the thesis. Where each block of output is used:

| Output block | Thesis |
|---|---|
| `0.`–`2.` derived aggregates, closure, BAU verification | Section 4, Section 5.1, Appendix A |
| `3.` headline, `3-bis` fiscal side, `3-ter` decomposition | Sections 5.2–5.4, Section 6.1 |
| `4.`, `4-ter` transient stock vs permanent flow | Section 5.5, Section 6.3 |
| `4-bis` scheme convention | Section 5.5, Figure 2 |
| `7.1`–`7.8` sensitivity and invariance | Section 5.7, Table 5 |
| `7.4-bis` scheme methane countermeasures | Appendix C.1, Table C1 |
| `7.6-bis` rice yield feedback bound | Section 5.7, Appendix C.2 |
| `7.9` full KPI area | Section 4.6 |
| `8.`–`11.` allocations and frontier | Section 5.6, Table 4, Figure 3 |

Tested with: R version 4.5.3 (2026-03-11 ucrt) ; sfcr 0.2.3 ; tidyverse 2.0.0 ; ggrepel 0.9.8

## Units

The model runs in index units: 100 equals the crop output value of the base
period (2017–2019 mean, 5.79 trillion JPY). One index unit is 0.0579067
trillion JPY (`unit_tn`). Emissions are in Mt CO₂-eq using the 100-year global
warming potentials of the IPCC Fifth Assessment Report (265 for N₂O, 28 for
CH₄), as applied in Japan's national greenhouse gas inventory.

## Calibration ledger

`data/calibration_ledger.csv` lists every calibrated input used by the script.
The `reading` column is a short Japanese label; the `source` column cites each
source in its original language. Primary statistics are publicly available
from e-Stat and MAFF and are cited row by row rather than redistributed.

| Tag | Meaning |
|---|---|
| `JP-DATA` | Official Japanese statistics |
| `LIT` | Peer-reviewed literature, checked against the original |
| `DERIVED` | Reproducible calculation from tagged inputs |
| `NORM` | Normalisation |
| `ASSUMED` | No source; each is either shown to be invariant or used as a bound |
| `SWEPT` | Varied in the sensitivity analysis |
| `BOUNDED` | Reported as an interval |
| `INVARIANT` | Shown numerically to leave the policy difference unchanged |

## Citation

Please cite the thesis and the archived release of this repository. The DOI
of each release is shown on its Zenodo record; `CITATION.cff` gives the
citation metadata.

## Licence

The code (`sfc_midori.R`) is released under the MIT Licence (`LICENSE`).
The calibration ledger, `MODEL_NOTES.md`, the run log and the figures are
released under Creative Commons Attribution 4.0 International
(`LICENSE-DATA.md`).
