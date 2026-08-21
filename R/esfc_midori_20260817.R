# =============================================================================
#  esfc_midori.R
#  Japan's Midori Food System Strategy in a stock-flow consistent framework
#  with environmental satellite accounts.
#
#  S1 = KPI(6) chemical fertilizer -30% by 2050
#  S2 = KPI(6) + KPI(7) organic area 25% by 2050
#  HEADLINE = S2 - S1, the conversion effect on the current account.
#
#  Ledger : CALIB_MASTER_20260817.csv
#
#
#  Tags: JP-DATA = official Japanese statistics | LIT = peer-reviewed, PDF
#  verified | DERIVED = reproducible calculation | NORM = normalisation
#  | ASSUMED = no source (every one is either invariance-tested or an upper
#  bound) | SWEPT = varied | BOUNDED = reported as an interval, no point claim
#  | INVARIANT = numerically shown not to touch the policy difference.
# =============================================================================

library(sfcr)
library(tidyverse)

# =============================================================================
# 1. TIME
# =============================================================================

YEAR0 <- 2018 # period 1; base year
TERM <- 2050 - YEAR0 # 32y; the strategy's target year
yr <- function(y) y - YEAR0
Y2022 <- yr(2022) # 4y; policy start (strategy adopted 2021)
Y2030 <- yr(2030) # 12y; intermediate KPI
Y2050 <- yr(2050) # 32y; terminal KPI

# =============================================================================
# 2. CROP-LEVEL PRIMARY DATA
# =============================================================================

# w_c: share of crop c in crop output VALUE [JP-DATA]
w_rice <- 0.3005 # (MAFF, Agricultural Production Income Statistics, 2017-19 three-year mean)
w_veg <- 0.3967 # (MAFF, Agricultural Production Income Statistics, 2017-19 three-year mean)
w_fruit <- 0.1447 # (MAFF, Agricultural Production Income Statistics, 2017-19 three-year mean)
w_other <- 0.1581 # (MAFF, Agricultural Production Income Statistics, 2017-19 three-year mean)

# sA_c: share of crop c in planted AREA [JP-DATA]
sA_rice <- 0.515 # (e-Stat, Statistics on Cultivated Land and Planted Area, 2017-19 mean)
sA_veg <- 0.163 # (e-Stat, Statistics on Cultivated Land and Planted Area, 2017-19 mean)
sA_fruit <- 0.074 # (e-Stat, Statistics on Cultivated Land and Planted Area, 2017-19 mean)
sA_other <- 0.248 # (e-Stat, Statistics on Cultivated Land and Planted Area, 2017-19 mean)

# m_c: import dependence = 1 - self-sufficiency (weight basis) [JP-DATA/INVARIANT]
m_rice <- 0.033 # (MAFF, commodity self-sufficiency rates, FY2017-19 mean)
m_veg <- 0.210 # (MAFF, commodity self-sufficiency rates, FY2017-19 mean)
m_fruit <- 0.613 # (MAFF, commodity self-sufficiency rates, FY2017-19 mean)
m_other <- 0.508 # (MAFF, commodity self-sufficiency rates, FY2017-19 mean)

# psi_c: organic / conventional yield ratio [SWEPT]
psi_rice <- 0.720 # Tottori Pref. Agric. Exp. Stn. (2011) [JP-DATA]
psi_veg <- 0.670 # Seufert et al. 2012 Fig 1a; [LIT]
psi_fruit <- 0.753 # de Ponti et al. 2012 Tab.1; strawberry n=5 excluded (vegetable inMAFF). (6*69+14*78)/20=0.753. [DERIVED]
psi_other <- 0.800 # Seufert et al. (2012), Fig. 3f developed countries: -20% [LIT]

# epsN_c: direct N2O emission factor per unit applied N, Akiyama, Yan & Yagi (2006). [LIT]
epsN_rice <- 0.0031 # Not a Japanese estimate: Japanese rice trials lack zero-N controls, so the authors recommend the world value. [LIT]
epsN_veg <- 0.0062 # Area-weighted mean from their Table 2. [LIT]
epsN_fruit <- 0.0062 # Area-weighted mean from their Table 2. [LIT]
epsN_other <- 0.0062 # Area-weighted mean from their Table 2. [LIT]

# prem_c: organic price premium at the PRODUCER stage. PREM loads on crop
# output value, so a retail-stage premium would be a stage mismatch. [N06]
#   [DERIVED] MAFF, 11th Third-Party Committee on the Direct Payment Scheme
#   for Environmentally Friendly Agriculture (2019-08-22), Table 4-1, organic
#   level / JAS-certified / "total" row. Interval midpoints; the open top
#   class is taken at its lower bound 2.0 (conservative).
prem_rice <- 0.393 # rice, n=172
prem_veg <- 0.266 # non-rice, n=111
prem_fruit <- 0.266 # non-rice (the survey does not disaggregate below this)
prem_other <- 0.266 # non-rice (the survey does not disaggregate below this)

# Crop vs livestock shares of agricultural output [JP-DATA]
# Do not sum to 1 (0.65% residual = processed products)
# Livestock is exogenous and policy-neutral but is KEPT
share_crop <- 0.6359 # (MAFF, Agricultural Production Income Statistics, 2017-19 three-year mean)
share_livestock <- 0.3576 # (MAFF, Agricultural Production Income Statistics, 2017-19 three-year mean)


# =============================================================================
# 3. MACRO AND EXTERNAL ANCHORS
# =============================================================================
# Cabinet Office, SNA2024 (2020 base, 2008SNA), main series table (1), nominal, calendar years 2017-19. [JP-DATA]
nominal_GDP <- mean(c(565.1190, 569.1535, 571.8380)) # 568.7035 tn JPY
CONS_HH <- mean(c(294.3982, 296.9732, 296.4464)) # 295.9393 tn JPY
GOV_CONS <- mean(c(107.3042, 108.7364, 111.1948)) # 109.0785 tn JPY

# MAFF, Agricultural Production Income Statistics, national estimates.
CROP_OUT <- mean(c(5.9605, 5.7815, 5.6300)) # 5.790667; 100 index = this

# Ministry of Finance IIP / Balance of Payments statistics 2017-19. Both cancel from the policy difference.
NFA_pct <- 0.6067 # net foreign assets / GDP        [JP-DATA/INVARIANT]
primary_pct <- 0.037301 # primary income balance / GDP    [JP-DATA/INVARIANT]

# Agri-food exports / GDP. MAFF trade summary (MoF Trade Statistics basis), 2017-19.
# Agricultural products only: forestry (0.0367) and fishery (0.2884 tn JPY) excluded to match IMfood [JP-DATA]
Xag_pct <- mean(c(0.4966, 0.5661, 0.5878)) / nominal_GDP # 0.0009674051

# =============================================================================
# 4. STRUCTURAL PARAMETERS
# =============================================================================

Fbar_v <- 100 # baseline fertilizer N, INDEX [NORM]
Fbar_kgN_v <- 96 # the same quantity in PHYSICAL units, kgN/ha (Toriyama 2002, Tab.3) [JP-DATA]
# Fbar_v is an index and Fbar_kgN_v is a physical rate. Anything that converts
# nitrogen into carbon, area or emissions must use Fbar_kgN_v. [N24]
pF_v <- 0.08286 # fertilizer cost / crop revenue = 420k/5069k JPY(MAFF 2019, single year) [JP-DATA]
LAbar_v <- 100 # farmland area fixed [NORM]
w_v <- 1 # wage rate [NORM]
prN_v <- 1 # non-agri labour productivity [NORM]

# -- Mitscherlich fertilizer response  g(F) = 1 - beta*exp(-gamma*F) ----------
m0_v <- 355 / 516 # 0.687984  zero-N relative yield. (Toriyama, 2002, Table 3) [LIT/QUASI-INVARIANT]
m70_v <- 0.942940 # relative yield at -30% N. (Li et al., 2017, Fig. 1a) [LIT]
beta_v <- 0.388821 # solved jointly from (m0_v, m70_v) [DERIVED]
gamma_v <- 0.012479 # just identified [DERIVED]

# -- Behavioural block. All ASSUMED, all INVARIANT to 15 digits (7.8).
c1_v <- 0.7
c2_v <- 0.05 # C = c1*YD + c2*V[-1]
kappa1_v <- 0.2
kappa2_v <- 2.0
kappa3_v <- 0.5 # accelerator / profit / subsidy
zeta_v <- 0.05 # depreciation
ellA_v <- 0.3 # agri labour per unit land
Ga_v <- 10 # government purchases of agri goods
kN_v <- 2.4 # non-agri capital-output ratio [ASSUMED/INVARIANT]
r_B_v <- 0.02 # effective rate reproducing the SNA general-government interest
# bill given the model's residual B; NOT a market JGB yield [CALIB]

# -- Emissions satellite (GIO inventory units; one-way) ----------------------
ghg_n2o_syn0_v <- 103.3459 # BAU synthetic-fert N2O, 10kt-CO2 (GIO 2026, Tab.5-50 3.D.1.1, 2017-19 mean) [JP-DATA]
ghg_ch4_pad0_v <- 1343.4926 # BAU paddy CH4,        10kt-CO2 (GIO 2026, Tab.5-43 3.C.,   2017-19 mean) [JP-DATA]
epsN_gm_v <- 0.0031 # green-manure N2O EF = paddy EF [ASSUMED, upper bound; Xie et al. 2016 measure 0.195%]
nu_O_v <- 1.1927083333 # TOTAL N; Median of the six measured values(Nakayama&Yoshida2005, Nannun2014)  [LIT/BOUNDED]
nu_O_band <- c(100, 159) / Fbar_kgN_v # [1.0417, 1.6563] field min-max, kgN/ha / 96
# C/N of the incorporated green manure. 17.1 is the MEASURED value for the
# Chinese milk vetch used in the very trials that calibrate nu_O (Nagumo et al.
# 2014: C 37.0%, N 2.17%). The retired 13.0 was Katayanagi et al.'s own COMPOST
# assumption and did not describe this model's organic N flow. [N19]
CN_gm_v <- 17.1 # [LIT]
ch4_uplift_v <- 0.8673672646 # organic paddy CH4 uplift, route A (Katayanagi et al. 2016) [DERIVED/BOUNDED]

ch4_route_A <- function(nu, cn = CN_gm_v) {
  0.09458 * (nu * Fbar_kgN_v * cn) / 213.5 # 7.4 sweeps this jointly with nu_O
}

# -- Soil organic carbon reservoir (two pools, DEVIATION form) ---------------
# s = SOC - SOC_BAU, so the initial stock cancels and never has to be pinned.
# k comes from PUBLISHED EQUILIBRIUM PAIRS (input = k*SOC at steady state),
# not from RothC internals. [N20]
k_paddy_v <- 0.046733 # Shirato & Yokozawa (2005) Tab.1, seasonal factor 0.40 [DERIVED]
k_upland_v <- 0.033294 # Shirato, Hakamata & Taniyama (2004) Tab.3, modified model [DERIVED]
# Residue C lost to the yield penalty. CROP-SPECIFIC: a rice residue loss must
# not be charged to upland land. [N25]
#  PADDY  Shirato & Yokozawa (2005) Tab.2, NPK+straw plots (n=4): roots+stubbles
#    0.7125 and rice straw 1.8125 tC/ha/yr. MAFF (H18 crop year, 9,049 kt straw)
#    reports 75.9% going to incorporation, so returned C = 0.7125 +
#    0.759*1.8125 = 2.0882, times (1 - psi_rice) = 0.28.
#  UPLAND Ogawa, Takeuchi & Katayama (1988) - the same source Shirato uses for
#    the paddy residue split - report average crop residue production in
#    Hokkaido of 2 t DM/ha; at 40% C that is 0.80 tC/ha/yr. Times (1 - psi)
#    area-weighted over veg/fruit/other = 0.250862.
resid_loss_paddy_v <- 0.5847 # tC/ha/yr [DERIVED]
resid_loss_upland_v <- 0.2007 # tC/ha/yr [DERIVED]
phi_v <- 1.0 # share of converted land applying green manure [SWEPT; MAFF 2019 Tab.3-4 = 29/45]
A_ha_v <- 28544 # ha per index-ha. sA_rice*LAbar == Japan's rice area by
# construction of ghg_ch4_pad0: 1.47 Mha / 0.515 = 2.8544 Mha. [DERIVED] [N21]

# -- Policy KPI ramps(Midori Food System Strategy targets. [JP-DATA]) ---------
PI30 <- 0.20
PI50 <- 0.30 # KPI(6): chemical fertilizer 0.90 -> 0.72 -> 0.63 Mt (national tonnage)
A30 <- 0.01575
A50 <- 0.25 # KPI(7): organic area 63 kha (2030) -> 1 Mha = 25% (2050)
CAP <- 0.75 # max share of one crop's own area that may convert [ASSUMED]


# =============================================================================
# 5. DERIVED AGGREGATES
# =============================================================================
psi_bar_v <- w_rice * psi_rice + w_veg * psi_veg + w_fruit * psi_fruit + w_other * psi_other
Dbar_v <- 100 * (w_rice / (1 - m_rice) + w_veg / (1 - m_veg) +
                   w_fruit / (1 - m_fruit) + w_other / (1 - m_other))
IM_star <- Dbar_v - 100
epsN_bar_v <- sA_rice * epsN_rice + sA_veg * epsN_veg + # AREA weighted:
  sA_fruit * epsN_fruit + sA_other * epsN_other # a physical flow
prem_bar_v <- (w_rice * psi_rice * prem_rice + w_veg * psi_veg * prem_veg +
                 w_fruit * psi_fruit * prem_fruit + w_other * psi_other * prem_other) / psi_bar_v
g_bau_v <- 1 - beta_v * exp(-gamma_v * Fbar_v)
lam0_v <- 1 / g_bau_v
unit_tn <- CROP_OUT / 100 # tn JPY per index unit

# Unit bridge: an EF-based BAU synthetic N2O equals ghg_n2o_syn0 by construction.
ghg_n2o_gm0_v <- epsN_gm_v * nu_O_v * LAbar_v * (ghg_n2o_syn0_v / (epsN_bar_v * Fbar_v))

# Green-manure C input and its unit bridge into the emission satellite.
iota_gm_v <- nu_O_v * Fbar_kgN_v * CN_gm_v / 1000 # 1.957950 tC/ha/yr gross
iota_paddy_v <- iota_gm_v - resid_loss_paddy_v # 1.373257 tC/ha/yr
iota_upland_v <- iota_gm_v - resid_loss_upland_v # 1.757250 tC/ha/yr
gamma_soc_v <- A_ha_v * (44 / 12) / 1e4 # index-ha-tC/yr -> 10 kt-CO2eq

# psi_bar band uses coherent source states, not per-crop cherry-picking.
# upper endpoint = all four crops at de Ponti et al. (2012) values [N09]
psi_dePonti <- c(rice = 0.94, veg = 0.80, fruit = 0.72, other = 0.80)
psi_bar_LO <- psi_bar_v # the baseline IS the lower end
psi_bar_HI <- w_rice * psi_dePonti[["rice"]] + w_veg * psi_dePonti[["veg"]] +
  w_fruit * psi_dePonti[["fruit"]] + w_other * psi_dePonti[["other"]]

r_avg_v <- primary_pct / NFA_pct # 0.061482. NOT a market rate [N02]
r_marg_v <- 0.02 # 10-yr JGB / BoJ neutral-rate proxy [LIT/SWEPT]
r_marg_band <- c(0.005, 0.02, 0.0285, 0.04, r_avg_v) # 0.0285 = 10y JGB, Aug 2026

cat("=== 0. derived aggregates ===\n")
cat(sprintf(
  "  psi_bar   %.6f  band [%.6f, %.6f]\n",
  psi_bar_v, psi_bar_LO, psi_bar_HI
))
cat(sprintf(
  "  Dbar      %.6f   IM* %.6f (%.1f%% of demand)\n",
  Dbar_v, IM_star, 100 * IM_star / Dbar_v
))
cat(sprintf("  epsN_bar  %.8f   prem_bar %.6f\n", epsN_bar_v, prem_bar_v))
cat(sprintf("  g(Fbar)   %.8f   lam0 %.8f\n", g_bau_v, lam0_v))
cat(sprintf(
  "  nu_O      %.7f  band [%.5f, %.5f]      ch4_uplift %.7f\n",
  nu_O_v, nu_O_band[1], nu_O_band[2], ch4_uplift_v
))
cat(sprintf("  ghg_n2o_gm0 %.6f\n", ghg_n2o_gm0_v))
cat(sprintf(
  "  green-manure C %.1f kgC/ha  iota: gross %.6f | paddy %.6f | upland %.6f\n",
  iota_gm_v * 1000, iota_gm_v, iota_paddy_v, iota_upland_v
))
cat(sprintf("  gamma_soc %.6f  A_ha %d\n", gamma_soc_v, A_ha_v))
cat(sprintf("  unit_tn   %.10f tn JPY per index unit\n", unit_tn))


# =============================================================================
# 6. CLOSED-FORM STATIONARY CLOSURE
#   NFA*/GDP anchored to data, CAB normalised to 0 (a zero-growth
#   normalisation, not a claim about Japan) -> net exports come out negative;
#   see [N01]. r_avg is a NET ratio, not a market rate; see [N02].
#   The closure is a FUNCTION of the behavioural block because 7.8's
#   invariance test must re-solve it; see [N03].
# =============================================================================

make_world <- function(c1 = c1_v, c2 = c2_v, kappa2 = kappa2_v, zeta = zeta_v,
                       ellA = ellA_v, Ga = Ga_v, kN = kN_v, ravg = r_avg_v) {
  YL <- 100 * share_livestock / share_crop # livestock output, exogenous
  WL <- 0.30 * YL
  PiL <- 0.70 * YL # split ASSUMED, dCAB-neutral
  Cf_s <- Dbar_v - Ga + YL
  C_s <- 100 * CONS_HH / CROP_OUT
  Gn <- 100 * GOV_CONS / CROP_OUT - Ga
  V_s <- (1 - c1) * C_s / c2 # from C = c1*YD + c2*V[-1]
  aa <- 1 - zeta * kN
  PFIM <- pF_v * Fbar_v + IM_star # total imports at BAU
  K0 <- (C_s - Cf_s) + zeta * 100 + Gn
  ip <- ravg * NFA_pct
  GDP <- (K0 + PFIM + aa * (100 + YL)) / (aa + ip)
  YN <- GDP - 100 - YL
  KN <- kN * YN
  NFA <- NFA_pct * GDP
  INF <- ip * GDP
  Xag <- Xag_pct * GDP
  Xm <- PFIM - INF
  WAs <- w_v * ellA * LAbar_v
  PiAs <- 100 - WAs - pF_v * Fbar_v - zeta * 100
  WPi <- (WAs + PiAs) + (WL + PiL) + zeta * 100 + Gn + Xm + (C_s - Cf_s)
  B <- V_s - 100 - KN - NFA
  list(
    r_avg = ravg, GDP = GDP, YN = YN, KNbar = KN, NFA = NFA, INF = INF,
    X_ag = Xag, X = Xm, NX_other = Xm - Xag, B = B,
    tau = (Ga + Gn + r_B_v * B) / WPi,
    kappa0 = zeta * 100 - kappa2 * (100 - WAs - pF_v * Fbar_v - zeta * 100) / 100,
    WA = WAs, YL = YL, WL = WL, PiL = PiL, Ga = Ga, Gn = Gn,
    c1 = c1, c2 = c2, kappa2 = kappa2, zeta = zeta
  )
}
W <- make_world()
cat("\n=== 1. closure ===\n")
print(unlist(W[c("GDP", "YN", "KNbar", "NFA", "INF", "X_ag", "X", "NX_other", "B", "tau", "kappa0")]))

crops <- c("rice", "veg", "fruit", "other")
w_c <- c(rice = w_rice, veg = w_veg, fruit = w_fruit, other = w_other)
sA_c <- c(rice = sA_rice, veg = sA_veg, fruit = sA_fruit, other = sA_other)
psi_c <- c(rice = psi_rice, veg = psi_veg, fruit = psi_fruit, other = psi_other)

# Rice zero-import corner: the residual-import assumption is structurally weakest for rice (WTO minimum access) [N04]
cat(sprintf(
  "\nRice corner: Dbar %.4f  YA %.4f  gap %.4f (%.2f%% of demand)\n",
  100 * w_rice / (1 - m_rice), 100 * w_rice,
  100 * w_rice / (1 - m_rice) - 100 * w_rice,
  100 * (100 * w_rice / (1 - m_rice) - 100 * w_rice) / (100 * w_rice / (1 - m_rice))
))


# #################### PART A - AGGREGATE CORE ####################

# =============================================================================
# 7A. EQUATIONS (34 endogenous + hidden Walras check Vh)
# =============================================================================
eqs <- sfcr_set(
  # KPI(6) is a NATIONAL TOTAL (-30% tonnage), so the intensity on conventional land scales by 1/(1-a). 
  # At a = 0 this collapses to the old spec: S1 is unchanged. [N05]
  Fint ~ (1 - pi_) * Fbar / (1 - a),
  F ~ Fint * (1 - a),                      # = (1-pi_)*Fbar, national total
  gC ~ 1 - beta * exp(-gamma * Fint),
  YAcrop ~ lam0 * gC * LAbar,
  YAcropO ~ lam0 * gfull * LAbar,          # organic anchored at g(Fbar): no synthetic N, so psi alone carries the penalty
  YA ~ (1 - a) * YAcrop + a * psi_bar * YAcropO,
  # -- satellite (one-way) ----------------------------------------------------
  LAo ~ a * LAbar,
  dN2O ~ ghg_n2o_syn0 * (F / Fbar - 1),
  dN2Ogm ~ ghg_n2o_gm0 * (LAo / LAbar),
  dCH4 ~ ghg_ch4_pad0 * (sA_rice * LAo / LAbar) * ch4_uplift,
  # Two-pool SOC reservoir, deviation form: identically zero in BAU, so GHGnet
  # stays exactly zero there. One-way - SOC never re-enters YA. [N20]
  SOCp ~ SOCp[-1] + phi * iota_paddy * (sA_rice * LAo) - k_paddy * SOCp[-1],
  SOCu ~ SOCu[-1] + phi * iota_upland * ((1 - sA_rice) * LAo) - k_upland * SOCu[-1],
  dSOC ~ (SOCp - SOCp[-1]) + (SOCu - SOCu[-1]),
  dCO2soc ~ -gamma_soc * dSOC, # a removal enters with a negative sign
  GHGnet ~ dN2O + dN2Ogm + dCH4 + dCO2soc,
  PREM ~ prem_bar * (a * psi_bar * YAcropO) * prem_on, # CAB-neutral
  # -- investment / capital ---------------------------------------------------
  rA ~ (YA - WA - pF * F - zeta * KA[-1]) / KA[-1],
  IA ~ kappa0 + kappa1 * ((YA - YA[-1]) / KA[-1]) + kappa2 * rA + kappa3 * Sub_I,
  KA ~ KA[-1] + IA - zeta * KA[-1],
  IN_ ~ zeta * KNbar,
  YN ~ Cn + IA + IN_ + Gn + X,
  WN ~ w * YN / prN,
  # -- FIXED-DEMAND / RESIDUAL-IMPORT CLOSURE ----------------------------------
  # Demand is fixed at Dbar and imports absorb the residual. [N06]
  IMfood ~ Dbar - YA,
  Cf ~ YA + IMfood - Ga + YL + PREM,
  PiA ~ YA - WA - pF * F - zeta * KA[-1] + Sub_I + PREM,
  PiN ~ YN - WN - zeta * KNbar,
  W_ ~ WA + WN + WL,
  Pi ~ PiA + PiN + PiL,
  TX ~ tau * (W_ + Pi),
  # Baseline stock at r_avg (data-matching), deviation at r_marg (JGB). [N02]
  INF ~ r_avg * NFA_star + r_marg * (NFA[-1] - NFA_star),
  INB ~ r_B * B[-1],
  YD ~ W_ + Pi - TX + INF + INB,
  C ~ c1 * YD + c2 * V[-1],
  Cn ~ C - Cf,
  CAB ~ X_ag - pF * F - IMfood + NX_other + INF,
  NFA ~ NFA[-1] + CAB,
  B ~ B[-1] + (Ga + Gn + Sub_I + INB - TX),
  V ~ KA + KNbar + B + NFA,
  Vh ~ Vh[-1] + (YD - C) # hidden: must track V to machine precision
)

# sfcr evaluates formulas lazily, so `tau ~ wld$tau` fails at solve time. Splice literal numbers in (17 digits = lossless).
sfcr_set_from <- function(v) {
  eval(parse(text = paste0(
    "sfcr_set(",
    paste(names(v), "~", sprintf("%.17g", v), collapse = ", "), ")"
  )))
}

mk_ext_vec <- function(wld = W, rmarg = r_marg_v, ...) {
  ov <- list(...)
  v <- c(
    pi_ = 0, a = 0, Sub_I = 0, prem_on = 1,
    Fbar = Fbar_v, pF = pF_v, w = w_v, LAbar = LAbar_v, prN = prN_v,
    beta = beta_v, gamma = gamma_v, gfull = g_bau_v, lam0 = lam0_v,
    kappa0 = wld$kappa0, kappa1 = kappa1_v, kappa2 = wld$kappa2,
    kappa3 = kappa3_v, zeta = wld$zeta, c1 = wld$c1, c2 = wld$c2,
    ghg_n2o_syn0 = ghg_n2o_syn0_v, ghg_n2o_gm0 = ghg_n2o_gm0_v,
    ghg_ch4_pad0 = ghg_ch4_pad0_v, ch4_uplift = ch4_uplift_v,
    k_paddy = k_paddy_v, k_upland = k_upland_v,
    iota_paddy = iota_paddy_v, iota_upland = iota_upland_v,
    phi = phi_v, gamma_soc = gamma_soc_v,
    sA_rice = sA_rice, psi_bar = psi_bar_v, prem_bar = prem_bar_v,
    Dbar = Dbar_v, WA = wld$WA, YL = wld$YL, WL = wld$WL, PiL = wld$PiL,
    Ga = wld$Ga, Gn = wld$Gn, tau = wld$tau, KNbar = wld$KNbar,
    X = wld$X, X_ag = wld$X_ag, NX_other = wld$NX_other,
    r_avg = wld$r_avg, r_marg = rmarg, NFA_star = wld$NFA, r_B = r_B_v
  )
  if (length(ov)) v[names(ov)] <- unlist(ov)
  v
}
mk_external <- function(wld = W, rmarg = r_marg_v, ...) {
  sfcr_set_from(mk_ext_vec(wld, rmarg, ...))
}
# soc = FALSE for PART B: eqs4 carries no SOC reservoir (at equilibrium the
# sink is identically zero, so PART B's dGHG already IS the permanent annual
# change). sfcr errors if given initials for variables absent from the model.
mk_initial <- function(wld = W, soc = TRUE) {
  v <- c(
    KA = 100, YA = 100, NFA = wld$NFA, B = wld$B,
    V = 100 + wld$KNbar + wld$B + wld$NFA,
    Vh = 100 + wld$KNbar + wld$B + wld$NFA
  )
  if (soc) v <- c(v, SOCp = 0, SOCu = 0)
  sfcr_set_from(v)
}

bau <- sfcr_baseline(eqs, mk_external(), TERM, mk_initial(),
                     hidden = c("V" = "Vh"), method = "Broyden"
)

cat("\n=== 2. BAU verification (expect YA=KA=100, CAB=0, NFA/B flat, GHG=0) ===\n")
print(bau %>% slice(c(2, TERM)) %>%
        select(period, YA, KA, F, CAB, NFA, B, GHGnet, dCO2soc, SOCp))
cat(sprintf(
  "Walras leak %.4e   BAU INF %.6f\n",
  max(abs(bau$V[-1] - bau$Vh[-1])), bau$INF[TERM]
))
# Broyden iterates to a tolerance: the hidden equation holds to ~1e-10, not exactly. 
# The sfcr warning about shock series length is benign (pi_path has length 29 = periods 4..32 exactly).

# =============================================================================
# 8A. SCENARIOS
#   Gradual ramps with a kink at 2030 (adoption diffuses cumulatively; a step would be wrong). 
#   sfcr BUG: shocks cannot hold time-index formulas - a bare `t` resolves to base::t (transpose).
#   Splice literal vectors via bquote().
# =============================================================================
ramp <- function(t, t0 = Y2022, t30 = Y2030, v30, t50 = Y2050, v50) {
  ifelse(t <= t0, 0,
         ifelse(t <= t30, v30 * (t - t0) / (t30 - t0),
                ifelse(t <= t50, v30 + (v50 - v30) * (t - t30) / (t50 - t30), v50)
         )
  )
}
tt <- Y2022:TERM
pi_path <- ramp(tt, v30 = PI30, v50 = PI50)
a_path <- ramp(tt, v30 = A30, v50 = A50)

shock_S1 <- sfcr_shock(sfcr_set(eval(bquote(pi_ ~ .(pi_path)))), Y2022, TERM)
shock_S2 <- sfcr_shock(sfcr_set(
  eval(bquote(pi_ ~ .(pi_path))),
  eval(bquote(a ~ .(a_path)))
), Y2022, TERM)
s1 <- sfcr_scenario(bau, shock_S1, TERM)
s2 <- sfcr_scenario(bau, shock_S2, TERM)

d2050 <- function(s, v, t = Y2050) s[[v]][t] - bau[[v]][t]
CONV <- s2$CAB[Y2050] - s1$CAB[Y2050]

cat("\n=== 3. HEADLINE (2050) ===\n")
cat(sprintf(
  "S1 dCAB  %+.4f (%+.4f tn JPY/yr)\n",
  d2050(s1, "CAB"), d2050(s1, "CAB") * unit_tn
))
cat(sprintf(
  "S2 dCAB  %+.4f (%+.4f tn JPY/yr)\n",
  d2050(s2, "CAB"), d2050(s2, "CAB") * unit_tn
))
cat(sprintf(
  "CONVERSION (S2-S1) %+.4f (%+.4f tn JPY/yr) << HEADLINE\n",
  CONV, CONV * unit_tn
))
cat(sprintf(
  "S1 dNFA  %+.4f (%+.3f tn JPY)\n",
  d2050(s1, "NFA"), d2050(s1, "NFA") * unit_tn
))
cat(sprintf(
  "S2 dNFA  %+.4f (%+.3f tn JPY)\n",
  d2050(s2, "NFA"), d2050(s2, "NFA") * unit_tn
))
cat(sprintf("S1 dGHG  %+.4f\n", d2050(s1, "GHGnet")))
cat(sprintf(
  "S2 dGHG  %+.4f (%+.3f Mt-CO2eq/yr) [syn %+.4f | gm %+.4f | CH4 %+.4f | SOC %+.4f]\n",
  d2050(s2, "GHGnet"), d2050(s2, "GHGnet") / 100, s2$dN2O[Y2050],
  s2$dN2Ogm[Y2050], s2$dCH4[Y2050], s2$dCO2soc[Y2050]
))
cat(sprintf(
  "   SOC gain %.3f MtC | equilibrium dGHG %+.4f (%+.3f Mt/yr, sink -> 0)\n",
  (s2$SOCp[Y2050] + s2$SOCu[Y2050]) * A_ha_v / 1e6,
  s2$dN2O[Y2050] + s2$dN2Ogm[Y2050] + s2$dCH4[Y2050],
  (s2$dN2O[Y2050] + s2$dN2Ogm[Y2050] + s2$dCH4[Y2050]) / 100
))
cat(sprintf(
  "2030 checkpoint (S2): dCAB %+.4f  dGHG %+.4f\n",
  d2050(s2, "CAB", Y2030), d2050(s2, "GHGnet", Y2030)
))
for (nm in c("S1", "S2")) {
  cat(sprintf(
    "Walras leak %s %.4e\n",
    nm, max(abs(get(tolower(nm))$V[-1] - get(tolower(nm))$Vh[-1]))
  ))
}
# =============================================================================
# 8A-bis. THE SIGN OF dGHG IS A FUNCTION OF THE EVALUATION DATE
#   The soil-carbon sink is a STOCK adjustment: it approaches a new equilibrium
#   and stops. Paddy CH4 and green-manure N2O are FLOWS: they persist for as
#   long as the land stays organic. Netting a CONSTANT sequestration rate
#   against an emission flow - which is what MAFF's 0.93 tCO2/ha/yr does -
#   nets a stock against a flow. SFC accounting does not permit it, and a
#   single-period LCA or a Tier-1 inventory cannot detect it. [N22]
#   After 2050, a and pi are held at target; the reservoir is then a linear
#   first-order recursion, so no solver is needed.
#   S1 alone can never cross: a = 0 there, so GHGnet = -103.3459*pi < 0. [N07]
# =============================================================================
soc_extend <- function(Tend = 250, phi = phi_v, iota_p = iota_paddy_v,
                       iota_u = iota_upland_v, upl = ch4_uplift_v) {
  sp <- 0
  su <- 0
  g <- rep(NA_real_, Tend)
  soc <- g; sink <- g; n1 <- g; n2 <- g; c4 <- g; maff <- g
  for (t in 2:Tend) {
    pi_ <- if (t <= TERM) ramp(t, v30 = PI30, v50 = PI50) else PI50
    a <- if (t <= TERM) ramp(t, v30 = A30, v50 = A50) else A50
    LAo <- a * LAbar_v
    e <- ghg_n2o_syn0_v * (-pi_) + ghg_n2o_gm0_v * (LAo / LAbar_v) * phi +
      ghg_ch4_pad0_v * (sA_rice * LAo / LAbar_v) * upl * phi
    npx <- (1 - k_paddy_v) * sp + phi * iota_p * (sA_rice * LAo)
    nux <- (1 - k_upland_v) * su + phi * iota_u * ((1 - sA_rice) * LAo)
    sink[t] <- gamma_soc_v * ((npx - sp) + (nux - su))
    n1[t] <- ghg_n2o_syn0_v * (-pi_)
    n2[t] <- ghg_n2o_gm0_v * (LAo / LAbar_v) * phi
    c4[t] <- ghg_ch4_pad0_v * (sA_rice * LAo / LAbar_v) * upl * phi
    # MAFF convention: soil CO2 only, at a CONSTANT 0.93 tCO2/ha/yr on the
    # converted area (11th Third-Party Committee, Tab.3-1). A rate, not a stock.
    maff[t] <- 0.93 * (LAo * A_ha_v) / 1e4
    g[t] <- e - sink[t]
    sp <- npx
    su <- nux
    soc[t] <- (sp + su) * A_ha_v / 1e6
  }
  tibble(
    year = YEAR0 + seq_len(Tend), dGHG = g, SOC_MtC = soc,
    dN2O = n1, dN2Ogm = n2, dCH4 = c4, sink = sink, dGHG_maff = -maff
  )
}
cross_up <- function(x, yr, after = 2050) {
  for (i in 3:length(x)) {
    if (!is.na(x[i - 1]) && x[i] > 0 && x[i - 1] <= 0 && yr[i] > after) {
      return(yr[i - 1] + (-x[i - 1]) / (x[i] - x[i - 1]))
    }
  }
  NA_real_
}
cat("\n=== 4. dGHG: transient stock vs permanent flow ===\n")
for (ph in c(1.0, 29 / 45)) {
  ext <- soc_extend(phi = ph)
  cum <- cumsum(ifelse(is.na(ext$dGHG), 0, ext$dGHG))
  EMperm <- ghg_n2o_syn0_v * (-PI50) + ghg_n2o_gm0_v * A50 * ph +
    ghg_ch4_pad0_v * sA_rice * A50 * ch4_uplift_v * ph
  cat(sprintf(
    "  phi %.4f: dGHG2050 %+9.4f | annual cross %.1f | cumulative cross %d\n",
    ph, ext$dGHG[Y2050], cross_up(ext$dGHG, ext$year),
    ext$year[which(cum > 0)[1]]
  ))
  cat(sprintf(
    "             equilibrium dGHG %+.4f (%+.3f Mt-CO2eq/yr, PERMANENT)\n",
    EMperm, EMperm / 100
  ))
}

# =============================================================================
# 4-bis. FIGURE: a stock adjustment cannot be netted against a flow
#   Two conventions on the SAME policy. MAFF applies a constant 0.93
#   tCO2/ha/yr and counts soil CO2 only, so the strategy looks like a
#   permanent sink. A mass-conserving reservoir with all three gases is
#   negative only while the soil is filling. [N22]
# =============================================================================
ext <- soc_extend()
tcross <- cross_up(ext$dGHG, ext$year)
EMperm <- ghg_n2o_syn0_v * (-PI50) + ghg_n2o_gm0_v * A50 +
  ghg_ch4_pad0_v * sA_rice * A50 * ch4_uplift_v
fg <- ext %>% filter(year >= 2020, year <= 2100)

comp <- fg %>%
  transmute(
    year,
    `Paddy CH4` = dCH4 / 100,
    `Green-manure N2O` = dN2Ogm / 100,
    `Synthetic-fertiliser N2O` = dN2O / 100,
    `Soil carbon (transient)` = -sink / 100
  ) %>%
  pivot_longer(-year, names_to = "component")
comp$component <- factor(comp$component, levels = c(
  "Paddy CH4", "Green-manure N2O", "Synthetic-fertiliser N2O",
  "Soil carbon (transient)"
))

nets <- bind_rows(
  fg %>% transmute(year, value = dGHG / 100, conv = "This model (reservoir, 3 gases)"),
  fg %>% transmute(year, value = dGHG_maff / 100, conv = "MAFF convention (constant 0.93 tCO2/ha/yr, CO2 only)")
)

p_soc <- ggplot() +
  geom_col(data = comp, aes(year, value, fill = component), width = 1) +
  geom_hline(yintercept = 0, linewidth = 0.4, colour = "grey30") +
  geom_hline(
    yintercept = EMperm / 100, linetype = 3, linewidth = 0.5,
    colour = "grey30"
  ) +
  geom_vline(xintercept = 2050, linetype = 2, linewidth = 0.4, colour = "grey50") +
  geom_vline(xintercept = tcross, linetype = 2, linewidth = 0.4, colour = "grey50") +
  geom_line(data = nets, aes(year, value, colour = conv), linewidth = 1) +
  annotate("text", x = 2050, y = 2.05, label = "KPI target year", hjust = 1.05,
           size = 3, colour = "grey35") +
  annotate("text", x = tcross, y = 2.05,
           label = sprintf("annual balance turns positive (%.0f)", tcross),
           hjust = -0.05, size = 3, colour = "grey35") +
  annotate("text", x = 2100, y = EMperm / 100,
           label = sprintf("permanent %+.2f", EMperm / 100),
           hjust = 1.02, vjust = -0.6, size = 3, colour = "grey35") +
  scale_fill_manual(values = c(
    "Paddy CH4" = "#D1495B", "Green-manure N2O" = "#EDAE49",
    "Synthetic-fertiliser N2O" = "#3E7CB1",
    "Soil carbon (transient)" = "#66A182"
  )) +
  scale_colour_manual(values = c(
    "This model (reservoir, 3 gases)" = "grey10",
    "MAFF convention (constant 0.93 tCO2/ha/yr, CO2 only)" = "grey45"
  )) +
  guides(
    fill = guide_legend(order = 1, nrow = 2),
    colour = guide_legend(order = 2, nrow = 2)
  ) +
  labs(
    title = "A stock adjustment cannot be netted against a flow",
    subtitle = paste0(
      "Same policy, two accounting conventions. Soil carbon fills a reservoir ",
      "and stops; CH4 and N2O persist."
    ),
    x = NULL, y = "Annual GHG change vs BAU (Mt-CO2eq/yr)",
    fill = NULL, colour = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.box = "vertical",
        legend.spacing.y = unit(0, "pt"))
ggsave("fig_soc_crossover.png", p_soc, width = 9, height = 6.5, dpi = 300)

cat(sprintf(
  "  MAFF convention at 2050: %+.4f (%+.3f Mt/yr) vs this model %+.4f (%+.3f)\n",
  ext$dGHG_maff[Y2050], ext$dGHG_maff[Y2050] / 100,
  ext$dGHG[Y2050], ext$dGHG[Y2050] / 100
))
cat(sprintf(
  "  MAFF convention is a CONSTANT rate: still %+.3f Mt/yr in 2100; this model %+.3f\n",
  ext$dGHG_maff[ext$year == 2100] / 100, ext$dGHG[ext$year == 2100] / 100
))

# dCAB is still negative in the terminal period [N07]

# =============================================================================
# 9A. SENSITIVITY AND ROBUSTNESS
#   BODY carries exactly TWO sweeps (Section 7.1, 7.2), one per causal link; the rest in Appendix A. [N08]
# =============================================================================
run_pair <- function(...) {
  b <- sfcr_baseline(eqs, mk_external(...), TERM, mk_initial(),
                     hidden = c("V" = "Vh"), method = "Broyden"
  )
  x1 <- sfcr_scenario(b, shock_S1, TERM)
  x2 <- sfcr_scenario(b, shock_S2, TERM)
  list(
    b = b, x1 = x1, x2 = x2, conv = x2$CAB[Y2050] - x1$CAB[Y2050],
    ghg = x2$GHGnet[Y2050] - b$GHGnet[Y2050]
  )
}

# -- 7.1 psi_bar sweep --------------------------------------------------------
# The baseline IS the lower endpoint - disclose this. The break-even sits BELOW the band's upper end [N09]
cat("\n=== 7.1 psi_bar sweep ===\n")
for (p in c(psi_bar_LO, psi_bar_HI)) {
  cat(sprintf("  psi_bar %.6f -> conversion dCAB %+.4f\n", p, run_pair(psi_bar = p)$conv))
}
be_psi <- uniroot(function(p) run_pair(psi_bar = p)$conv,
                  c(psi_bar_LO, 0.95),
                  tol = 1e-8
)$root
cat(sprintf("  BREAK-EVEN psi_bar = %.6f\n", be_psi))
cat(sprintf("  vs band upper %.6f -> margin %+.6f\n", psi_bar_HI, be_psi - psi_bar_HI))

# -- 7.2 r_marg sweep (the snowball link) ------------------------------------
cat("\n=== 7.2 r_marg sweep ===\n")
for (rm in r_marg_band) {
  rr <- run_pair(rmarg = rm)
  cat(sprintf(
    "  r_marg %.5f -> conversion dCAB %+.4f   S2 dNFA %+.4f\n",
    rm, rr$conv, rr$x2$NFA[Y2050] - rr$b$NFA[Y2050]
  ))
}

# -- 7.3 r_avg invariance -----------------------------------------------------
cat("\n=== 7.3 r_avg invariance (the average rate must NOT matter) ===\n")
for (ra in c(0.02, 0.03, r_avg_v, 0.10)) {
  W2 <- make_world(ravg = ra)
  b2 <- sfcr_baseline(eqs, mk_external(W2), TERM, mk_initial(W2),
                      hidden = c("V" = "Vh"), method = "Broyden"
  )
  x1 <- sfcr_scenario(b2, shock_S1, TERM)
  x2 <- sfcr_scenario(b2, shock_S2, TERM)
  cat(sprintf(
    "  r_avg %.5f: GDP %9.3f tau %.6f -> conversion dCAB %+.8f  (dev %+.2e)\n",
    ra, W2$GDP, W2$tau, x2$CAB[Y2050] - x1$CAB[Y2050],
    (x2$CAB[Y2050] - x1$CAB[Y2050]) - CONV
  ))
}
cat("  -> r_avg pins the BAU level only; it cancels from the difference.\n")

# -- 7.4 GHG reversal: break-even in ch4_uplift, jointly with nu_O ------------
#    nu_O drives BOTH the green-manure N2O & ch4_uplift, so they must move together.
cat("\n=== 7.4 GHG reversal: ch4_uplift break-even over the nu_O band ===\n")
gm0_of <- function(nu, eps = epsN_gm_v) {
  eps * nu * LAbar_v * (ghg_n2o_syn0_v / (epsN_bar_v * Fbar_v))
}
# The break-even asks whether conversion raises GHG PERMANENTLY, so it is
# evaluated on the flow components only. At equilibrium the soil-carbon sink
# is identically zero, so excluding it is not a convenience: it IS the
# equilibrium value of the same object. [N22]
ghg_at <- function(u, gm0 = ghg_n2o_gm0_v) {
  b <- sfcr_baseline(eqs, mk_external(ch4_uplift = u, ghg_n2o_gm0 = gm0),
                     TERM, mk_initial(),
                     hidden = c("V" = "Vh"), method = "Broyden"
  )
  x <- sfcr_scenario(b, shock_S2, TERM)
  (x$dN2O[Y2050] + x$dN2Ogm[Y2050] + x$dCH4[Y2050]) -
    (b$dN2O[Y2050] + b$dN2Ogm[Y2050] + b$dCH4[Y2050])
}
for (nu in c(nu_O_band[1], nu_O_v, nu_O_band[2])) {
  gm0 <- gm0_of(nu)
  uA <- ch4_route_A(nu)
  be <- uniroot(function(u) ghg_at(u, gm0), c(0, 1.6), tol = 1e-8)$root
  cat(sprintf(
    "  nu_O %.4f: gm N2O %7.4f | route A %.4f | break-even %.6f | margin %5.2fx\n",
    nu, gm0 * A50, uA, be, uA / be
  ))
}

# -- 7.5 the opposite corner: epsN_gm at its MEASURED value ----------------
#    Both bound-side choices make the reversal easier, so run the least
#    favourable corner: Xie et al. (2016) measured EF 0.195%. [N10]
cat("\n=== 7.5 counter-check: epsN_gm = 0.00195 (Xie et al. 2016, measured) ===\n")
for (nu in c(nu_O_band[1], nu_O_v)) {
  gm0 <- gm0_of(nu, 0.00195)
  uA <- ch4_route_A(nu)
  be <- uniroot(function(u) ghg_at(u, gm0), c(0, 1.6), tol = 1e-8)$root
  cat(sprintf(
    "  nu_O %.4f: break-even %.6f | route A %.4f | margin %5.2fx\n",
    nu, be, uA, uA / be
  ))
}

# -- 7.6 psi_rice diagnostic (a component of 7.1) -------------------------
cat("\n=== 7.6 psi_rice diagnostic ===\n")
psi_rice_tests <- c(
  "0.720" = "Tottori 2011-13 [ADOPTED]",
  "0.810" = "retired: untraceable",
  "0.940" = "de Ponti Tab.1 rice, n=7 [band upper]"
)
for (i in seq_along(psi_rice_tests)) {
  pr <- as.numeric(names(psi_rice_tests)[i])
  pb <- w_rice * pr + w_veg * psi_veg + w_fruit * psi_fruit + w_other * psi_other
  cat(sprintf(
    "  psi_rice %.3f -> psi_bar %.6f, conversion dCAB %+.4f   %s\n",
    pr, pb, run_pair(psi_bar = pb)$conv, psi_rice_tests[i]
  ))
}

# -- 7.7 the -30% conventional yield loss is BOUNDED --------------------------
#    With m0 pinned, concavity of g(F) makes the linear limit the largest attainable loss. [N11]
cat("\n=== 7.7 conventional yield loss at -30% N: bound vs calibration ===\n")
loss_lin <- 1 - (355 + 0.7 * (516 - 355)) / 516
loss_li <- 1 - (1 - beta_v * exp(-gamma_v * 70)) / (1 - beta_v * exp(-gamma_v * 100))
cat(sprintf(
  "  linear limit (max under Mitscherlich) %.4f%%   calibrated %.4f%% (%.0f%% of max)\n",
  100 * loss_lin, 100 * loss_li, 100 * loss_li / loss_lin
))

# -- 7.8 invariance of the assumed behavioural block --------------------------
#    Neutralizes the "your behavioural parameters have no source" objection.
#    These parameters enter the closure, so the world must be re-solved, otherwise BAU is non-stationary [N03]
cat("\n=== 7.8 invariance check (deviation of conversion dCAB from central) ===\n")
inv_tests <- list(
  c1 = 0.5, c2 = 0.10, kappa2 = 4.0, zeta = 0.08,
  ellA = 0.5, Ga = 20, kN = 3.0
)
for (nm in names(inv_tests)) {
  W2 <- do.call(make_world, setNames(list(inv_tests[[nm]]), nm))
  b2 <- sfcr_baseline(eqs, mk_external(W2), TERM, mk_initial(W2),
                      hidden = c("V" = "Vh"), method = "Broyden"
  )
  x1 <- sfcr_scenario(b2, shock_S1, TERM)
  x2 <- sfcr_scenario(b2, shock_S2, TERM)
  cat(sprintf(
    "  %-7s = %-5s kappa0 %8.5f GDP %9.3f -> deviation %+.2e\n",
    nm, inv_tests[[nm]], W2$kappa0, W2$GDP,
    (x2$CAB[Y2050] - x1$CAB[Y2050]) - CONV
  ))
}

# kappa1 and kappa3 do not enter the closure, so they are swapped directly.
# kappa3 multiplies Sub_I = 0: its invariance is VACUOUS
for (nm in c("kappa1", "kappa3")) {
  vv <- if (nm == "kappa1") 0.4 else 1.0
  cat(sprintf(
    "  %-7s = %-5s (outside the closure)      -> deviation %+.2e%s\n",
    nm, vv, do.call(run_pair, setNames(list(vv), nm))$conv - CONV,
    if (nm == "kappa3") "  <- VACUOUS: Sub_I = 0" else ""
  ))
}
cat(
  "  -> all |deviation| <= ~6e-14. Also invariant: r_avg, NFA_pct,\n",
  "     primary_pct, m_c, Dbar, tau, prem_c, WL/PiL, and (quasi) m0.\n"
)

# =============================================================================
# 10A. HEADLINE FIGURE
#   Government balance uses the SOLVED INB column - never lag(B) across stacked scenarios,
#   the lag would leak across scenario boundaries.
# =============================================================================
plotdat <- bind_rows(list(BAU = bau, S1 = s1, S2 = s2), .id = "scn") %>%
  filter(period > 1) %>%
  mutate(bauNFA = bau$NFA[period]) %>%
  transmute(
    year = YEAR0 + period, scn,
    # panels show DEVIATIONS from BAU, not levels - say so in the panel titles [N01]
    `Current account, dev. from BAU (tn JPY/yr)` = CAB * unit_tn,
    `NFA, dev. from BAU (tn JPY)` = (NFA - bauNFA) * unit_tn,
    `Gov. balance, dev. from BAU (tn JPY/yr)` = (TX - (W$Ga + W$Gn + INB)) * unit_tn,
    `Net GHG change from BAU (Mt-CO2eq/yr)` = GHGnet / 100
  ) %>%
  pivot_longer(-c(year, scn))
plotdat$name <- factor(plotdat$name, levels = c(
  "Current account, dev. from BAU (tn JPY/yr)", "NFA, dev. from BAU (tn JPY)",
  "Gov. balance, dev. from BAU (tn JPY/yr)",
  "Net GHG change from BAU (Mt-CO2eq/yr)"
))

ggplot(plotdat, aes(year, value, colour = scn)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey70") +
  geom_line(linewidth = 0.9) +
  facet_wrap(~name, scales = "free_y", nrow = 2) +
  scale_colour_manual(values = c(BAU = "grey55", S1 = "#3E7CB1", S2 = "#D1495B")) +
  labs(
    title = "Midori KPIs under the aggregate SFC core",
    subtitle = paste0(
      "S1 = fertilizer -30% (national total); S2 = + organic 25% by 2050. ",
      "BAU normalises CAB and the fiscal balance to zero."
    ),
    x = NULL, y = NULL, colour = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.spacing = unit(1, "lines"))
ggsave("fig_core_headline.png", width = 9, height = 6.5, dpi = 300)



# #################### PART B - 4-CROP DECOMPOSITION ####################
#
# Same model at crop granularity. 
# Uniform allocation must reproduce PART A to machine precision. [N12]
#
# ============================================================================
# 11B. EQUATIONS (4 crops x 2 technologies)
#   YA_c = 100*w_c * [ (1-a_c)*gC/gfull + a_c*psi_c ]
#   areaO before Fint (national-total KPI). Paddy CH4 uses organic RICE area only.
# =============================================================================

eqs4 <- sfcr_set(
  areaO ~ sA_rice * a_rice + sA_veg * a_veg + sA_fruit * a_fruit + sA_other * a_other,
  Fint ~ (1 - pi_) * Fbar / (1 - areaO), # KPI(6) national total
  F ~ Fint * (1 - areaO),
  gC ~ 1 - beta * exp(-gamma * Fint),
  YA_rice ~ 100 * w_rice * ((1 - a_rice) * (gC / gfull) + a_rice * psi_rice),
  YA_veg ~ 100 * w_veg * ((1 - a_veg) * (gC / gfull) + a_veg * psi_veg),
  YA_fruit ~ 100 * w_fruit * ((1 - a_fruit) * (gC / gfull) + a_fruit * psi_fruit),
  YA_other ~ 100 * w_other * ((1 - a_other) * (gC / gfull) + a_other * psi_other),
  YA ~ YA_rice + YA_veg + YA_fruit + YA_other,
  dN2O ~ ghg_n2o_syn0 * (F / Fbar - 1),
  dN2Ogm ~ ghg_n2o_gm0 * areaO,
  dCH4 ~ ghg_ch4_pad0 * (sA_rice * a_rice) * ch4_uplift,
  GHGnet ~ dN2O + dN2Ogm + dCH4,
  PREM ~ 100 * (prem_rice * w_rice * a_rice * psi_rice +
                  prem_veg * w_veg * a_veg * psi_veg +
                  prem_fruit * w_fruit * a_fruit * psi_fruit +
                  prem_other * w_other * a_other * psi_other),
  rA ~ (YA - WA - pF * F - zeta * KA[-1]) / KA[-1],
  IA ~ kappa0 + kappa1 * ((YA - YA[-1]) / KA[-1]) + kappa2 * rA,
  KA ~ KA[-1] + IA - zeta * KA[-1],
  IN_ ~ zeta * KNbar,
  YN ~ Cn + IA + IN_ + Gn + X,
  WN ~ w * YN / prN,
  IMfood ~ Dbar - YA,
  Cf ~ YA + IMfood - Ga + YL + PREM,
  PiA ~ YA - WA - pF * F - zeta * KA[-1] + PREM,
  PiN ~ YN - WN - zeta * KNbar,
  W_ ~ WA + WN + WL,
  Pi ~ PiA + PiN + PiL,
  TX ~ tau * (W_ + Pi),
  INF ~ r_avg * NFA_star + r_marg * (NFA[-1] - NFA_star),
  INB ~ r_B * B[-1],
  YD ~ W_ + Pi - TX + INF + INB,
  C ~ c1 * YD + c2 * V[-1],
  Cn ~ C - Cf,
  CAB ~ X_ag - pF * F - IMfood + NX_other + INF,
  NFA ~ NFA[-1] + CAB,
  B ~ B[-1] + (Ga + Gn + INB - TX),
  V ~ KA + KNbar + B + NFA,
  Vh ~ Vh[-1] + (YD - C)
)

mk_external4 <- function(wld = W, rmarg = r_marg_v, ...) {
  ov <- list(...)
  v <- c(
    pi_ = 0, a_rice = 0, a_veg = 0, a_fruit = 0, a_other = 0,
    Fbar = Fbar_v, pF = pF_v, w = w_v, prN = prN_v,
    beta = beta_v, gamma = gamma_v, gfull = g_bau_v,
    kappa0 = wld$kappa0, kappa1 = kappa1_v, kappa2 = wld$kappa2,
    zeta = wld$zeta, c1 = wld$c1, c2 = wld$c2,
    w_rice = w_rice, w_veg = w_veg, w_fruit = w_fruit, w_other = w_other,
    sA_rice = sA_rice, sA_veg = sA_veg, sA_fruit = sA_fruit, sA_other = sA_other,
    psi_rice = psi_rice, psi_veg = psi_veg, psi_fruit = psi_fruit,
    psi_other = psi_other,
    prem_rice = prem_rice, prem_veg = prem_veg, prem_fruit = prem_fruit,
    prem_other = prem_other,
    ghg_n2o_syn0 = ghg_n2o_syn0_v, ghg_n2o_gm0 = ghg_n2o_gm0_v,
    ghg_ch4_pad0 = ghg_ch4_pad0_v, ch4_uplift = ch4_uplift_v,
    Dbar = Dbar_v, WA = wld$WA,
    YL = wld$YL, WL = wld$WL, PiL = wld$PiL, Ga = wld$Ga, Gn = wld$Gn,
    tau = wld$tau, KNbar = wld$KNbar, X = wld$X, X_ag = wld$X_ag,
    NX_other = wld$NX_other,
    r_avg = wld$r_avg, r_marg = rmarg, NFA_star = wld$NFA, r_B = r_B_v
  )
  if (length(ov)) v[names(ov)] <- unlist(ov)
  sfcr_set_from(v)
}
bau4 <- sfcr_baseline(eqs4, mk_external4(), TERM, mk_initial(soc = FALSE),
                      hidden = c("V" = "Vh"), method = "Broyden"
)
cat("\n=== 8. PART B BAU (expect YA=KA=100, CAB=0, GHG=0) ===\n")
print(bau4 %>% slice(c(2, TERM)) %>% select(period, YA, KA, F, CAB, NFA, B, GHGnet))
cat(sprintf("PART B Walras leak %.4e\n", max(abs(bau4$V[-1] - bau4$Vh[-1]))))


# =============================================================================
# 12B. ALLOCATIONS
#   KPI(7) is an area target: sum(sA_c*a_c) = abar(t). EVERY allocation below
#   satisfies it exactly; they differ only in which land converts.
# =============================================================================
abar_path <- ramp(tt, v30 = A30, v50 = A50)

# Import value induced per unit AREA converted: an AUTHORS' DERIVATION. 
# The RANKING is source-conditional [N13]
cost_c <- w_c * (1 - psi_c) / sA_c
cat("\n=== import cost per unit area converted (lower = cheaper) ===\n")
print(round(sort(cost_c), 4))

fill_alloc <- function(order, target = A50, cap = CAP) {
  a <- setNames(numeric(4), crops)
  rem <- target
  for (cc in order) {
    take <- min(cap * sA_c[[cc]], rem)
    a[cc] <- take / sA_c[[cc]]
    rem <- rem - take
    if (rem <= 1e-12) break
  }
  stopifnot(abs(sum(sA_c * a) - target) < 1e-9)
  a
}
by_cost <- names(sort(cost_c))
by_cost_norice <- setdiff(by_cost, "rice")
ALLOC <- list(
  "Uniform (neutral benchmark)"  = setNames(rep(A50, 4), crops),
  "CAB-optimal (cheapest first)" = fill_alloc(by_cost),
  "CAB-worst (veg first)"        = fill_alloc(rev(by_cost)),
  "Rice-focused"                 = fill_alloc(c("rice", "other", "fruit", "veg")),
  "Paddy-sparing (no rice)"      = fill_alloc(by_cost_norice)
)
run_alloc <- function(a2050) {
  scl <- abar_path / A50
  sh <- sfcr_shock(sfcr_set(
    eval(bquote(pi_ ~ .(pi_path))),
    eval(bquote(a_rice ~ .(a2050[["rice"]] * scl))),
    eval(bquote(a_veg ~ .(a2050[["veg"]] * scl))),
    eval(bquote(a_fruit ~ .(a2050[["fruit"]] * scl))),
    eval(bquote(a_other ~ .(a2050[["other"]] * scl)))
  ), Y2022, TERM)
  sfcr_scenario(bau4, sh, TERM)
}

# =============================================================================
# 13B. RESULTS
# =============================================================================
res <- imap_dfr(ALLOC, function(a, nm) {
  r <- run_alloc(a)
  tibble(
    allocation = nm, a_rice = a[["rice"]], a_veg = a[["veg"]],
    a_fruit = a[["fruit"]], a_other = a[["other"]],
    dCAB_2050 = r$CAB[Y2050] - bau4$CAB[Y2050],
    trillion_yen_per_yr = (r$CAB[Y2050] - bau4$CAB[Y2050]) * unit_tn,
    dNFA_2050 = r$NFA[Y2050] - bau4$NFA[Y2050],
    dGHG_2050 = r$GHGnet[Y2050]
  )
})
# PART B carries no SOC reservoir and needs none: at equilibrium the sink is
# identically zero, so dGHG here IS the PERMANENT annual change. Allocation is
# a question about which land is organic forever, so equilibrium is the right
# frame. Label the axis accordingly. [N23]
cat("\n=== 9. allocations (25% AREA target; dGHG = PERMANENT annual) ===\n")
print(as.data.frame(res %>% mutate(across(where(is.numeric), ~ round(., 3)))))
# Reading guide (incl. why CAB-worst still converts some rice) [N14]

uni <- res %>% filter(allocation == "Uniform (neutral benchmark)")
dom <- res %>% filter(allocation == "Paddy-sparing (no rice)")
# Consistency test: under uniform allocation, the 4-crop model must reproduce
# the aggregate core exactly. Drift >1e-13 means psi_c transcription
# mismatch between mk_ext_vec() and mk_external4().
cat(sprintf(
  "\nCONSISTENCY uniform %+.8f vs core %+.8f (diff %.2e)\n",
  uni$dCAB_2050, d2050(s2, "CAB"), abs(uni$dCAB_2050 - d2050(s2, "CAB"))
))
cat(sprintf(
  "DOMINANCE paddy-sparing (%+.3f, %+.2f) vs uniform (%+.3f, %+.2f) -> %s\n",
  dom$dCAB_2050, dom$dGHG_2050, uni$dCAB_2050, uni$dGHG_2050,
  ifelse(dom$dCAB_2050 > uni$dCAB_2050 & dom$dGHG_2050 < uni$dGHG_2050,
         "YES on both margins", "NO"
  )
))
cat(sprintf(
  "SPREAD %.3f .. %.3f (%.2fx)\n",
  min(res$dCAB_2050), max(res$dCAB_2050),
  min(res$dCAB_2050) / max(res$dCAB_2050)
))
# Mandatory caveat: the model has no paddy CH4 mitigation channel. [N15]

cat("\n=== 10. CAP robustness ===\n")
max_norice <- sum(sA_c[setdiff(crops, "rice")]) # 0.485
for (capv in c(0.50, 0.75, 1.00)) {
  if (capv * max_norice < A50 - 1e-9) {
    cat(sprintf(
      "  CAP %.2f: paddy-sparing INFEASIBLE (%.3f < %.2f) -- itself a finding\n",
      capv, capv * max_norice, A50
    ))
    next
  }
  ps <- run_alloc(fill_alloc(by_cost_norice, cap = capv))
  cat(sprintf(
    "  CAP %.2f: uniform (%+.3f, %+.2f)  paddy-sparing (%+.3f, %+.2f)  dominates %s\n",
    capv, uni$dCAB_2050, uni$dGHG_2050,
    ps$CAB[Y2050] - bau4$CAB[Y2050], ps$GHGnet[Y2050],
    ifelse(ps$CAB[Y2050] - bau4$CAB[Y2050] > uni$dCAB_2050 &&
             ps$GHGnet[Y2050] < uni$dGHG_2050, "yes", "NO")
  ))
}
# Frontier. NON-MONOTONIC: the cap binds and forces spillover; curvature comes entirely from the CAB side. [N16]
# Finer nodes than the five reported in the text: the CAB-optimal rice share
# sits near 0.25 and a 4-node curve cannot resolve the turning point. [N16]
frontier <- map_dfr(
  c(0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.40, 0.50, 0.75, 1.0),
  function(fr) {
    ra <- fr * A50
    a <- setNames(numeric(4), crops)
    a["rice"] <- ra / sA_c[["rice"]]
    rest <- fill_alloc(by_cost_norice, target = A50 - ra)
    a[names(rest)[names(rest) != "rice"]] <- rest[names(rest) != "rice"]
    r <- run_alloc(a)
    tibble(
      rice_share = fr, a_rice = a[["rice"]],
      dCAB_2050 = r$CAB[Y2050] - bau4$CAB[Y2050], dGHG_2050 = r$GHGnet[Y2050]
    )
  }
)
fr_opt <- frontier %>% slice_max(dCAB_2050, n = 1)
cat("\n=== 11. CAB-GHG frontier (rice share of the 25% area target) ===\n")
print(as.data.frame(frontier %>% mutate(across(where(is.numeric), ~ round(., 3)))))

# =============================================================================
# 14B. TRADE-OFF FIGURE (5.5 headline)
#   Two panels because the figure carries two messages that fight for the
#   same axes. (a) is the frontier alone, zoomed so the turning point is
#   visible: pushing rice conversion PAST the CAB-optimal share makes BOTH
#   objectives worse. (b) is the spread across named allocations, which needs
#   a 5x taller CAB range and would flatten (a) if drawn on the same axes.
#   Caption notes in [N17].
# =============================================================================
PA <- "(a) Frontier: rice share of the 25% area target"
PB <- "(b) Five allocations, each meeting KPI(7)"

fr_p <- frontier %>%
  transmute(
    panel = PA, x = dGHG_2050 / 100, y = dCAB_2050 * unit_tn,
    lab = ifelse(rice_share %in% c(0, 0.25, 0.5, 1.0),
                 sprintf("%.0f%%", 100 * rice_share), NA_character_
    )
  )
al_p <- res %>%
  transmute(
    panel = PB, x = dGHG_2050 / 100, y = dCAB_2050 * unit_tn,
    lab = allocation,
    on_curve = allocation %in% c("Paddy-sparing (no rice)", "Rice-focused")
  )
elbow <- fr_opt %>%
  transmute(panel = PA, x = dGHG_2050 / 100, y = dCAB_2050 * unit_tn)

set.seed(20260807)
p_tr <- ggplot(mapping = aes(x, y)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey70") +
  geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey70") +
  geom_path(data = fr_p, colour = "grey55", linewidth = 0.7, linetype = 2) +
  geom_point(data = fr_p, colour = "grey45", size = 1.9) +
  geom_point(data = elbow, colour = "#D1495B", size = 4, shape = 21,
             fill = NA, stroke = 1.1) +
  ggrepel::geom_text_repel(
    data = fr_p %>% filter(!is.na(lab)), aes(label = lab),
    size = 3, colour = "grey35", box.padding = 0.35, seed = 20260807
  ) +
  geom_point(data = al_p, aes(shape = on_curve), colour = "#D1495B",
             size = 3.2) +
  ggrepel::geom_text_repel(
    data = al_p, aes(label = lab), size = 3.1, box.padding = 0.55,
    min.segment.length = 0, seed = 20260807
  ) +
  scale_shape_manual(values = c(`TRUE` = 21, `FALSE` = 16), guide = "none") +
  facet_wrap(~panel, scales = "free", nrow = 1) +
  labs(
    title = "Same 25% organic target, different land: a CAB-GHG frontier",
    subtitle = paste0(
      "Up-left is better. In (a) the ringed node is the CAB-optimal rice ",
      "share; beyond it BOTH objectives worsen. Open points in (b) are the ",
      "frontier's own endpoints, not independent runs."
    ),
    x = "Permanent annual GHG change (Mt-CO2eq/yr; + = worse)",
    y = "Current-account change, 2050 (tn JPY/yr; - = worse)"
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.spacing = unit(1.4, "lines"),
        plot.subtitle = element_text(size = 9.5, colour = "grey30"))
ggsave("fig_allocation_frontier.png", p_tr, width = 11, height = 5.6, dpi = 300)

cat(sprintf(
  "\n  frontier turning point: rice share %.2f  dCAB %+.3f (%+.4f tn/yr)  dGHG %+.3f Mt\n",
  fr_opt$rice_share, fr_opt$dCAB_2050, fr_opt$dCAB_2050 * unit_tn,
  fr_opt$dGHG_2050 / 100
))
cat(sprintf(
  "  beyond it both worsen: at rice share 1.00 dCAB %+.3f and dGHG %+.3f Mt\n",
  frontier$dCAB_2050[nrow(frontier)],
  frontier$dGHG_2050[nrow(frontier)] / 100
))

# =============================================================================
# END
# =============================================================================

