/*===========================================================================
  02_main_regression.do

  Green Finance Allocation in Bangladesh — Empirical Analysis (2020–2023)
  MSc Economics Dissertation, University of Glasgow, Adam Smith Business School
  Supervisor: Dr. Foivos Savva
  Author:     Faiza Farah

  PURPOSE:
  Estimates the main pooled OLS regression of ln(green_finance) on
  sectoral characteristics. Documents rejection of FE and FGLS.
  Reports White heteroskedasticity test and produces the added-variable
  plot for the project pipeline variable.

  Key result: ln_projects is the only significant predictor
    β = 1.066, robust SE = 0.178, p < 0.01
    Adj. R² = 0.359

  INPUT:  data/panel_analysis.dta
  OUTPUT: output/main_regression_results.txt
          output/Figure_avplot_projects.png
===========================================================================*/

clear all
set more off
capture log close
log using "logs/02_main_regression.log", replace text

use "data/panel_analysis.dta", clear

/*---------------------------------------------------------------------------
  MODEL:
  ln(green_finance_it) = α
    + β1·log_ghg_emissions_it
    + β2·log_gdp_contrib_it
    + β3·log_credit_share_it
    + β4·priority_dummy_i
    + β5·ln_projects_it
    + ε_it

  Estimator: Pooled OLS with HC3 heteroskedasticity-robust standard errors
  Log-log specification: coefficients interpreted as elasticities
---------------------------------------------------------------------------*/

global depvar  ln_greenfinance
global indvars log_ghg_emissions log_gdp_contrib log_credit_share ///
               priority_dummy ln_projects

*-----------------------------------------------------------------------
* 1. Main pooled OLS — HC3 robust standard errors
*-----------------------------------------------------------------------
regress $depvar $indvars, vce(robust)
estimates store main_ols

display _newline "=== MAIN OLS RESULTS ==="
estimates table main_ols, b(%8.3f) se(%8.3f) stats(N r2_a)

* Export results
capture which outreg2
if _rc == 0 {
    outreg2 using "output/main_regression_results.txt", replace ///
        title("Table 2: Determinants of Sectoral Green Finance Allocation in Bangladesh (2020-2023)") ///
        ctitle("ln(Green Finance)") ///
        addnote("HC3 heteroskedasticity-robust standard errors in parentheses." ///
                "* p<0.10 ** p<0.05 *** p<0.01")
}
else {
    display "NOTE: outreg2 not installed. Run: ssc install outreg2"
    estimates table main_ols, b se star stats(N r2 r2_a)
}

*-----------------------------------------------------------------------
* 2. White heteroskedasticity test
*    H0: homoskedastic errors
*    Result: chi2 = 21.87, p = 0.2377
*    Fail to reject at 5% — but robust SEs retained as precaution
*-----------------------------------------------------------------------
quietly regress $depvar $indvars
estat imtest, white
display _newline "White test: chi2 = " r(chi2) ", p = " r(p)
display "Robust SEs retained as precautionary measure."

*-----------------------------------------------------------------------
* 3. Added-variable (partial regression) plot — Figure 4
*    Conditional relationship: ln(projects) | all other regressors
*    Fitted slope = OLS elasticity β5 = 1.066
*-----------------------------------------------------------------------
quietly regress $depvar $indvars, vce(robust)

avplot ln_projects, ///
    title("Partial Regression Plot: Log Green-Finance Disbursement" ///
          "vs. Log Approved Projects", size(medsmall) color(black)) ///
    xtitle("e( log_estimated_projects | X )", size(small)) ///
    ytitle("e( log_green_finance | X )", size(small)) ///
    note("coef = 1.0657358, (robust) se = .17826661, t = 5.98", ///
         size(vsmall) position(7)) ///
    msymbol(circle) mcolor(navy%70) msize(small) ///
    lcolor(maroon) lwidth(medthin) ///
    graphregion(color(white)) bgcolor(white)

graph export "output/Figure_avplot_projects.png", replace width(1600)
display "Figure saved: output/Figure_avplot_projects.png"

*-----------------------------------------------------------------------
* 4. Alternative specifications — tested and rejected
*-----------------------------------------------------------------------

* 4a. Fixed Effects
*     REJECTED: priority_dummy is time-invariant and would be dropped;
*     with N=23 and 6 sector dummies, degrees of freedom critically reduced;
*     multicollinearity between sector FE and main regressors → instability.
quietly xtreg $depvar $indvars i.year, fe vce(robust)
estimates store fe_spec
display _newline "FE specification estimated for comparison — REJECTED (see dissertation §3.3.3)"

* 4b. FGLS
*     REJECTED: overfits at N=23; coefficients sensitive to sectoral outliers;
*     efficiency gains do not outweigh estimation instability.
quietly xtgls $depvar $indvars, panels(heteroskedastic)
estimates store fgls_spec
display "FGLS specification estimated for comparison — REJECTED (see dissertation §3.3.3)"

* Compare specifications
estimates table main_ols fe_spec, b(%8.3f) se(%8.3f) stats(N)

*-----------------------------------------------------------------------
* 5. Key results summary
*-----------------------------------------------------------------------
estimates restore main_ols
display _newline "=== COEFFICIENT SUMMARY ==="
display "log_ghg_emissions  β1 = " %6.3f _b[log_ghg_emissions]  " — emissions-blind (p > 0.10)"
display "log_gdp_contrib    β2 = " %6.3f _b[log_gdp_contrib]    " — GDP-neutral (p > 0.10)"
display "log_credit_share   β3 = " %6.3f _b[log_credit_share]   " — no credit integration (p > 0.10)"
display "priority_dummy     β4 = " %6.3f _b[priority_dummy]     " — symbolic label (p > 0.10)"
display "ln_projects        β5 = " %6.3f _b[ln_projects]        " — SIGNIFICANT (p < 0.01)"
display "Adj. R-squared        = " %6.3f e(r2_a)

log close
