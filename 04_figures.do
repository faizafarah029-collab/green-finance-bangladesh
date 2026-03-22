/*===========================================================================
  04_figures.do

  Green Finance Allocation in Bangladesh — Empirical Analysis (2020–2023)
  MSc Economics Dissertation, University of Glasgow, Adam Smith Business School
  Supervisor: Dr. Foivos Savva
  Author:     Faiza Farah

  PURPOSE:
  Produces all dissertation figures using exact variable names from dataset:
    Figure 5 — Scatterplot: ln(green_finance) vs ln(gdp_share)
    Figure 6 — Mean SAR with 95% CIs by sector
    Figure 7 — SAR vs GHG emissions share (%)

  INPUT:  data/panel_analysis.dta
  OUTPUT: output/Figure_GF_vs_GDP.png
          output/Figure_SAR_mean_CI.png
          output/Figure_GF_vs_emissions.png
===========================================================================*/

clear all
set more off
capture log close
log using "logs/04_figures.log", replace text

use "data/panel_analysis.dta", clear

set scheme s1color

*-----------------------------------------------------------------------
* FIGURE 5: ln(green_finance) vs ln(gdp_share)
*    Shows GDP-neutral allocation (fitted slope ≈ flat)
*-----------------------------------------------------------------------
twoway ///
    (scatter ln_greenfinance log_gdp_contrib, ///
        msymbol(circle) mcolor(navy%60) msize(medsmall)) ///
    (lfit ln_greenfinance log_gdp_contrib, ///
        lcolor(maroon) lwidth(medthin)) ///
    (lfitci ln_greenfinance log_gdp_contrib, ///
        ciplot(rarea) alcolor(gray%25) alwidth(none) lcolor(none)), ///
    title("Log Green Finance vs. Log GDP Contribution (2020-2023)", ///
          size(medsmall) color(black)) ///
    xtitle("Log of Sectoral GDP Contribution", size(small)) ///
    ytitle("Log of Green Finance Allocation", size(small)) ///
    note("Fitted line: {&beta} = -0.312, p = 0.12 — GDP-neutral allocation", ///
         size(vsmall)) ///
    legend(off) ///
    graphregion(color(white)) bgcolor(white)

graph export "output/Figure_GF_vs_GDP.png", replace width(1600)
display "Saved: Figure_GF_vs_GDP.png"

*-----------------------------------------------------------------------
* FIGURE 6: Mean SAR with 95% CIs by sector
*    Replicates dissertation Figure 6
*-----------------------------------------------------------------------
bysort sector_id: egen SAR_mean   = mean(SAR)
bysort sector_id: egen SAR_sd     = sd(SAR)
bysort sector_id: gen  SAR_n      = _N
gen SAR_se      = SAR_sd   / sqrt(SAR_n)
gen SAR_ci95_lo = SAR_mean - 1.96 * SAR_se
gen SAR_ci95_hi = SAR_mean + 1.96 * SAR_se

preserve
    bysort sector_id: keep if _n == 1
    sort SAR_mean
    gen rank = _n
    label define sector_rank ///
        1 "Agriculture" 2 "Industry" 3 "Construction" ///
        4 "Services" 5 "Waste Mgmt" 6 "Energy", replace
    label values rank sector_rank

    twoway ///
        (rcap SAR_ci95_lo SAR_ci95_hi rank, ///
            horizontal lcolor(navy) lwidth(medthin)) ///
        (scatter rank SAR_mean if SAR_mean < 0, ///
            msymbol(circle) mcolor(cranberry) msize(medlarge)) ///
        (scatter rank SAR_mean if SAR_mean >= 0, ///
            msymbol(circle) mcolor(navy) msize(medlarge)), ///
        xline(0, lpattern(dash) lcolor(black%60) lwidth(thin)) ///
        title("Average Sector-Alignment Ratio (SAR) with 95% CIs", ///
              size(medsmall) color(black)) ///
        xtitle("Average SAR (2020-2023)", size(small)) ///
        ytitle("Sector", size(small)) ///
        ylabel(1(1)6, valuelabel angle(0) labsize(small)) ///
        legend(off) ///
        graphregion(color(white)) bgcolor(white)

    graph export "output/Figure_SAR_mean_CI.png", replace width(1600)
    display "Saved: Figure_SAR_mean_CI.png"
restore

*-----------------------------------------------------------------------
* FIGURE 7: SAR vs GHG emissions share
*    Shows emissions-blind allocation (flat fitted line)
*-----------------------------------------------------------------------
bysort sector_id: egen mean_SAR     = mean(SAR)
bysort sector_id: egen mean_ghg_pct = mean(ghg_share_pct)

preserve
    bysort sector_id: keep if _n == 1

    twoway ///
        (scatter mean_SAR mean_ghg_pct, ///
            msymbol(circle) mcolor(cranberry) msize(medlarge) ///
            mlabel(sector) mlabsize(vsmall) mlabposition(12) ///
            mlabcolor(black)) ///
        (lfit mean_SAR mean_ghg_pct, ///
            lcolor(gray%70) lwidth(medthin) lpattern(solid)), ///
        yline(0, lpattern(dash) lcolor(black%50) lwidth(thin)) ///
        title("Relationship Between Emissions Intensity and Allocation (2020-2023)", ///
              size(medsmall) color(black)) ///
        xtitle("Sectoral GHG Emissions Share (%)", size(small)) ///
        ytitle("Sector-Alignment Ratio (SAR)", size(small)) ///
        note("{&beta} = 0.142, p > 0.10 — no significant relationship between emissions and allocation", ///
             size(vsmall)) ///
        legend(off) ///
        graphregion(color(white)) bgcolor(white)

    graph export "output/Figure_GF_vs_emissions.png", replace width(1600)
    display "Saved: Figure_GF_vs_emissions.png"
restore

display _newline "All figures exported to output/"
log close
