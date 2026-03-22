/*===========================================================================
  03_gdp_neutrality_tests.do

  Green Finance Allocation in Bangladesh — Empirical Analysis (2020–2023)
  MSc Economics Dissertation, University of Glasgow, Adam Smith Business School
  Supervisor: Dr. Foivos Savva
  Author:     Faiza Farah

  PURPOSE:
  Two-way fixed effects model testing whether green finance allocation
  scales with sectoral GDP share. Pre-specified Wald tests:
    (1) GDP-neutrality:      H0: β = 0
    (2) GDP-proportionality: H0: β = 1
  Wild cluster bootstrap p-values as small-sample robustness check.
  SAR summary table by sector.

  Confirmed results from dissertation:
    Two-way FE: β(ln_gdpshare_pct) = -0.667***, SE = 0.072
    Neutrality test:      F(1) = 85.43,  p = 0.0002491
    Proportionality test: F(1) = 533.89, p = 2.82e-06

  INPUT:  data/panel_analysis.dta
  OUTPUT: output/GDP_neutrality_tests.txt
          output/SAR_sector_mean.csv
===========================================================================*/

clear all
set more off
capture log close
log using "logs/03_gdp_neutrality_tests.log", replace text

use "data/panel_analysis.dta", clear

xtset sector_id year

/*---------------------------------------------------------------------------
  MACRO-ALIGNMENT MODEL:

  ln(green_finance_s,t) = α + β·ln(gdp_share_pct_s,t) + μ_s + τ_t + ε_s,t

    μ_s = sector fixed effects (absorb time-invariant heterogeneity)
    τ_t = year fixed effects   (absorb common annual shocks)
    β   = elasticity of green finance w.r.t. GDP share (sector-invariant)

  Standard errors clustered by sector (Cameron & Miller, 2015)
---------------------------------------------------------------------------*/

*-----------------------------------------------------------------------
* 1. Two-way FE regression
*-----------------------------------------------------------------------
xtreg ln_greenfinance ln_gdpshare_pct i.year, fe vce(cluster sector_id)
estimates store twfe_gdp

display _newline "=== TWO-WAY FE RESULTS ==="
estimates table twfe_gdp, b(%8.3f) se(%8.3f) stats(N)

capture which outreg2
if _rc == 0 {
    outreg2 using "output/GDP_neutrality_tests.txt", replace ///
        title("Two-Way FE: GDP Share and Green Finance Allocation") ///
        ctitle("ln(Green Finance)") ///
        addnote("Sector and year fixed effects included." ///
                "Standard errors clustered by sector." ///
                "* p<0.10 ** p<0.05 *** p<0.01")
}

*-----------------------------------------------------------------------
* 2. Pre-specified Wald tests
*-----------------------------------------------------------------------

* Test 1 — GDP-neutrality: H0: β = 0
test ln_gdpshare_pct = 0
display _newline "=== GDP-NEUTRALITY TEST (H0: β = 0) ==="
display "F(" r(df) ", " r(df_r) ") = " %8.5f r(F)
display "p-value             = " %10.7f r(p)
display "Expected (confirmed): F = 85.43, p = 0.0002491"
display "Result: REJECT H0 — GDP share has explanatory power"
scalar f_neutral = r(F)
scalar p_neutral = r(p)

* Test 2 — GDP-proportionality: H0: β = 1
test ln_gdpshare_pct = 1
display _newline "=== GDP-PROPORTIONALITY TEST (H0: β = 1) ==="
display "F(" r(df) ", " r(df_r) ") = " %8.5f r(F)
display "p-value             = " %12.2e r(p)
display "Expected (confirmed): F = 533.89, p = 2.82e-06"
display "Result: REJECT H0 — allocation not proportional to GDP weight"
scalar f_prop = r(F)
scalar p_prop = r(p)

*-----------------------------------------------------------------------
* 3. Wild cluster bootstrap — small-sample robustness
*    Addresses finite-sample concerns with only 6 cluster units
*    Requires: ssc install boottest
*-----------------------------------------------------------------------
capture which boottest
if _rc == 0 {
    display _newline "=== WILD CLUSTER BOOTSTRAP ==="
    boottest ln_gdpshare_pct, boottype(wild) cluster(sector_id) ///
        reps(999) seed(20230101)
    display "Wild bootstrap p-value (H0: β = 0): " r(p)

    boottest (ln_gdpshare_pct = 1), boottype(wild) cluster(sector_id) ///
        reps(999) seed(20230101)
    display "Wild bootstrap p-value (H0: β = 1): " r(p)
}
else {
    display _newline "NOTE: Install boottest for wild cluster bootstrap:"
    display "  ssc install boottest"
}

*-----------------------------------------------------------------------
* 4. Practical equivalence check
*    90% CI vs equivalence band |β| ≤ 0.20 (Schuirmann, 1987)
*-----------------------------------------------------------------------
quietly xtreg ln_greenfinance ln_gdpshare_pct i.year, fe vce(cluster sector_id)
scalar b_est  = _b[ln_gdpshare_pct]
scalar se_est = _se[ln_gdpshare_pct]
scalar ci_lo  = b_est - invttail(e(df_r), 0.05) * se_est
scalar ci_hi  = b_est + invttail(e(df_r), 0.05) * se_est

display _newline "=== PRACTICAL EQUIVALENCE CHECK (|β| ≤ 0.20) ==="
display "β = " %6.3f b_est
display "90% CI: [" %6.3f ci_lo ", " %6.3f ci_hi "]"
display cond(ci_lo > -0.20 & ci_hi < 0.20, ///
    "Within equivalence band — practically neutral", ///
    "Outside equivalence band — not practically neutral")

*-----------------------------------------------------------------------
* 5. SAR summary by sector
*-----------------------------------------------------------------------
display _newline "=== SECTOR ALIGNMENT RATIOS ==="

bysort sector_id: egen SAR_mean   = mean(SAR)
bysort sector_id: egen SAR_sd     = sd(SAR)
bysort sector_id: gen  SAR_n      = _N
gen SAR_se      = SAR_sd   / sqrt(SAR_n)
gen SAR_ci95_lo = SAR_mean - 1.96 * SAR_se
gen SAR_ci95_hi = SAR_mean + 1.96 * SAR_se

preserve
    bysort sector_id: keep if _n == 1
    sort SAR_mean
    list sector SAR_mean SAR_ci95_lo SAR_ci95_hi, clean noobs sep(0)
    export delimited sector SAR_mean SAR_ci95_lo SAR_ci95_hi ///
        using "output/SAR_sector_mean.csv", replace
    display "Saved: output/SAR_sector_mean.csv"
restore

log close
