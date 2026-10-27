# =============================================================================
#  sfc_midori.R
#  Japan's MIDORI Food System Strategy in a stock-flow consistent model with
#  environmental satellite accounts.
#
#  S1 = chemical fertiliser -30% by 2050
#  S2 = S1 + organic farming on 25% of cropland by 2050
#  Headline = S2 - S1, the effect of converting farmland to organic.
#
#  Calibration ledger: data/calibration_ledger.csv
#  Design notes [N01]-[N25]: MODEL_NOTES.md
#
#  Tags: JP-DATA official statistics | LIT literature | DERIVED calculated
#  from tagged inputs | NORM normalisation | ASSUMED no source | SWEPT varied
#  in the sensitivity analysis | BOUNDED reported as an interval |
#  INVARIANT shown not to affect the policy difference
# =============================================================================

library(sfcr)
library(tidyverse)
library(ggrepel)

# =============================================================================
# Time
# =============================================================================

YEAR0 <- 2018 # period 0, so period t is year 2018 + t (period 1 = 2019)
TERM <- 2050 - YEAR0
yr <- function(y) y - YEAR0
Y2022 <- yr(2022) # policy start
Y2030 <- yr(2030) # interim KPI
Y2050 <- yr(2050) # KPI target year

# =============================================================================
# Crop data (2017-19 means)
# =============================================================================

# Share of crop output value [JP-DATA] (MAFF, 2026c)
w_rice <- 0.300476 # 52,199 / 173,721
w_veg <- 0.398541 # 69,235 / 173,721
w_fruit <- 0.145377 # 25,255 / 173,721
w_other <- 0.155606 # 27,032 / 173,721

# Share of planted area of the four crops [DERIVED] (MAFF, 2024, 2026a, 2026i)
sA_rice <- 0.519785 # 1,468,000 / 2,824,246
sA_veg <- 0.164138 # 463,567 / 2,824,246
sA_fruit <- 0.075181 # 212,329 / 2,824,246
sA_other <- 0.240896 # 680,350 / 2,824,246

# Import dependence = 1 - self-sufficiency, weight basis [JP-DATA, INVARIANT] (MAFF, 2026h)
m_rice <- 0.033
m_veg <- 0.210
m_fruit <- 0.613
m_other <- 0.511 # band [0.347, 0.511]

# Organic / conventional yield ratio [SWEPT]
psi_rice <- 0.720 # (Tottori Prefectural Agricultural Experiment Station, 2011)
psi_veg <- 0.670 # (Seufert et al., 2012)
psi_fruit <- 0.753 # (de Ponti et al., 2012) [DERIVED]
psi_other <- 0.800 # (Seufert et al., 2012)

# Direct N2O emission factor per unit N [LIT] (Akiyama et al., 2006)
epsN_rice <- 0.0031
epsN_veg <- 0.0062
epsN_fruit <- 0.0062
epsN_other <- 0.0062

# Organic price premium, producer stage [DERIVED] (MAFF, 2019)
prem_rice <- 0.393
prem_veg <- 0.266
prem_fruit <- 0.266
prem_other <- 0.266

# Crop and livestock shares of agricultural output [JP-DATA] (MAFF, 2026c)
share_crop <- 0.6359
share_livestock <- 0.3576

# =============================================================================
# Macro and external anchors (2017-19 means, tn JPY)
# =============================================================================

# Nominal, calendar years [JP-DATA] (Cabinet Office, 2025)
nominal_GDP <- mean(c(565.1190, 569.1535, 571.8380))
CONS_HH <- mean(c(294.3982, 296.9732, 296.4464))
GOV_CONS <- mean(c(107.3042, 108.7364, 111.1948))

CROP_OUT <- mean(c(5.9605, 5.7815, 5.6300)) # = index 100 (MAFF, 2026c)

# Both cancel from the policy difference [N02]
NFA_yen <- mean(c(329.302, 341.450, 357.015)) # IIP, year-end (MOF, 2026c)
primary_yen <- mean(c(20.6843, 21.4026, 21.5531)) # primary income (MOF, 2026c)
NFA_pct <- NFA_yen / nominal_GDP # [INVARIANT]
primary_pct <- primary_yen / nominal_GDP # [INVARIANT]

# Agricultural exports only [JP-DATA] (MAFF, 2026b)
Xag_pct <- mean(c(0.4966, 0.5661, 0.5878)) / nominal_GDP

# =============================================================================
# Structural parameters
# =============================================================================

Fbar_v <- 100 # fertiliser N, index [NORM]
Fbar_kgN_v <- 96 # the same, kgN/ha (Toriyama, 2002) [N24]
pF_v <- 0.08286 # fertiliser cost / crop revenue, 2019 (MAFF, 2026g)
LAbar_v <- 100 # farmland [NORM]
w_v <- 1 # wage rate [NORM]
prN_v <- 1 # non-agricultural labour productivity [NORM]

# Fertiliser response g(F) = 1 - beta * exp(-gamma * F)
m0_v <- 355 / 516 # relative yield at zero N (Toriyama, 2002)
m70_v <- 0.942940 # relative yield at -30% N (Li et al., 2017)
beta_v <- 0.388821 # solved from m0 and m70 [DERIVED]
gamma_v <- 0.012479 # [DERIVED]

# Behavioural parameters [ASSUMED, INVARIANT]
c1_v <- 0.7
c2_v <- 0.05 # C = c1*YD + c2*V[-1]
kappa1_v <- 0.2
kappa2_v <- 2.0
kappa3_v <- 0.5
zeta_v <- 0.05 # depreciation
ellA_v <- 0.3 # agricultural labour per unit land
Ga_v <- 10 # government purchases of agricultural goods
kN_v <- 2.4 # non-agricultural capital-output ratio
r_B_v <- 0.02 # reproduces the general-government interest bill (Cabinet Office, 2025)

# Emissions satellite, Mt CO2-eq (GIO, 2026)
ghg_n2o_syn0_v <- 1.033459 # synthetic-fertiliser N2O
ghg_ch4_pad0_v <- 13.434926 # paddy CH4
epsN_gm_v <- 0.00082582 # green-manure N2O factor (Xie et al., 2016) [N10]
epsN_gm_band <- c(0.00082582, 0.00195, 0.0031)
nu_O_v <- 1.1927083333 # organic / conventional N (Nagumo et al., 2014; Nakayama & Yoshida, 2005)
nu_O_band <- c(100, 159) / Fbar_kgN_v
CN_gm_v <- 17.1 # C/N of green manure (Nagumo et al., 2014) [N19]
ch4_uplift_v <- 0.8673672646 # paddy CH4 uplift (Katayanagi et al., 2016) [BOUNDED]

ch4_route_A <- function(nu, cn = CN_gm_v) {
  0.09458 * (nu * Fbar_kgN_v * cn) / 213.5
}

# Soil organic carbon: decay rates from equilibrium input / stock [N20]
k_paddy_v <- 0.046733 # (Shirato & Yokozawa, 2005) [DERIVED]
k_upland_v <- 0.033294 # (Shirato et al., 2004) [DERIVED]

# Residue carbon lost to the lower organic yield, tC/ha/yr [N25]
resid_loss_paddy_v  <- 0.4489 # (Shirato & Yokozawa, 2005; MAFF, 2026j) [DERIVED]
resid_loss_upland_v <- 0.3856 # (Ogawa et al., 1988) [DERIVED]

phi_v <- 1.0 # share of converted land using green manure [SWEPT] (MAFF, 2019)
A_ha_v <- 28242 # ha per index hectare = 2,824,246 / 100 [N21]

# KPI targets (MAFF, 2021, 2022b)
PI30 <- 0.20
PI50 <- 0.30 # fertiliser KPI: 0.90 -> 0.72 -> 0.63 Mt
A30 <- 0.01575
A50 <- 0.25 # organic KPI; 70.6% of the 1 Mha target on this land base [N21]
CAP <- 0.75 # max share of one crop's area that converts [ASSUMED]

# Direct payment scheme's soil-carbon credit for organic farming (MAFF, 2026f) [N22]
maff_rate_v <- 1.04 # tCO2/ha/yr

# =============================================================================
# Derived aggregates
# =============================================================================

psi_bar_v <- w_rice * psi_rice + w_veg * psi_veg + w_fruit * psi_fruit + w_other * psi_other
Dbar_v <- 100 * (w_rice / (1 - m_rice) + w_veg / (1 - m_veg) +
                   w_fruit / (1 - m_fruit) + w_other / (1 - m_other))
IM_star <- Dbar_v - 100
epsN_bar_v <- sA_rice * epsN_rice + sA_veg * epsN_veg + # area weighted
  sA_fruit * epsN_fruit + sA_other * epsN_other
prem_bar_v <- (w_rice * psi_rice * prem_rice + w_veg * psi_veg * prem_veg +
                 w_fruit * psi_fruit * prem_fruit + w_other * psi_other * prem_other) / psi_bar_v
g_bau_v <- 1 - beta_v * exp(-gamma_v * Fbar_v)
lam0_v <- 1 / g_bau_v
unit_tn <- CROP_OUT / 100 # tn JPY per index unit

# Scales green-manure N2O so that synthetic N2O reproduces the inventory
ghg_n2o_gm0_v <- epsN_gm_v * nu_O_v * LAbar_v * (ghg_n2o_syn0_v / (epsN_bar_v * Fbar_v))

# Green-manure carbon input, tC/ha/yr, and conversion to Mt CO2-eq
iota_gm_v <- nu_O_v * Fbar_kgN_v * CN_gm_v / 1000
iota_paddy_v <- iota_gm_v - resid_loss_paddy_v
iota_upland_v <- iota_gm_v - resid_loss_upland_v
gamma_soc_v <- A_ha_v * (44 / 12) * 1e-6

# Yield-ratio band: all four crops at de Ponti et al. (2012) values [N09]
psi_dePonti <- c(rice = 0.94, veg = 0.80, fruit = 0.72, other = 0.80)
psi_bar_LO <- psi_bar_v
psi_bar_HI <- w_rice * psi_dePonti[["rice"]] + w_veg * psi_dePonti[["veg"]] +
  w_fruit * psi_dePonti[["fruit"]] + w_other * psi_dePonti[["other"]]

r_avg_v <- primary_yen / NFA_yen # net ratio, not a market rate [N02]
r_marg_v <- 0.02 # [SWEPT]
r_marg_band <- c(0.005, 0.02, 0.028, 0.04, r_avg_v) # 0.028: 10-year JGB, July 2026 (MOF, 2026a)

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
cat(sprintf(
  "  output-value shares: rice %.4f | veg+fruit %.4f | other %.4f\n",
  w_rice, w_veg + w_fruit, w_other
))
cat(sprintf("  MAFF comparison rate %.2f tCO2/ha/yr (2nd-period evaluation)\n",
            maff_rate_v))


# =============================================================================
# Stationary closure
#   BAU current account normalised to zero [N01]. A function of the
#   behavioural parameters, so the invariance test can re-solve it [N03].
# =============================================================================

make_world <- function(c1 = c1_v, c2 = c2_v, kappa2 = kappa2_v, zeta = zeta_v,
                       ellA = ellA_v, Ga = Ga_v, kN = kN_v, ravg = r_avg_v) {
  YL <- 100 * share_livestock / share_crop # livestock output, exogenous
  WL <- 0.30 * YL
  PiL <- 0.70 * YL
  Cf_s <- Dbar_v - Ga + YL
  C_s <- 100 * CONS_HH / CROP_OUT
  Gn <- 100 * GOV_CONS / CROP_OUT - Ga
  V_s <- (1 - c1) * C_s / c2
  aa <- 1 - zeta * kN
  PFIM <- pF_v * Fbar_v + IM_star # imports at BAU
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

# Rice imports as a share of rice demand [N04]
cat(sprintf(
  "\nRice corner: Dbar %.4f  YA %.4f  gap %.4f (%.2f%% of demand)\n",
  100 * w_rice / (1 - m_rice), 100 * w_rice,
  100 * w_rice / (1 - m_rice) - 100 * w_rice,
  100 * (100 * w_rice / (1 - m_rice) - 100 * w_rice) / (100 * w_rice / (1 - m_rice))
))


# #################### PART A - AGGREGATE MODEL ####################

# =============================================================================
# Equations
# =============================================================================
eqs <- sfcr_set(
  # Fertiliser KPI is a national total: conventional land carries it [N05]
  Fint ~ (1 - pi_) * Fbar / (1 - a),
  F ~ Fint * (1 - a),
  gC ~ 1 - beta * exp(-gamma * Fint),
  YAcrop ~ lam0 * gC * LAbar,
  YAcropO ~ lam0 * gfull * LAbar, # organic yield set by psi alone
  YA ~ (1 - a) * YAcrop + a * psi_bar * YAcropO,
  # -- emissions satellite (one-way) --
  LAo ~ a * LAbar,
  dN2O ~ ghg_n2o_syn0 * (F / Fbar - 1),
  # phi scales both green-manure terms, as in soc_extend() (no effect at phi = 1)
  dN2Ogm ~ ghg_n2o_gm0 * (LAo / LAbar) * phi,
  dCH4 ~ ghg_ch4_pad0 * (LAo / LAbar) * ch4_uplift * phi,
  # two-pool soil carbon, deviation from BAU [N20]
  SOCp ~ SOCp[-1] + phi * iota_paddy * (sA_rice * LAo) - k_paddy * SOCp[-1],
  SOCu ~ SOCu[-1] + phi * iota_upland * ((1 - sA_rice) * LAo) - k_upland * SOCu[-1],
  dSOC ~ (SOCp - SOCp[-1]) + (SOCu - SOCu[-1]),
  dCO2soc ~ -gamma_soc * dSOC,
  GHGnet ~ dN2O + dN2Ogm + dCH4 + dCO2soc,
  PREM ~ prem_bar * (a * psi_bar * YAcropO) * prem_on,
  # -- investment and capital --
  rA ~ (YA - WA - pF * F - zeta * KA[-1]) / KA[-1],
  IA ~ kappa0 + kappa1 * ((YA - YA[-1]) / KA[-1]) + kappa2 * rA + kappa3 * Sub_I,
  KA ~ KA[-1] + IA - zeta * KA[-1],
  IN_ ~ zeta * KNbar,
  YN ~ Cn + IA + IN_ + Gn + X,
  WN ~ w * YN / prN,
  # -- fixed food demand, imports close the balance [N06] --
  IMfood ~ Dbar - YA,
  Cf ~ YA + IMfood - Ga + YL + PREM,
  PiA ~ YA - WA - pF * F - zeta * KA[-1] + Sub_I + PREM,
  PiN ~ YN - WN - zeta * KNbar,
  W_ ~ WA + WN + WL,
  Pi ~ PiA + PiN + PiL,
  TX ~ tau * (W_ + Pi),
  # BAU stock earns r_avg, the deviation earns r_marg [N02]
  INF ~ r_avg * NFA_star + r_marg * (NFA[-1] - NFA_star),
  INB ~ r_B * B[-1],
  YD ~ W_ + Pi - TX + INF + INB,
  C ~ c1 * YD + c2 * V[-1],
  Cn ~ C - Cf,
  CAB ~ X_ag - pF * F - IMfood + NX_other + INF,
  NFA ~ NFA[-1] + CAB,
  B ~ B[-1] + (Ga + Gn + Sub_I + INB - TX),
  V ~ KA + KNbar + B + NFA,
  Vh ~ Vh[-1] + (YD - C) # hidden equation (Walras check)
)

# sfcr evaluates formulas lazily, so parameters are written in as literals
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
# soc = FALSE for the four-crop model, which has no soil carbon pools [N23]
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

# =============================================================================
# Scenarios
#   Linear ramps with a kink at 2030. Paths are written in as literal vectors
#   because sfcr shocks cannot hold time-indexed formulas.
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

# Government balance, using the solved interest bill INB
gov_bal <- function(s, t = Y2050) s$TX[t] - (W$Ga + W$Gn + s$INB[t])

# =============================================================================
# Results for 2050
# =============================================================================

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

# -- 3-bis. Fiscal balance --
cat(sprintf(
  "S1 dFISC %+.4f (%+.4f tn JPY/yr)   S2 dFISC %+.4f (%+.4f tn JPY/yr)\n",
  gov_bal(s1) - gov_bal(bau), (gov_bal(s1) - gov_bal(bau)) * unit_tn,
  gov_bal(s2) - gov_bal(bau), (gov_bal(s2) - gov_bal(bau)) * unit_tn
))
cat(sprintf(
  "CONVERSION fiscal (S2-S1) %+.4f (%+.4f tn JPY/yr)   dB %+.4f (%+.3f tn JPY)\n",
  gov_bal(s2) - gov_bal(s1), (gov_bal(s2) - gov_bal(s1)) * unit_tn,
  s2$B[Y2050] - s1$B[Y2050], (s2$B[Y2050] - s1$B[Y2050]) * unit_tn
))

# -- 3-ter. Decomposition: dCAB = -pF*dF + dYA + r_marg*dNFA[-1], dF = 0 [N18]
dNFA_lag <- s2$NFA[Y2050 - 1] - s1$NFA[Y2050 - 1]
int_term <- r_marg_v * dNFA_lag
cat(sprintf(
  "DECOMPOSITION output %+.4f (%.1f%%) | interest on lost NFA %+.4f (%.1f%%)  [dF = %+.2e]\n",
  CONV - int_term, 100 * abs(CONV - int_term) / abs(CONV),
  int_term, 100 * abs(int_term) / abs(CONV),
  s2$F[Y2050] - s1$F[Y2050]
))

cat(sprintf("S1 dGHG  %+.6f Mt-CO2eq/yr\n", d2050(s1, "GHGnet")))
cat(sprintf(
  "S2 dGHG  %+.6f Mt-CO2eq/yr [syn %+.6f | gm %+.6f | CH4 %+.6f | SOC %+.6f]\n",
  d2050(s2, "GHGnet"), s2$dN2O[Y2050],
  s2$dN2Ogm[Y2050], s2$dCH4[Y2050], s2$dCO2soc[Y2050]
))
cat(sprintf(
  "   SOC gain %.3f MtC | equilibrium dGHG %+.6f Mt-CO2eq/yr (sink -> 0)\n",
  (s2$SOCp[Y2050] + s2$SOCu[Y2050]) * A_ha_v / 1e6,
  s2$dN2O[Y2050] + s2$dN2Ogm[Y2050] + s2$dCH4[Y2050]
))
cat(sprintf(
  "2030 checkpoint (S2): dCAB %+.4f  dGHG %+.6f Mt-CO2eq/yr\n",
  d2050(s2, "CAB", Y2030), d2050(s2, "GHGnet", Y2030)
))
for (nm in c("S1", "S2")) {
  cat(sprintf(
    "Walras leak %s %.4e\n",
    nm, max(abs(get(tolower(nm))$V[-1] - get(tolower(nm))$Vh[-1]))
  ))
}

# =============================================================================
# Greenhouse gas balance after 2050 [N07, N22]
#   Soil carbon is a stock that saturates; CH4 and N2O are flows that persist.
#   After 2050 the reservoir is a linear recursion, so no solver is needed.
#   a_end continues the organic ramp past 2050 up to a_end.
# =============================================================================
slope_a <- (A50 - A30) / (Y2050 - Y2030)

soc_extend <- function(Tend = 250, phi = phi_v, iota_p = iota_paddy_v,
                       iota_u = iota_upland_v, upl = ch4_uplift_v,
                       a_end = A50, maff_rate = maff_rate_v,
                       gm0 = ghg_n2o_gm0_v) {
  sp <- 0
  su <- 0
  g <- rep(NA_real_, Tend)
  soc <- g; sink <- g; n1 <- g; n2 <- g; c4 <- g; maff <- g
  for (t in 2:Tend) {
    pi_ <- if (t <= TERM) ramp(t, v30 = PI30, v50 = PI50) else PI50
    a <- if (t <= TERM) {
      ramp(t, v30 = A30, v50 = A50)
    } else {
      min(A50 + slope_a * (t - Y2050), a_end)
    }
    LAo <- a * LAbar_v
    e <- ghg_n2o_syn0_v * (-pi_) + gm0 * (LAo / LAbar_v) * phi +
      ghg_ch4_pad0_v * (LAo / LAbar_v) * upl * phi
    npx <- (1 - k_paddy_v) * sp + phi * iota_p * (sA_rice * LAo)
    nux <- (1 - k_upland_v) * su + phi * iota_u * ((1 - sA_rice) * LAo)
    sink[t] <- gamma_soc_v * ((npx - sp) + (nux - su))
    n1[t] <- ghg_n2o_syn0_v * (-pi_)
    n2[t] <- gm0 * (LAo / LAbar_v) * phi
    c4[t] <- ghg_ch4_pad0_v * (LAo / LAbar_v) * upl * phi
    maff[t] <- maff_rate * (LAo * A_ha_v) / 1e6 # scheme: constant rate on converted area
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
  ext_ph <- soc_extend(phi = ph)
  cum <- cumsum(ifelse(is.na(ext_ph$dGHG), 0, ext_ph$dGHG))
  EMperm_ph <- ghg_n2o_syn0_v * (-PI50) + ghg_n2o_gm0_v * A50 * ph +
    ghg_ch4_pad0_v * A50 * ch4_uplift_v * ph
  cat(sprintf(
    "  phi %.4f: dGHG2050 %+9.4f | annual cross %.1f | cumulative cross %d\n",
    ph, ext_ph$dGHG[Y2050], cross_up(ext_ph$dGHG, ext_ph$year),
    ext_ph$year[which(cum > 0)[1]]
  ))
  cat(sprintf(
    "             equilibrium dGHG %+.6f Mt-CO2eq/yr (PERMANENT)\n",
    EMperm_ph
  ))
}

# -- 4-ter. Organic ramp continued after 2050 (Section 6.4) --
cat("\n=== 4-ter. ramp termination: crossing year by terminal organic share ===\n")
for (ae in c(A50, 0.354, 0.50)) {
  ext_a <- soc_extend(a_end = ae)
  cat(sprintf(
    "  a_end %.4f (reached %.1f): annual cross %.1f | dGHG2050 %+.4f\n",
    ae, YEAR0 + Y2050 + (ae - A50) / slope_a,
    cross_up(ext_a$dGHG, ext_a$year), ext_a$dGHG[Y2050]
  ))
}

# =============================================================================
# Figure 2: this model against the direct payment scheme's convention [N22]
# =============================================================================
ext <- soc_extend()
tcross <- cross_up(ext$dGHG, ext$year)
EMperm <- ghg_n2o_syn0_v * (-PI50) + ghg_n2o_gm0_v * A50 +
  ghg_ch4_pad0_v * A50 * ch4_uplift_v
fg <- ext %>% filter(year >= 2020, year <= 2100)

comp <- fg %>%
  transmute(
    year,
    `Paddy CH4` = dCH4,
    `Green-manure N2O` = dN2Ogm,
    `Synthetic-fertiliser N2O` = dN2O,
    `Soil carbon (transient)` = -sink
  ) %>%
  pivot_longer(-year, names_to = "component")
comp$component <- factor(comp$component, levels = c(
  "Paddy CH4", "Green-manure N2O", "Synthetic-fertiliser N2O",
  "Soil carbon (transient)"
))

LAB_MODEL <- "This model (three gases, soil carbon as a stock)"
LAB_MAFF  <- "Direct payment convention (soil CO2 only, constant rate)"

nets <- bind_rows(
  fg %>% transmute(year, value = dGHG,      conv = LAB_MODEL),
  fg %>% transmute(year, value = dGHG_maff, conv = LAB_MAFF)
)

p_soc <- ggplot() +
  geom_area(data = comp %>% filter(value >= 0),
            aes(year, value, fill = component), position = "stack") +
  geom_area(data = comp %>% filter(value < 0),
            aes(year, value, fill = component), position = "stack") +
  geom_hline(yintercept = 0, linewidth = 0.4, colour = "grey30") +
  geom_hline(yintercept = EMperm, linetype = 3, linewidth = 0.5, colour = "grey30") +
  geom_vline(xintercept = 2050, linetype = 2, linewidth = 0.4, colour = "grey50") +
  geom_vline(xintercept = tcross, linetype = 2, linewidth = 0.4, colour = "grey50") +
  geom_line(data = nets, aes(year, value, colour = conv), linewidth = 1) +
  annotate("text", x = 2050, y = 3.25, label = "KPI target year", hjust = 1.05,
           size = 3, colour = "grey35") +
  annotate("text", x = tcross, y = 3.25,
           label = sprintf("annual balance turns positive (%d)", as.integer(ceiling(tcross))),
           hjust = -0.05, size = 3, colour = "grey35") +
  annotate("text", x = 2100, y = EMperm,
           label = sprintf("permanent %+.2f", EMperm),
           hjust = 1.02, vjust = -0.6, size = 3, colour = "grey35") +
  scale_x_continuous(breaks = seq(2020, 2100, 20)) +
  scale_y_continuous(breaks = seq(-3, 3.5, 0.5)) +
  scale_fill_manual(values = c(
    "Paddy CH4" = "#D1495B", "Green-manure N2O" = "#EDAE49",
    "Synthetic-fertiliser N2O" = "#3E7CB1",
    "Soil carbon (transient)" = "#66A182"
  )) +
  scale_colour_manual(values = setNames(c("grey10", "grey45"),
                                        c(LAB_MODEL, LAB_MAFF))) +
  guides(
    fill = guide_legend(order = 1, nrow = 2),
    colour = guide_legend(order = 2, nrow = 2)
  ) +
  labs(
    x = NULL, y = "Annual GHG change vs BAU (Mt-CO2eq/yr)",
    fill = NULL, colour = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.box = "vertical",
        legend.spacing.y = unit(0, "pt"))

print(p_soc)
dir.create("figures", showWarnings = FALSE)
ggsave("figures/fig_soc_crossover.png", p_soc, width = 9, height = 5.6, dpi = 300)

cat(sprintf(
  "  scheme convention at 2050: %+.6f Mt/yr vs this model %+.6f Mt/yr\n",
  ext$dGHG_maff[Y2050], ext$dGHG[Y2050]
))
cat(sprintf(
  "  scheme convention is a CONSTANT rate: still %+.3f Mt/yr in 2100; this model %+.3f\n",
  ext$dGHG_maff[ext$year == 2100], ext$dGHG[ext$year == 2100]
))
# First-period coefficient (MAFF, 2019), for reference only
ext_093 <- soc_extend(maff_rate = 0.93)
cat(sprintf(
  "  [first-period coefficient 0.93 for reference: %+.6f Mt/yr at 2050]\n",
  ext_093$dGHG_maff[Y2050]
))

# =============================================================================
# Sensitivity and robustness [N08]
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

# -- 7.1 Organic yield ratio [N09] --
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

# -- 7.2 Marginal interest rate --
cat("\n=== 7.2 r_marg sweep ===\n")
for (rm in r_marg_band) {
  rr <- run_pair(rmarg = rm)
  cat(sprintf(
    "  r_marg %.5f -> conversion dCAB %+.4f   S2 dNFA %+.4f\n",
    rm, rr$conv, rr$x2$NFA[Y2050] - rr$b$NFA[Y2050]
  ))
}

# -- 7.3 Average return on NFA [N02] --
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

# -- 7.4 Paddy methane uplift, varied with green-manure N [N10] --
cat("\n=== 7.4 GHG reversal: ch4_uplift break-even over the nu_O band ===\n")
gm0_of <- function(nu, eps = epsN_gm_v) {
  eps * nu * LAbar_v * (ghg_n2o_syn0_v / (epsN_bar_v * Fbar_v))
}
# Permanent change: flow terms only, since soil carbon is zero at equilibrium [N22]
ghg_at <- function(u, gm0 = ghg_n2o_gm0_v) {
  b <- sfcr_baseline(eqs, mk_external(ch4_uplift = u, ghg_n2o_gm0 = gm0),
                     TERM, mk_initial(),
                     hidden = c("V" = "Vh"), method = "Broyden"
  )
  x <- sfcr_scenario(b, shock_S2, TERM)
  (x$dN2O[Y2050] + x$dN2Ogm[Y2050] + x$dCH4[Y2050]) -
    (b$dN2O[Y2050] + b$dN2Ogm[Y2050] + b$dCH4[Y2050])
}
be_ch4_central <- NA_real_ # break-even at the central nu_O, used in 7.4-bis
for (nu in c(nu_O_band[1], nu_O_v, nu_O_band[2])) {
  gm0 <- gm0_of(nu)
  uA <- ch4_route_A(nu)
  be <- uniroot(function(u) ghg_at(u, gm0), c(0, 1.6), tol = 1e-8)$root
  if (isTRUE(all.equal(nu, nu_O_v))) be_ch4_central <- be
  cat(sprintf(
    "  nu_O %.4f: gm N2O %7.4f | route A %.4f | break-even %.6f | margin %5.2fx\n",
    nu, gm0 * A50, uA, be, uA / be
  ))
}

# -- 7.4-bis Methane countermeasures required by the direct payment scheme --
#    (MAFF, 2025). Reduction m gives an effective uplift (1+u)(1-m)-1. Applied
#    to all converted land, this is an upper bound [N15].
cat("\n=== 7.4-bis scheme methane countermeasures as an effective uplift ===\n")
m_list <- c(
  "autumn tillage (10%)"                   = 0.10,
  "prolonged midseason drainage (30%)"     = 0.30,
  "no flooding preceding year (34%)"       = 0.34,
  "drainage + autumn tillage (multiplic.)" = 1 - 0.70 * 0.90,
  "no flooding + drainage (multiplic.)"    = 1 - 0.66 * 0.70
)
for (nm in names(m_list)) {
  m  <- m_list[[nm]]
  ue <- (1 + ch4_uplift_v) * (1 - m) - 1
  eq <- ghg_at(ue)
  cat(sprintf(
    "  %-40s m %.3f -> uplift %.6f | equilibrium dGHG %+.6f | vs break-even %.2fx\n",
    nm, m, ue, eq, ue / be_ch4_central
  ))
}
m_rev <- 1 - (1 + be_ch4_central) / (1 + ch4_uplift_v)
cat(sprintf(
  "  reduction required to reverse the permanent sign: %.2f%% (max single measure 34%%)\n",
  100 * m_rev
))
for (m in c(0.30, 0.34)) {
  ue <- (1 + ch4_uplift_v) * (1 - m) - 1
  e  <- soc_extend(upl = ue)
  cat(sprintf("  m %.2f -> annual cross %.1f\n", m, cross_up(e$dGHG, e$year)))
}

# -- 7.5 Green-manure N2O emission factor [N10] --
cat("\n=== 7.5 epsN_gm band [ratio-transfer | Xie raw | paddy EF] ===\n")
for (eps in epsN_gm_band) {
  for (nu in c(nu_O_band[1], nu_O_v)) {
    gm0 <- gm0_of(nu, eps)
    uA <- ch4_route_A(nu)
    be <- uniroot(function(u) ghg_at(u, gm0), c(0, 1.6), tol = 1e-8)$root
    cat(sprintf(
      "  epsN_gm %.5f  nu_O %.4f: break-even %.6f | route A %.4f | margin %5.2fx\n",
      eps, nu, be, uA, uA / be
    ))
  }
}

# -- 7.6 Rice yield ratio --
cat("\n=== 7.6 psi_rice diagnostic ===\n")
psi_bar_at_rice <- function(pr) {
  w_rice * pr + w_veg * psi_veg + w_fruit * psi_fruit + w_other * psi_other
}
psi_rice_tests <- c(
  "0.720" = "Tottori 2011-13 [ADOPTED]",
  "0.940" = "de Ponti Tab.1 rice, n=7 [band upper]"
)
for (i in seq_along(psi_rice_tests)) {
  pr <- as.numeric(names(psi_rice_tests)[i])
  pb <- psi_bar_at_rice(pr)
  cat(sprintf(
    "  psi_rice %.3f -> psi_bar %.6f, conversion dCAB %+.4f   %s\n",
    pr, pb, run_pair(psi_bar = pb)$conv, psi_rice_tests[i]
  ))
}

# -- 7.6-bis Soil carbon raising rice yield, as an upper bound (Section 6.4) --
#    h multiplies psi_rice; 1.05 is the largest gain supported by Ma et al.
#    (2023). dGHG does not depend on psi_bar.
cat("\n=== 7.6-bis SOC->yield feedback: exogenous upper bound (rice only) ===\n")
for (h in c(1.011, 1.05)) {
  pb_h <- psi_bar_at_rice(psi_rice * h)
  rr_h <- run_pair(psi_bar = pb_h)
  cat(sprintf(
    "  h_rice %.3f -> psi_rice %.4f, psi_bar %.6f: dCAB %+.4f (%.1f%% smaller)  dGHG dev %+.2e\n",
    h, psi_rice * h, pb_h, rr_h$conv, 100 * (1 - rr_h$conv / CONV),
    rr_h$ghg - (s2$GHGnet[Y2050] - bau$GHGnet[Y2050])
  ))
}
be_rice <- psi_rice + (be_psi - psi_bar_LO) / w_rice
cat(sprintf(
  "  BREAK-EVEN psi_rice = %.6f  (> 1: outside the domain of a yield ratio)\n",
  be_rice
))
# h at which rice overtakes other arable crops as the cheapest to convert [N13]
h_rank <- (1 - (w_other * (1 - psi_other) / sA_other) * sA_rice / w_rice) / psi_rice
cat(sprintf(
  "  ranking reversal (rice becomes cheapest) at h_rice = %.4f  (outside the 1.05 bound)\n",
  h_rank
))

# -- 7.7 Conventional yield loss at -30% N [N11] --
cat("\n=== 7.7 conventional yield loss at -30% N: bound vs calibration ===\n")
loss_lin <- 1 - (355 + 0.7 * (516 - 355)) / 516
loss_li <- 1 - (1 - beta_v * exp(-gamma_v * 70)) / (1 - beta_v * exp(-gamma_v * 100))
cat(sprintf(
  "  linear limit (max under Mitscherlich) %.4f%%   calibrated %.4f%% (%.0f%% of max)\n",
  100 * loss_lin, 100 * loss_li, 100 * loss_li / loss_lin
))

# -- 7.8 Behavioural parameters: the closure is re-solved for each [N03] --
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

# kappa1 and kappa3 are outside the closure; kappa3 multiplies Sub_I = 0
for (nm in c("kappa1", "kappa3")) {
  vv <- if (nm == "kappa1") 0.4 else 1.0
  cat(sprintf(
    "  %-7s = %-5s (outside the closure)      -> deviation %+.2e%s\n",
    nm, vv, do.call(run_pair, setNames(list(vv), nm))$conv - CONV,
    if (nm == "kappa3") "  <- VACUOUS: Sub_I = 0" else ""
  ))
}
cat(
  "  -> all |deviation| <= ~1.2e-13. Also invariant: r_avg, NFA_pct,\n",
  "     primary_pct, m_c, Dbar, tau, prem_c, WL/PiL, and (quasi) m0.\n"
)

# -- 7.9 Full KPI area: 1,000,000 ha on the 2,824,246 ha base (Section 4.6) [N21]
cat("\n=== 7.9 full KPI area ===\n")
a_full <- 1e6 / 2824246
a_path_full <- ramp(tt, v30 = A30, v50 = a_full)
shock_S2_full <- sfcr_shock(sfcr_set(
  eval(bquote(pi_ ~ .(pi_path))),
  eval(bquote(a ~ .(a_path_full)))
), Y2022, TERM)
s2_full <- sfcr_scenario(bau, shock_S2_full, TERM)
conv_full <- s2_full$CAB[Y2050] - s1$CAB[Y2050]
cat(sprintf(
  "  a_full %.6f -> conversion dCAB %+.6f (x%.4f of the headline)\n",
  a_full, conv_full, conv_full / CONV
))

# =============================================================================
# Figure 1: current account, net foreign assets and government balance
# =============================================================================
dir.create("figures", showWarnings = FALSE)

plotdat <- bind_rows(list(S1 = s1, S2 = s2), .id = "scn") %>%
  filter(period > 1) %>%
  mutate(bauNFA = bau$NFA[period]) %>%
  transmute(
    year = YEAR0 + period, scn,
    # BAU current account and government balance are zero, so levels = change vs BAU
    `(a) Current account vs BAU (tn JPY/yr)`    = CAB * unit_tn,
    `(b) Net foreign assets vs BAU (tn JPY)`    = (NFA - bauNFA) * unit_tn,
    `(c) Government balance vs BAU (tn JPY/yr)` = (TX - (W$Ga + W$Gn + INB)) * unit_tn
  ) %>%
  pivot_longer(-c(year, scn))
plotdat$name <- factor(plotdat$name, levels = c(
  "(a) Current account vs BAU (tn JPY/yr)", "(b) Net foreign assets vs BAU (tn JPY)",
  "(c) Government balance vs BAU (tn JPY/yr)"
))

ggplot(plotdat, aes(year, value, colour = scn)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey70") +
  geom_line(linewidth = 0.9) +
  facet_wrap(~name, scales = "free_y", nrow = 1) +
  scale_colour_manual(values = c(S1 = "#3E7CB1", S2 = "#D1495B")) +
  labs(x = NULL, y = NULL, colour = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.spacing = unit(1, "lines"))
ggsave("figures/fig_core_headline.png", width = 9, height = 3.2, dpi = 300)


# #################### PART B - FOUR-CROP MODEL ####################
#
# The same model by crop. With every crop converted equally it reproduces
# Part A exactly [N12]. No soil carbon pools: dGHG is the permanent change [N23].

# =============================================================================
# Equations
# =============================================================================

eqs4 <- sfcr_set(
  areaO ~ sA_rice * a_rice + sA_veg * a_veg + sA_fruit * a_fruit + sA_other * a_other,
  Fint ~ (1 - pi_) * Fbar / (1 - areaO),
  F ~ Fint * (1 - areaO),
  gC ~ 1 - beta * exp(-gamma * Fint),
  YA_rice ~ 100 * w_rice * ((1 - a_rice) * (gC / gfull) + a_rice * psi_rice),
  YA_veg ~ 100 * w_veg * ((1 - a_veg) * (gC / gfull) + a_veg * psi_veg),
  YA_fruit ~ 100 * w_fruit * ((1 - a_fruit) * (gC / gfull) + a_fruit * psi_fruit),
  YA_other ~ 100 * w_other * ((1 - a_other) * (gC / gfull) + a_other * psi_other),
  YA ~ YA_rice + YA_veg + YA_fruit + YA_other,
  dN2O ~ ghg_n2o_syn0 * (F / Fbar - 1),
  dN2Ogm ~ ghg_n2o_gm0 * areaO,
  dCH4 ~ ghg_ch4_pad0 * a_rice * ch4_uplift,
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
# Allocations of the 25% area target
#   Every allocation meets sum(sA_c * a_c) = 25%; they differ in which land converts.
# =============================================================================
abar_path <- ramp(tt, v30 = A30, v50 = A50)

# Import value induced per hectare converted [N13]
cost_c <- w_c * (1 - psi_c) / sA_c
cat("\n=== import cost per unit area converted (lower = cheaper) ===\n")
print(round(sort(cost_c), 4))

# Converts crops in the given order, each up to CAP of its own area
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
  "Every crop equally"         = setNames(rep(A50, 4), crops),
  "Other arable crops first"   = fill_alloc(by_cost),
  "Vegetables and fruit first" = fill_alloc(rev(by_cost)),
  "Rice only"                  = fill_alloc(c("rice", "other", "fruit", "veg")),
  "No rice"                    = fill_alloc(by_cost_norice)
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
# Allocation results (Table 4) [N14]
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

# Relative to S1: S1 has no organic land, so one run serves all five
s1_4   <- run_alloc(setNames(rep(0, 4), crops))
s1_cab <- s1_4$CAB[Y2050] - bau4$CAB[Y2050]
res <- res %>% mutate(dCAB_vsS1 = dCAB_2050 - s1_cab)
cat(sprintf("S1 (Part B) dCAB %+.4f | core %+.4f\n", s1_cab, d2050(s1, "CAB")))
print(as.data.frame(res %>% transmute(allocation,
                                      dCAB_vsBAU_tn = round(dCAB_2050 * unit_tn, 3),
                                      dCAB_vsS1_tn  = round(dCAB_vsS1 * unit_tn, 3))))

cat("\n=== 9. allocations (25% AREA target; dGHG = PERMANENT annual) ===\n")
print(as.data.frame(res %>% mutate(across(where(is.numeric), ~ round(., 3)))))

uni <- res %>% filter(allocation == "Every crop equally")
dom <- res %>% filter(allocation == "No rice")
# Every crop converted equally must reproduce Part A
cat(sprintf(
  "\nCONSISTENCY uniform %+.8f vs core %+.8f (diff %.2e)\n",
  uni$dCAB_2050, d2050(s2, "CAB"), abs(uni$dCAB_2050 - d2050(s2, "CAB"))
))
cat(sprintf(
  "DOMINANCE no rice (%+.3f, %+.2f) vs every crop equally (%+.3f, %+.2f) -> %s\n",
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

cat("\n=== 10. CAP robustness ===\n")
max_norice <- sum(sA_c[setdiff(crops, "rice")])
for (capv in c(0.50, 0.75, 1.00)) {
  if (capv * max_norice < A50 - 1e-9) {
    cat(sprintf(
      "  CAP %.2f: no rice INFEASIBLE (%.3f < %.2f) -- itself a finding\n",
      capv, capv * max_norice, A50
    ))
    next
  }
  ps <- run_alloc(fill_alloc(by_cost_norice, cap = capv))
  cat(sprintf(
    "  CAP %.2f: every crop equally (%+.3f, %+.2f)  no rice (%+.3f, %+.2f)  dominates %s\n",
    capv, uni$dCAB_2050, uni$dGHG_2050,
    ps$CAB[Y2050] - bau4$CAB[Y2050], ps$GHGnet[Y2050],
    ifelse(ps$CAB[Y2050] - bau4$CAB[Y2050] > uni$dCAB_2050 &&
             ps$GHGnet[Y2050] < uni$dGHG_2050, "yes", "NO")
  ))
}

# =============================================================================
# Allocation frontier: rice share of the target, rest filled by cost [N16]
#   The turning point is 1 - CAP * sA_other / A50.
# =============================================================================
cat(sprintf(
  "  analytic turning point fr* = 1 - CAP*sA_other/A50 = %.6f\n",
  1 - CAP * sA_other / A50
))
frontier <- map_dfr(
  c(0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.27, 0.277312, 0.285, 0.30, 0.40, 0.50, 0.75, 1.0),
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
# Figure 3: allocation frontier [N17]
# =============================================================================

# Current account relative to S1 (the conversion effect), as in the text
fr_p <- frontier %>%
  transmute(
    x = dGHG_2050, y = (dCAB_2050 - s1_cab) * unit_tn,
    lab = ifelse(rice_share %in% c(0, 0.50, 1.0),
                 sprintf("%.0f%%", 100 * rice_share), NA_character_)
  )
elbow <- fr_opt %>% transmute(x = dGHG_2050, y = (dCAB_2050 - s1_cab) * unit_tn)

p_tr <- ggplot(mapping = aes(x, y)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey70") +
  geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey70") +
  geom_path(data = fr_p, colour = "grey55", linewidth = 0.7) +
  geom_point(data = fr_p, colour = "grey45", size = 2.2) +
  geom_point(data = elbow, colour = "#D1495B", size = 4.5, shape = 21,
             fill = "white", stroke = 1.3) +
  geom_text_repel(
    data = fr_p %>% filter(!is.na(lab)), aes(label = lab),
    size = 3.2, colour = "grey35", box.padding = 0.5,
    min.segment.length = 0, seed = 20260807
  ) +
  geom_text_repel(
    data = elbow, aes(label = "27.7%: largest\ncurrent-account gain"),
    size = 3.2, colour = "#D1495B", box.padding = 1.2,
    nudge_y = 0.03, min.segment.length = 0, seed = 20260807
  ) +
  scale_y_continuous(breaks = seq(-0.10, 0.10, 0.05)) +
  labs(
    x = "Permanent annual GHG change vs BAU (Mt-CO2eq/yr; + = worse)",
    y = "Current-account change vs S1, 2050 (tn JPY/yr; - = worse)"
  ) +
  theme_minimal(base_size = 12)

print(p_tr)
ggsave("figures/fig_allocation_frontier.png", p_tr, width = 7.5, height = 5.5, dpi = 300)


# #################### PART C - NUMBERS FOR THE TEXT ####################
#
# Every number quoted in the thesis is written to results/ from this run, so
# text, tables and figures come from one code version [N26]. Each row states
# its comparison: S1 vs BAU, S2 vs BAU, or S2 - S1 (the conversion effect).

dir.create("results", showWarnings = FALSE)

pct_gdp <- function(tn) 100 * tn / nominal_GDP # 2017-19 nominal GDP (Cabinet Office, 2025)
cum_to <- function(e, y) sum(e$dGHG[e$year <= y], na.rm = TRUE)
first_cum_pos <- function(e) {
  e$year[which(cumsum(replace(e$dGHG, is.na(e$dGHG), 0)) > 0)[1]]
}
perm_of <- function(u = ch4_uplift_v, gm0 = ghg_n2o_gm0_v, phi = 1) {
  ghg_n2o_syn0_v * (-PI50) + gm0 * A50 * phi + ghg_ch4_pad0_v * A50 * u * phi
}

# S1 has no organic land: only synthetic N2O changes
s1_ghg_cum2050 <- sum(ghg_n2o_syn0_v * (-ramp(1:TERM, v30 = PI30, v50 = PI50)))
s2_ghg_cum2050 <- cum_to(ext, 2050)
s2_ghg_cum2100 <- cum_to(ext, 2100)

conv_ha <- A50 * LAbar_v * A_ha_v                # converted hectares in 2050
conv_paddy_ha <- sA_rice * conv_ha
sink_per_ha <- 1e6 * ext$sink[Y2050] / conv_ha   # tCO2/ha/yr in 2050
ch4_per_paddy_ha <- 1e6 * s2$dCH4[Y2050] / conv_paddy_ha
rice_only <- res %>% filter(allocation == "Rice only")
rice_only_ch4 <- ghg_ch4_pad0_v * rice_only$a_rice * ch4_uplift_v

cab <- function(s) d2050(s, "CAB") * unit_tn
nfa <- function(s) d2050(s, "NFA") * unit_tn
fisc <- function(s) (gov_bal(s) - gov_bal(bau)) * unit_tn
ghg <- function(s) d2050(s, "GHGnet")

srow <- function(metric, comparison, value, unit, pct = NA_real_, pct_of = "") {
  tibble(metric, comparison, value, unit, pct, pct_of)
}
summary_2050 <- bind_rows(
  srow("Current account, 2050", "S1 vs BAU", cab(s1), "tn JPY/yr", pct_gdp(cab(s1)), "GDP"),
  srow("Current account, 2050", "S2 vs BAU", cab(s2), "tn JPY/yr", pct_gdp(cab(s2)), "GDP"),
  srow("Current account, 2050", "S2 - S1", cab(s2) - cab(s1), "tn JPY/yr",
      pct_gdp(cab(s2) - cab(s1)), "GDP"),
  srow("Conversion effect: lost output", "S2 - S1", (CONV - int_term) * unit_tn, "tn JPY/yr",
      100 * (CONV - int_term) / CONV, "conversion effect"),
  srow("Conversion effect: lost interest on NFA", "S2 - S1", int_term * unit_tn, "tn JPY/yr",
      100 * int_term / CONV, "conversion effect"),
  srow("Net foreign assets, 2050", "S1 vs BAU", nfa(s1), "tn JPY", pct_gdp(nfa(s1)), "GDP"),
  srow("Net foreign assets, 2050", "S2 vs BAU", nfa(s2), "tn JPY", pct_gdp(nfa(s2)), "GDP"),
  srow("Net foreign assets, 2050", "S2 - S1", nfa(s2) - nfa(s1), "tn JPY",
      pct_gdp(nfa(s2) - nfa(s1)), "GDP"),
  srow("Government balance, 2050", "S1 vs BAU", fisc(s1), "tn JPY/yr", pct_gdp(fisc(s1)), "GDP"),
  srow("Government balance, 2050", "S2 vs BAU", fisc(s2), "tn JPY/yr", pct_gdp(fisc(s2)), "GDP"),
  srow("Government balance, 2050", "S2 - S1", fisc(s2) - fisc(s1), "tn JPY/yr",
      pct_gdp(fisc(s2) - fisc(s1)), "GDP"),
  srow("Annual GHG, 2050", "S1 vs BAU", ghg(s1), "Mt CO2-eq/yr"),
  srow("Annual GHG, 2050", "S2 vs BAU", ghg(s2), "Mt CO2-eq/yr"),
  srow("Annual GHG, 2050", "S2 - S1", ghg(s2) - ghg(s1), "Mt CO2-eq/yr"),
  srow("  synthetic-fertiliser N2O", "S2 vs BAU", s2$dN2O[Y2050], "Mt CO2-eq/yr"),
  srow("  green-manure N2O", "S2 vs BAU", s2$dN2Ogm[Y2050], "Mt CO2-eq/yr"),
  srow("  paddy CH4", "S2 vs BAU", s2$dCH4[Y2050], "Mt CO2-eq/yr",
      100 * s2$dCH4[Y2050] / ghg_ch4_pad0_v, "national paddy CH4"),
  srow("  soil carbon", "S2 vs BAU", s2$dCO2soc[Y2050], "Mt CO2-eq/yr"),
  srow("Permanent annual GHG (soil carbon saturated)", "S2 vs BAU", EMperm, "Mt CO2-eq/yr"),
  srow("Cumulative GHG 2019-2050", "S1 vs BAU", s1_ghg_cum2050, "Mt CO2-eq"),
  srow("Cumulative GHG 2019-2050", "S2 vs BAU", s2_ghg_cum2050, "Mt CO2-eq"),
  srow("Cumulative GHG 2019-2050", "S2 - S1", s2_ghg_cum2050 - s1_ghg_cum2050, "Mt CO2-eq"),
  srow("Cumulative GHG 2019-2100", "S2 vs BAU", s2_ghg_cum2100, "Mt CO2-eq"),
  srow("First year with annual GHG above BAU", "S2 vs BAU", ceiling(tcross), "year"),
  srow("First year with cumulative GHG above BAU", "S2 vs BAU", first_cum_pos(ext), "year"),
  srow("Scheme convention, 2050", "S2 vs BAU", ext$dGHG_maff[Y2050], "Mt CO2-eq/yr"),
  srow("Scheme convention, cumulative 2019-2050", "S2 vs BAU",
      sum(ext$dGHG_maff[ext$year <= 2050], na.rm = TRUE), "Mt CO2-eq"),
  srow("Soil carbon sink per converted ha, 2050", "S2 vs BAU", sink_per_ha, "t CO2/ha/yr",
      100 * sink_per_ha / maff_rate_v, "scheme rate 1.04"),
  srow("Paddy CH4 increase per converted paddy ha", "S2 vs BAU", ch4_per_paddy_ha,
      "t CO2-eq/ha/yr"),
  srow("Rice-only allocation: paddy CH4", "S2 vs BAU", rice_only_ch4, "Mt CO2-eq/yr",
      100 * rice_only_ch4 / ghg_ch4_pad0_v, "national paddy CH4")
)
cat("\n=== 12. SUMMARY TABLE FOR 2050 (results/summary_2050.csv) ===\n")
print(as.data.frame(summary_2050 %>% mutate(value = signif(value, 5), pct = signif(pct, 4))),
      right = FALSE)
write_csv(summary_2050, "results/summary_2050.csv")

# -- 12-bis. Sign at the uplift bounds (route A over the green-manure N band) --
#    nu_O moves the uplift, the green-manure N2O and the soil carbon input together.
cat("\n=== 12-bis. GHG sign at the uplift bounds ===\n")
bounds <- map_dfr(c(nu_O_band[1], nu_O_v, nu_O_band[2]), function(nu) {
  iota_g <- nu * Fbar_kgN_v * CN_gm_v / 1000
  u <- ch4_route_A(nu)
  e <- soc_extend(iota_p = iota_g - resid_loss_paddy_v,
                  iota_u = iota_g - resid_loss_upland_v,
                  upl = u, gm0 = gm0_of(nu))
  tibble(
    nu_O = nu, uplift = u, dGHG_2050 = e$dGHG[Y2050],
    cum_2050 = cum_to(e, 2050), cum_2100 = cum_to(e, 2100),
    annual_cross = cross_up(e$dGHG, e$year, after = 2022),
    first_cum_positive = first_cum_pos(e),
    permanent = perm_of(u, gm0_of(nu))
  )
})
print(as.data.frame(bounds %>% mutate(across(where(is.numeric), ~ round(., 4)))))
write_csv(bounds, "results/ghg_uplift_bounds.csv")

cat("\n=== 12-ter. GHG under the scheme's methane countermeasures ===\n")
cmeas <- map_dfr(names(m_list), function(nm) {
  u <- (1 + ch4_uplift_v) * (1 - m_list[[nm]]) - 1
  e <- soc_extend(upl = u)
  tibble(
    measure = nm, reduction = m_list[[nm]], uplift = u,
    dGHG_2050 = e$dGHG[Y2050], cum_2050 = cum_to(e, 2050),
    cum_2100 = cum_to(e, 2100), permanent = perm_of(u)
  )
})
print(as.data.frame(cmeas %>% mutate(across(where(is.numeric), ~ round(., 4)))))
write_csv(cmeas, "results/ghg_countermeasures.csv")

# -- 12-quater. Fixed demand against the own-price elasticity (Section 4.3) --
#    Back-of-envelope only: the model has no consumer price. It shows how large
#    a price response would have to be to absorb the conversion shortfall.
eps_own <- -0.454 # uncompensated own-price elasticity, food excl. meals away from home (Haijima, 2021) [LIT]
dYA_conv <- s2$YA[Y2050] - s1$YA[Y2050]
short_pct <- -100 * dYA_conv / Dbar_v
prem_pct <- 100 * s2$PREM[Y2050] / Dbar_v
cat("\n=== 12-quater. fixed demand vs own-price elasticity (indicative) ===\n")
cat(sprintf("  conversion output shortfall 2050: %.4f index = %.3f%% of food demand Dbar\n",
            -dYA_conv, short_pct))
cat(sprintf("  price rise that would absorb it at eps %.3f: %.2f%%\n", eps_own, short_pct / abs(eps_own)))
cat(sprintf("  organic premium paid in S2, 2050: %.4f index = %.3f%% of Dbar -> demand %.3f%% at eps\n",
            s2$PREM[Y2050], prem_pct, prem_pct * eps_own))
cat("  -> the premium is not passed into quantities: fixed demand is a strong assumption.\n")
