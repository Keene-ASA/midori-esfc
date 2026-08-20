# Japan's Midori Food System Strategy in an Ecological Stock-Flow Consistent Framework

Replication code for a master's thesis (University of Hohenheim, 2026)
evaluating two KPIs of Japan's **Midori Food System Strategy** (みどりの食料
システム戦略, adopted 2021) in a stock-flow consistent (SFC) macroeconomic
model with a mass-conserving soil-carbon reservoir and an emissions satellite:

- **KPI(6)**: reduce chemical fertilizer use by 30% by 2050 (0.90 → 0.63 Mt,
  national tonnage)
- **KPI(7)**: expand organic farmland to 25% of farmland (1 Mha) by 2050

**Two headline questions.**

*Economy.* What does organic conversion do to Japan's current account? The
model isolates the *conversion effect* as the difference between S1
(fertilizer cut only) and S2 (fertilizer cut + organic conversion), and traces
how yield penalties on converted land raise food imports by more than
fertilizer-import savings reduce them, with the resulting deficit
self-amplifying through interest on the net foreign asset position.

*Atmosphere.* Does organic conversion raise or lower agricultural emissions?
Neither, unconditionally — **the sign is a function of the evaluation date.**
Soil carbon is a *stock adjustment*: the reservoir fills, approaches a new
equilibrium, and the annual gain goes to zero. Paddy CH4 and green-manure N2O
are *flows*: they persist for as long as the land stays organic. The annual
balance is negative while the soil is filling and permanently positive once it
is full. MAFF's official evaluation applies a **constant** 0.93 tCO2/ha/yr
sequestration rate, which nets a stock adjustment against a flow — an
operation SFC accounting does not permit, and which a single-period LCA or a
Tier-1 inventory cannot detect. See `MODEL_NOTES.md` N22.

The model is designated **E-SFC** on the strength of the two-pool soil-carbon
reservoir (mass balance: input = decomposition + ΔSOC), not on the strength of
an ecology → economy feedback. That feedback is deliberately left open; the
reason is quantified rather than asserted (N22, and the exclusion rows in the
ledger). Soil carbon enters the emissions satellite only, one-way.

## Repository contents

| File | Description |
|---|---|
| `R/esfc_midori_20260817.R` | The full model: aggregate core (Part A), 4-crop decomposition (Part B), scenarios, sensitivity and robustness checks, and three figures. |
| `python/verify_20260819.py` | Independent closed-form Python re-derivation of the GHG/SOC satellite (shares no numerical machinery with R). |
| `docs/MODEL_NOTES.md` | Design rationale and interpretation notes, referenced from the code as `[N01]`–`[N25]`. Read this alongside the code. |
| `calibration/CALIB_MASTER_20260819.csv` | Frozen calibration ledger: every parameter with value, provenance tag, source, and notes (270 entries). |
| `calibration/MERGE_REPORT_20260819.md` | Report of the 2026-08-19 ledger merge. |
| `calibration/CALIB_CHANGELOG_20260817.md` | Changelog of the calibration ledger. |
| `docs/HANDOFF_2026-08-19.md` | Implementation close-out and handoff notes for the writing phase. |
| `raw_data/` | Frozen source extracts (FAOSTAT, MAFF, SNA, GIO) used to populate the ledger. |
| `figures/` | Output directory for figures (generated files are gitignored). |

## Requirements

- R (>= 4.1)
- Packages: [`sfcr`](https://github.com/joaomacalos/sfcr), `tidyverse`,
  `ggrepel`
- Python 3 (for the independent verification script only; no external packages required)

```r
install.packages(c("sfcr", "tidyverse", "ggrepel"))
```

## Running

Run the independent closed-form Python verification **first**, then the R model.
The two implementations share no numerical machinery (R uses a Broyden solver;
Python is pure closed-form arithmetic from the R source specification).

```bash
python python/verify_20260819.py
```

```r
source("R/esfc_midori_20260817.R")
```

The R script is a single top-to-bottom run (a few minutes; the sensitivity
sweeps re-solve the model repeatedly). It prints:

1. Derived aggregates and the closed-form stationary closure
2. BAU verification (stationarity, the hidden Walras check, and that the
   soil-carbon reservoir is identically zero in BAU)
3. Headline results at 2050 (S1, S2, conversion effect; CAB, NFA, GHG with its
   four components)
4. The transient-stock-versus-permanent-flow block: annual and cumulative
   crossover years, and the permanent equilibrium value
5. Sensitivity and robustness (7.1–7.8), including break-even values for the
   organic yield ratio and the CH4 uplift
6. Part B: five conversion-allocation strategies that all satisfy the 25%
   area target, a CAB–GHG frontier, and consistency/dominance tests

and writes three figures to the working directory:

- `fig_core_headline.png` — CAB, NFA, government balance, and net GHG
  deviations from BAU under S1 and S2
- `fig_soc_crossover.png` — the same policy under two accounting conventions:
  a mass-conserving reservoir with all three gases, and MAFF's constant-rate
  soil-CO2-only convention
- `fig_allocation_frontier.png` — the CAB–GHG trade-off across allocations of
  the same 25% organic area target

## Model in one paragraph

A stationary zero-growth baseline is calibrated in closed form to Japanese
data (2017–19 means; SNA, MoF IIP/BoP, MAFF agricultural statistics), with
crop output indexed to 100. Food demand is fixed at the baseline level and
imports absorb the residual between demand and domestic output, so a yield
penalty on organically converted land translates directly into higher food
imports (N06). The current account feeds the net foreign asset position, whose
deviation from baseline is financed at a marginal (JGB) rate — the snowball
channel that makes the framework genuinely stock-flow consistent. A two-pool
soil-carbon reservoir (paddy and upland, with decomposition rates derived from
published equilibrium pairs for Japanese long-term experiments) is written in
deviation form, so the initial stock cancels and never has to be pinned; its
CO2 flux joins synthetic-fertilizer N2O, green-manure N2O and organic-paddy
CH4 in an emissions satellite denominated in national inventory units. The
policy difference in the current account collapses analytically to a two-state
recursion governed by six parameters, all of them either official statistics
or swept (N18); all behavioural parameters are shown to be exactly invariant
to the policy difference (§7.8).

## What the model does not do

- **No ecology → economy feedback.** A SOC → yield channel is defensible for
  rice alone (Japanese paddy topsoil sits just below Ma et al.'s rice optimum)
  and unsupported for vegetables, fruit and upland crops. It is bounded
  exogenously instead: overturning the sign of the conversion effect would
  require organic rice to *out-yield* conventional rice. The quantitative
  reason for not endogenising it — Fixing the reporting depth at 0–30 m per Ma et al. (2023) reduces the
  stock-to-concentration conversion band to 0.10× the signal it must resolve,
  so coarseness is no longer the obstacle. Two other reasons are: the depth of
  the reservoir itself is unresolved (decomposition rates derive from
  plough-layer equilibrium pairs of 10–18 cm, against a 0–30 cm reporting
  convention), and Ma et al.'s relation has an optimum, so a single elasticity
  cannot be applied. — is recorded in the ledger.
- **No paddy CH4 mitigation channel** (mid-season drainage, AWD). Allocation
  results that favour sparing paddy land must be read with this in mind (N15).
- **No livestock feedback.** Livestock output is exogenous and policy-neutral,
  but retained so the agricultural aggregate matches the statistics.

## Provenance tags

Every parameter in the code and ledger carries a tag:

| Tag | Meaning |
|---|---|
| `JP-DATA` | Official Japanese statistics (MAFF, Cabinet Office, MoF, GIO, e-Stat) |
| `LIT` | Peer-reviewed literature, verified against the PDF |
| `DERIVED` | Reproducible calculation from tagged inputs |
| `NORM` | Normalisation / numéraire |
| `CALIB` | Set to reproduce an observed aggregate flow |
| `ASSUMED` | No source; each is either invariance-tested or an upper bound |
| `SWEPT` | Varied in sensitivity analysis |
| `BOUNDED` | Reported as an interval, no point claim |
| `INVARIANT` | Numerically shown not to affect the policy difference |

The 2026-08-19 ledger carries 14 `ASSUMED` entries, all of them either
invariance-tested to ~1e-13 or justified as upper bounds. **None of the six
parameters that determine the headline result** — `Fbar`, `pF`, `beta`,
`gamma`, `psi_bar`, `r_marg` — **is `ASSUMED`.**

## Verification

Every reported figure is reproduced by an independent closed-form Python
implementation that shares no numerical machinery with R's Broyden solver
(`python/verify_20260819.py`). This is not decoration: it is the only check
that caught two bugs. (1) A units error in which a fertilizer *index* (100)
was used where the physical rate (96 kgN/ha) was required [N24]. (2) A pool
inconsistency in which the paddy residue-loss factor was also applied to the
upland pool [N25]. Bug (2) was an error in the direction favourable to the
conclusion. The R run alone was internally consistent and looked correct.

## Status and citation

Code accompanying a master's thesis in preparation (University of Hohenheim,
submission 2026); a journal version is planned. Please contact the author
before citing.

## Data and code availability

This repository is currently **private**. It will be made public, and a Zenodo
DOI will be assigned, at the time of thesis submission or preprint release.
Intended licences: code under MIT; data under CC BY 4.0.
University pre-publication review requirements have not yet been confirmed.
