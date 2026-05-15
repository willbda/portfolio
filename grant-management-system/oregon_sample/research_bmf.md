# IRS BMF Research — Oregon (eo_or.csv)

_Written by Claude Code on 2026-04-23._

Source: `https://www.irs.gov/pub/irs-soi/eo_or.csv` (4.4 MB, 26,793 rows).

## Columns (all 28 expected columns present)

`EIN, NAME, ICO, STREET, CITY, STATE, ZIP, GROUP, SUBSECTION, AFFILIATION, CLASSIFICATION, RULING, DEDUCTIBILITY, FOUNDATION, ACTIVITY, ORGANIZATION, STATUS, TAX_PERIOD, ASSET_CD, INCOME_CD, FILING_REQ_CD, PF_FILING_REQ_CD, ACCT_PD, ASSET_AMT, INCOME_AMT, REVENUE_AMT, NTEE_CD, SORT_NAME`

Load-bearing: `SUBSECTION` (03 = 501(c)(3)), `FOUNDATION` (02–04 = private foundation; 09–18 = non-PF public charity), `NTEE_CD` (activity taxonomy), `STATUS` (1 = active).

## Counts

| Filter | Rows |
|---|---|
| Total | 26,793 |
| SUBSECTION = 03 | 22,166 |
| NTEE A* | 2,140 |
| NTEE N* | 2,016 |
| A* + 501(c)(3) | 2,109 |
| N* + 501(c)(3) | 1,720 |
| Private foundations (FOUND 02/03/04, any NTEE) | 1,146 |
| NTEE T20/T21/T22/T30 grantmakers | 596 |

`FOUNDATION` distribution within A/N (4,156 rows): 00=325, 03=18, 04=103, 09–14=21, **15=1,597, 16=2,072**, 17=15, 21–23=5. ~88% public-charity 15/16; ~3% private foundations.

## Samples (NAME | CITY | NTEE | SUB | F | REV)

**A\***: Montavilla Jazz Festival | Portland | A60 | 03 | 16 | 279,212 · NW Tibetan Cultural Assoc | Portland | A230 | 03 | 16 | 427,007 · School of Making Thinking | Portland | A25 | 03 | 15 | 55,026 · Accordion Club of Roseburg | Roseburg | A6C | 03 | 16 | 0 · Applegate Pioneer Museum | Veneta | A50 | 03 | 16 | 0 · Bialystock & Bloom | Portland | A65 | 03 | 16 | 0 · Silton Foundation | Gresham | A62 | 03 | 15 | 0 · Lightworker NP Productions | Eugene | A68 | 03 | 15 | 0 · Arts and Culture Project | Eugene | A25 | 03 | 15 | 0 · Summer Shred PDX | Portland | A20 | 03 | 16 | —.

**N\***: Cooper Spur Race Team | Hood River | N68 | 03 | 16 | 365,116 · Winterhawks Am. Hockey | Portland | N68 | 03 | 15 | 187,448 · Bustin Barriers | Portland | N62 | 03 | 15 | 140,653 · Lower Columbia Legion Baseball | Clatskanie | N63 | 03 | 16 | 0 · Silverton Youth Softball | Silverton | N63 | 03 | 16 | — · Brownsville Athletics | Brownsville | N60 | 03 | 16 | — · Rip City Paddlers | Portland | N99 | 03 | 16 | 0 · West Linn HS Snowboard | West Linn | N68 | 03 | 16 | — · Classic Rides Car Club | Portland | N50 | 07 | 00 | 0 · Klamath Basin Snowdrifters | Klamath Falls | N50 | 07 | 00 | 0.

## Recommendation — grantees vs. funders

Build **grantees** from `SUBSECTION=03 AND NTEE_CD LIKE 'A%' OR 'N%' AND FOUNDATION IN (09..18)` (~3,800 arts/rec public charities — the realistic applicant pool). Build **funders** as the union of (a) `FOUNDATION IN (02,03,04)` statewide (1,146 private foundations, the 990-PF universe) and (b) `NTEE_CD LIKE 'T2%' OR 'T30%'` (596 grantmaking public charities/community foundations). Do **not** restrict funders to A/N — most OR foundations give cross-category; mission-based targeting belongs in a downstream `funder_focus_areas` table fed from 990-PF Schedule I. Keep a `role` enum (`grantee`/`funder`/`both`) since some A/N orgs are themselves private foundations (e.g. Mt Hood Ski Racing League, N68/F04 — a true hybrid).
