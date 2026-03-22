# Green Finance Allocation in Bangladesh — Empirical Analysis (2020–2023)

**MSc Economics Dissertation**
University of Glasgow, Adam Smith Business School
Supervisor: Dr. Foivos Savva
Author: Faiza Farah

---

## Research Question

To what extent is green finance in Bangladesh strategically aligned with sectoral greenhouse gas (GHG) emissions and economic contribution (GDP share) between 2020 and 2023?

---

## Summary of Findings

Green finance allocation in Bangladesh is driven almost entirely by project pipeline readiness (β = 1.066, p < 0.01). Sectoral GHG emissions, GDP contribution, credit share, and policy priority status exert no statistically significant influence on allocation. GDP-neutrality and proportionality tests both reject the null hypotheses, and Sector Alignment Ratios (SAR) confirm consistent under-allocation across all sectors relative to their economic weight. The findings suggest Bangladesh's green finance system rewards administrative compliance rather than environmental urgency.

---

## Repository Structure

```
green-finance-bangladesh/
├── README.md
├── code/
│   ├── 01_data_preparation.do      — Variable construction, log transforms, SAR
│   ├── 02_main_regression.do       — Pooled OLS, diagnostics, avplot
│   ├── 03_gdp_neutrality_tests.do  — Two-way FE, Wald tests, wild bootstrap
│   └── 04_figures.do               — All dissertation figures
├── data/
│   ├── panel_dataset_2020_2023.dta         — Raw panel dataset
│   ├── panel_dataset_2020_2023_ready.dta   — Analysis-ready dataset
│   └── panel_dataset_2020_2023_old334_ready.dta — Earlier version (archived)
└── output/
    ├── Figure_SAR_mean_CI.png
    ├── GDP_neutrality_tests.xlsx
    ├── SAR_sector_mean_appendix.xlsx
    └── FE2W_regression.txt
```

---

## Data Sources

| Variable | Source |
|----------|--------|
| Green finance disbursement | Bangladesh Bank Sustainable Finance Reports (2020–2023); IDCOL Annual Reports |
| Sectoral GHG emissions | Climate Watch; Bangladesh national MRV reports |
| Sectoral GDP contribution | Bangladesh Bureau of Statistics (BBS) |
| Credit share | Bangladesh Bank monetary data |
| Project pipeline (n_projects) | Bangladesh Bank Sustainable Finance Reports; IDCOL datasets |
| Priority sector designation | Bangladesh Bank Sustainable Finance Policy (2020) |

---

## Methods

**Panel structure:** 6 sectors × 4 years (2020–2023), N = 23 (one sector-year excluded due to missing data)

**Main estimator:** Pooled OLS with HC3 heteroskedasticity-robust standard errors (Stata 18, scripted .do-files)

**Log-log specification:** All continuous variables log-transformed for elasticity interpretation and skewness correction

**Rejected specifications:** Fixed Effects (degree-of-freedom loss, instability at N=23); FGLS (overfitting, outlier sensitivity); SUR (no multi-equation structure)

**Macro-alignment tests:** Two-way fixed effects with sector-clustered standard errors and wild cluster bootstrap inference (Cameron, Gelbach & Miller, 2008; Roodman et al., 2019)

**Pre-specified Wald tests:**
- GDP-neutrality: H₀: β = 0 → F(1) = 85.43, p = 0.0002 (rejected)
- GDP-proportionality: H₀: β = 1 → F(1) = 533.89, p = 2.82e-06 (rejected)

**SAR diagnostic:** Sector Alignment Ratio = ln(GF share) − ln(GDP share), following compositional data methods (Aitchison, 1982)

**Qualitative strand:** 6 key informant interviews (KIIs) with senior officials at Bangladesh Bank, IDCOL, Ministry of Agriculture, a commercial bank, an international development agency, and a national NGO; thematic analysis in NVivo 14 (Braun & Clarke, 2006)

---

## Software

- **Stata 18** — all quantitative analysis (`.do-files` fully scripted for replication)
- **Python** — data cleaning and merging of electricity generation and transport emissions datasets from Bangladesh national MRV sources
- **NVivo 14** — qualitative thematic analysis

---

## How to Replicate

1. Open Stata and set the working directory to this repository root
2. Run scripts in order:
   ```stata
   do code/01_data_preparation.do
   do code/02_main_regression.do
   do code/03_gdp_neutrality_tests.do
   do code/04_figures.do
   ```
3. All outputs will be saved to the `output/` folder

**Required Stata packages:**
```stata
ssc install outreg2
ssc install boottest   // for wild cluster bootstrap in 03_gdp_neutrality_tests.do
```

---

## Ethics

Ethical approval for the qualitative component was granted by the University of Glasgow College of Social Sciences Research Ethics Committee. All participant data has been anonymised. Raw interview transcripts are not included in this repository.

---

## Citation

Farah, F. (2025). *Is Green Finance Allocation in Bangladesh Aligned with Sectoral Emissions and Economic Contribution? An Empirical Analysis (2020–2023)*. MSc Economics Dissertation, University of Glasgow, Adam Smith Business School.
