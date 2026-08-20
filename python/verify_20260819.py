#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verify_20260819.py
Independent closed-form re-derivation of the GHG / SOC satellite of
esfc_midori_20260817.R, written from the R source *specification* (not from
shared numerical machinery), to close HANDOFF_2026-08-17 items:

  §7.1  "R re-run after the Fbar_kgN and resid_loss fixes"  -> pre-checks the
        satellite side of the pass/fail list in §4 so the R run only has to
        confirm, not discover.
  §7.1  "§7 stock/concentration quantification, re-computed"  -> §6.5 last row.

NOTE ON SCOPE.  The CAB / NFA figures are NOT recomputed here: they cannot
change.  GHGnet is a terminal node of the equation set (grep confirms it never
appears on any right-hand side), so the SOC reservoir is a one-way satellite
and every economic variable is algebraically invariant to it.  The §4 lines
marked "must not move" are guaranteed by construction, not by coincidence.
"""

# ---------------------------------------------------------------- parameters
YEAR0, TERM = 2018, 32
Y2022, Y2030, Y2050 = 4, 12, 32

sA_rice, sA_veg, sA_fruit, sA_other = 0.515, 0.163, 0.074, 0.248
epsN_rice, epsN_veg, epsN_fruit, epsN_other = 0.0031, 0.0062, 0.0062, 0.0062

Fbar = 100.0            # index
Fbar_kgN = 96.0         # kgN/ha            [JP-DATA] Toriyama 2002 Tab.3
LAbar = 100.0
nu_O = 1.1927083333
CN_gm = 17.1            # [LIT] Nagumo et al. 2014
epsN_gm = 0.0031

ghg_n2o_syn0 = 103.3459
ghg_ch4_pad0 = 1343.4926

k_paddy, k_upland = 0.046733, 0.033294
resid_loss_paddy, resid_loss_upland = 0.5847, 0.2007
phi_default = 1.0
A_ha = 28544.0

PI30, PI50 = 0.20, 0.30
A30,  A50  = 0.01575, 0.25

# ---------------------------------------------------------------- aggregates
epsN_bar = (sA_rice*epsN_rice + sA_veg*epsN_veg
            + sA_fruit*epsN_fruit + sA_other*epsN_other)
ghg_n2o_gm0 = epsN_gm * nu_O * LAbar * (ghg_n2o_syn0 / (epsN_bar * Fbar))

def ch4_route_A(nu, cn=CN_gm):
    return 0.09458 * (nu * Fbar_kgN * cn) / 213.5

ch4_uplift = ch4_route_A(nu_O)

iota_gm     = nu_O * Fbar_kgN * CN_gm / 1000.0
iota_paddy  = iota_gm - resid_loss_paddy
iota_upland = iota_gm - resid_loss_upland
gamma_soc   = A_ha * (44.0/12.0) / 1e4

print("=== 0. parameter block ===")
print(f"  epsN_bar      {epsN_bar:.7f}   (ledger 0.0046035)")
print(f"  ghg_n2o_gm0   {ghg_n2o_gm0:.6f}  (ledger 83.004388)")
print(f"  ch4_uplift    {ch4_uplift:.10f}  (R 0.8673672646)")
print(f"  green-manure C {iota_gm*1000:.1f} kgC/ha"
      f"  iota: gross {iota_gm:.6f} | paddy {iota_paddy:.6f} | upland {iota_upland:.6f}")
print(f"  gamma_soc     {gamma_soc:.6f}   A_ha {A_ha:.0f}")

# ---------------------------------------------------------------- ramp + run
def ramp(t, v30, v50, t0=Y2022, t30=Y2030, t50=Y2050):
    if t <= t0:  return 0.0
    if t <= t30: return v30 * (t - t0) / (t30 - t0)
    if t <= t50: return v30 + (v50 - v30) * (t - t30) / (t50 - t30)
    return v50

def soc_extend(Tend=250, phi=phi_default, iota_p=iota_paddy, iota_u=iota_upland,
               upl=ch4_uplift, kp=k_paddy, ku=k_upland):
    """Faithful transcription of soc_extend() in the R source."""
    sp = su = 0.0
    out = {k: [None]*(Tend+1) for k in
           ("year","dGHG","sink","dN2O","dN2Ogm","dCH4","maff","SOCp","SOCu")}
    for t in range(1, Tend+1):
        out["year"][t] = YEAR0 + t
        if t < 2:
            continue
        pi_ = ramp(t, PI30, PI50) if t <= TERM else PI50
        a   = ramp(t, A30,  A50)  if t <= TERM else A50
        LAo = a * LAbar
        n1 = ghg_n2o_syn0 * (-pi_)
        n2 = ghg_n2o_gm0 * (LAo / LAbar) * phi
        c4 = ghg_ch4_pad0 * (sA_rice * LAo / LAbar) * upl * phi
        npx = (1 - kp) * sp + phi * iota_p * (sA_rice * LAo)
        nux = (1 - ku) * su + phi * iota_u * ((1 - sA_rice) * LAo)
        sink = gamma_soc * ((npx - sp) + (nux - su))
        out["dN2O"][t], out["dN2Ogm"][t], out["dCH4"][t] = n1, n2, c4
        out["sink"][t] = sink
        out["dGHG"][t] = (n1 + n2 + c4) - sink
        out["maff"][t] = -0.93 * (LAo * A_ha) / 1e4
        sp, su = npx, nux
        out["SOCp"][t], out["SOCu"][t] = sp, su
    return out

def cross_up(x, yr, after=2050):
    for i in range(2, len(x)):
        if x[i-1] is not None and x[i] is not None and x[i] > 0 \
           and x[i-1] <= 0 and yr[i] > after:
            return yr[i-1] + (-x[i-1]) / (x[i] - x[i-1])
    return float("nan")

print("\n=== 3./4. headline and crossover ===")
for phi in (1.0, 29/45):
    e = soc_extend(phi=phi)
    cum, ccross = 0.0, None
    for t in range(1, len(e["dGHG"])):
        if e["dGHG"][t] is None: continue
        cum += e["dGHG"][t]
        if ccross is None and cum > 0: ccross = e["year"][t]
    EMperm = (ghg_n2o_syn0*(-PI50) + ghg_n2o_gm0*A50*phi
              + ghg_ch4_pad0*sA_rice*A50*ch4_uplift*phi)
    print(f"  phi {phi:.4f}: dGHG2050 {e['dGHG'][Y2050]:+9.4f}"
          f" | annual cross {cross_up(e['dGHG'], e['year']):.1f}"
          f" | cumulative cross {ccross}")
    print(f"              equilibrium dGHG {EMperm:+.4f}"
          f" ({EMperm/100:+.3f} Mt-CO2eq/yr, PERMANENT)")

e = soc_extend()
i2030 = Y2030
print(f"  2030 checkpoint dGHG {e['dGHG'][i2030]:+.2f}")
print(f"  MAFF convention at 2050: {e['maff'][Y2050]:.2f}"
      f" ({e['maff'][Y2050]/100:.3f} Mt/yr) vs this model {e['dGHG'][Y2050]:.2f}")
print(f"  MAFF convention in 2100 (constant rate): {e['maff'][82]:.2f}")

# ---------------------------------------------------------------- 7.4 / 7.5
print("\n=== 7.4 ch4 break-even (epsN_gm = 0.0031) ===")
def breakeven_ch4(nu, eps=epsN_gm):
    """uplift at which the PERMANENT (equilibrium) balance is zero."""
    gm0 = eps * nu * LAbar * (ghg_n2o_syn0 / (epsN_bar * Fbar))
    return (ghg_n2o_syn0*PI50 - gm0*A50) / (ghg_ch4_pad0*sA_rice*A50)

for nu in (100/Fbar_kgN, nu_O, 159/Fbar_kgN):
    be, rA = breakeven_ch4(nu), ch4_route_A(nu)
    print(f"  nu_O {nu:.4f}: route A {rA:.4f} | break-even {be:.6f} | margin {rA/be:5.2f}x")

print("=== 7.5 (epsN_gm = 0.00195) ===")
for nu in (100/Fbar_kgN, nu_O):
    be, rA = breakeven_ch4(nu, 0.00195), ch4_route_A(nu)
    print(f"  nu_O {nu:.4f}: margin {rA/be:5.2f}x  (break-even {be:.6f})")

print("=== C/N break-even (retires the 'unconditional' claim) ===")
be = breakeven_ch4(nu_O)
cn_be = be * 213.5 / (0.09458 * nu_O * Fbar_kgN)
print(f"  C/N at which route A hits break-even: {cn_be:.2f}"
      "   <- CO2-only figure; see note below")

# ---------------------------------------------------------------- §7 stock/conc
print("\n=== §7 stock -> concentration, RE-COMPUTED (handoff §6.5 last row) ===")
LAo50 = A50 * LAbar
paddy_idx_ha = sA_rice * LAo50
upl_idx_ha   = (1 - sA_rice) * LAo50
soc_p_perha_2050 = e["SOCp"][Y2050] / paddy_idx_ha     # tC per PHYSICAL ha
soc_u_perha_2050 = e["SOCu"][Y2050] / upl_idx_ha
eq_p = phi_default * iota_paddy  / k_paddy
eq_u = phi_default * iota_upland / k_upland

print(f"  paddy  SOC gain 2050 {soc_p_perha_2050:7.3f} tC/ha"
      f" | equilibrium {eq_p:7.3f} tC/ha  ({soc_p_perha_2050/eq_p*100:.1f}% of eq.)")
print(f"  upland SOC gain 2050 {soc_u_perha_2050:7.3f} tC/ha"
      f" | equilibrium {eq_u:7.3f} tC/ha  ({soc_u_perha_2050/eq_u*100:.1f}% of eq.)")

# bulk densities: MAFF 2007 Shiryo-2 soil-type values used in handoff §6.1
bd = {"Gray Lowland 0.474": 1.03, "Gley 0.404": 0.96, "Wet Andosol 0.122": 0.79}
bd_w = 0.474*1.03 + 0.404*0.96 + 0.122*0.79
print(f"  area-weighted bulk density {bd_w:.5f} t/m3")

def conc(dSOC_t_ha, depth_m, bulk):
    """tC/ha over a layer -> g C / kg soil."""
    return dSOC_t_ha / (depth_m * 1e4 * bulk) * 1000.0

print("\n  -- OLD statement (retired): depth 10-20 cm x bulk 0.8-1.2 --")
old = [conc(soc_p_perha_2050, d, b) for d in (0.10, 0.20) for b in (0.8, 1.2)]
print(f"     range {min(old):.2f} - {max(old):.2f} g/kg   width {max(old)-min(old):.2f}")

print("\n  -- NEW: depth FIXED at 0-30 cm (Ma et al. 2023 Methods); "
      "bulk density is the only free assumption --")
new30 = [conc(soc_p_perha_2050, 0.30, b) for b in (0.79, 1.03)]
c30w  = conc(soc_p_perha_2050, 0.30, bd_w)
print(f"     range {min(new30):.2f} - {max(new30):.2f} g/kg   width {max(new30)-min(new30):.2f}"
      f"   (area-weighted point value {c30w:.2f})")

gap_clim = 36.0 - 25.09
gap_pool_lo, gap_pool_hi = 31.2 - 25.09, 32.4 - 25.09
print(f"\n     signal to beat: climate-consistent SOC yield gap {gap_clim:.2f} g/kg"
      f"  (pooled {gap_pool_lo:.2f}-{gap_pool_hi:.2f})")
print(f"     assumption width / signal:  OLD {(max(old)-min(old))/gap_clim:.2f}x"
      f"  ->  NEW {(max(new30)-min(new30))/gap_clim:.3f}x")
print(f"     model 2050 signal closes {c30w/gap_clim*100:.1f}% of the gap"
      f"  ({min(new30)/gap_clim*100:.1f}-{max(new30)/gap_clim*100:.1f}%)")

print("\n  -- RESIDUAL depth mismatch (must stay disclosed) --")
print("     k_paddy / k_upland come from PLOUGH-LAYER equilibrium pairs")
print("     (Shirato & Yokozawa 2005: 10-18 cm; Shirato et al. 2004: 15-17.5 cm),")
print("     so the reservoir may describe ~0.15 m, not 0.30 m:")
plough = [conc(soc_p_perha_2050, 0.15, b) for b in (0.79, 1.03)]
print(f"     if the gain sits in 0-15 cm only: {min(plough):.2f} - {max(plough):.2f} g/kg"
      f"   -> {min(plough)/gap_clim*100:.0f}-{max(plough)/gap_clim*100:.0f}% of the gap")
print("     REPORT BOTH.  The depth of the reservoir is the remaining open")
print("     assumption; the bulk density no longer is.")

eq_c30 = conc(eq_p, 0.30, bd_w)
print(f"\n  -- equilibrium (not 2050): {eq_c30:.2f} g/kg over 0-30 cm,"
      f" i.e. {eq_c30/gap_clim*100:.0f}% of the gap --")
print("     Even at the reservoir's own equilibrium the Japanese paddy does not")
print("     reach Ma's climate-consistent optimum, so h_rice <= 1.05 is not")
print("     undercut by the conversion's own carbon gain.")
