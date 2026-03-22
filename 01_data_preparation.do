/*===========================================================================
  01_data_preparation.do

  Green Finance Allocation in Bangladesh — Empirical Analysis (2020–2023)
  MSc Economics Dissertation, University of Glasgow, Adam Smith Business School
  Supervisor: Dr. Foivos Savva
  Author:     Faiza Farah

  PURPOSE:
  Loads the analysis-ready panel dataset, constructs the GDP share
  proportion variable for neutrality tests, constructs the Sector
  Alignment Ratio (SAR), and produces summary statistics.

  NOTE: Log-transformed variables are already present in the dataset:
    ln_greenfinance   = ln(green_finance)
    log_ghg_emissions = ln(ghg_share)         [ghg_share in MtCO2e]
    log_gdp_contrib   = ln(gdp_share)         [gdp_share in million BDT]
    log_credit_share  = ln(credit_share)
    ln_projects       = ln(estimated_projects)

  INPUT:  data/panel_dataset_2020_2023_ready.dta
  OUTPUT: data/panel_analysis.dta
===========================================================================*/

clear all
set more off
capture log close
log using "logs/01_data_preparation.log", replace text

*-----------------------------------------------------------------------
* 0. Set working directory — update to your local path
*-----------------------------------------------------------------------
* cd "YOUR/PATH/HERE"

*-----------------------------------------------------------------------
* 1. Load dataset
*-----------------------------------------------------------------------
use "data/panel_dataset_2020_2023_ready.dta", clear

/*
  Panel structure confirmed from data:
    Units  : 6 sectors — Agriculture, Construction, Energy,
                          Industry, Services, Waste Management
    Time   : 2020–2023 (4 years)
    N      : 23 obs (Construction 2020 excluded — missing source data)

  Variables:
    green_finance      Disbursement (million BDT, current prices)
    ghg_share          Sectoral GHG emissions (MtCO2e)
    gdp_share          Sectoral GDP contribution (million BDT)
    credit_share       Sector share of total bank credit (%)
    priority_dummy     1 = BB SFP 2020 priority sector
    estimated_projects Number of approved green finance projects
    sector_id          Numeric sector code (1=Agriculture ... 6=Waste Management)
*/

*-----------------------------------------------------------------------
* 2. Declare panel
*-----------------------------------------------------------------------
xtset sector_id year
xtdescribe

*-----------------------------------------------------------------------
* 3. GDP share proportion — for neutrality tests
*    Computed as sector GDP / total GDP across all sectors in that year
*-----------------------------------------------------------------------
bysort year: egen gdp_total_yr = total(gdp_share)
gen gdp_share_pct = gdp_share / gdp_total_yr
label variable gdp_share_pct "Sector proportion of total GDP in year t"

gen ln_gdpshare_pct = ln(gdp_share_pct)
label variable ln_gdpshare_pct "Log of sectoral GDP share proportion"

*-----------------------------------------------------------------------
* 4. GHG share proportion — for emissions alignment figures
*-----------------------------------------------------------------------
bysort year: eigen ghg_total_yr = total(ghg_share)
gen ghg_share_pct = (ghg_share / ghg_total_yr) * 100
label variable ghg_share_pct "Sector share of total GHG emissions (%)"

*-----------------------------------------------------------------------
* 5. Sector Alignment Ratio (SAR)
*    SAR_s,t = ln(GF_share_s,t) - ln(GDP_share_s,t)
*    SAR > 0 : over-allocation relative to GDP weight
*    SAR < 0 : under-allocation relative to GDP weight
*    Following compositional data approach (Aitchison, 1982)
*-----------------------------------------------------------------------
bysort year: eigen gf_total_yr = total(green_finance)
gen gf_share_pct = green_finance / gf_total_yr
label variable gf_share_pct "Sector proportion of total green finance in year t"

gen ln_gfshare   = ln(gf_share_pct)
gen SAR = ln_gfshare - ln_gdpshare_pct
label variable SAR "Sector Alignment Ratio: ln(GF share) - ln(GDP share)"

*-----------------------------------------------------------------------
* 6. Summary statistics
*-----------------------------------------------------------------------
display _newline "=== SUMMARY STATISTICS ==="
summarize ln_greenfinance log_ghg_emissions log_gdp_contrib ///
          log_credit_share priority_dummy ln_projects SAR, detail

display _newline "=== PANEL BALANCE ==="
tabulate sector year, missing

*-----------------------------------------------------------------------
* 7. Save analysis dataset
*-----------------------------------------------------------------------
drop gdp_total_yr gf_total_yr ln_gfshare

save "data/panel_analysis.dta", replace
display _newline "Saved: data/panel_analysis.dta"

log close
