# IRS 990 Index Research — Oregon Sample

*Written by Claude Code on 2026-04-23.*

## 1. Index availability

All four URLs return HTTP 200.

| Year | Size | Last-Modified |
|------|------|---------------|
| 2023 | 77.5 MB | 2025-03-06 |
| 2024 | 91.1 MB | 2025-03-06 |
| 2025 | 93.1 MB | 2026-01-21 |
| 2026 | 12.1 MB | 2026-04-15 (partial) |

## 2. Schema deviation

Actual columns: `RETURN_ID, FILING_TYPE, EIN, TAX_PERIOD, SUB_DATE, TAXPAYER_NAME, RETURN_TYPE, DLN, OBJECT_ID, XML_BATCH_ID`.

- **2023 index has no `XML_BATCH_ID` column** (9 cols). Stage 3 will need a fallback (IRS publishes separate batch-listing files).
- 2024/2025/2026 include `XML_BATCH_ID`.
- Workflow doc omits `FILING_TYPE`, `SUB_DATE`, `TAXPAYER_NAME`, `DLN` — all present.

## 3. TAX_PERIOD distribution

| Idx | Rows | Min | Max | Top 5 (YYYYMM:count) |
|-----|------|-----|-----|----------------------|
| 2023 | 705K | 202002 | 202312 | 202212:432K, 202206:81K, 202306:52K, 202209:27K, 202112:24K |
| 2024 | 729K | 201912 | 202411 | 202312:444K, 202306:82K, 202406:54K, 202309:27K, 202212:21K |
| 2025 | 749K | 202112 | 202512 | 202412:466K, 202406:83K, 202506:58K, 202409:27K, 202312:25K |
| 2026 | 99K | 202212 | 202609 | 202512:40K, 202506:22K, 202509:10K, 202412:6K, 202508:4K |

A calendar TY is "fully filed" once the *next* year's index shows it as the dominant bucket. TY2023 → saturated by 2024 index. TY2024 → saturated by 2025 index. TY2025 → still ramping (40K so far in 2026).

## 4. Collins Foundation (Oregon)

**EIN 930347943 does NOT appear in any index.** The Oregon Collins Foundation uses **EIN `742254030`** (name+990PF match). FYE August.

| Idx | TAX_PERIOD | RETURN_TYPE | OBJECT_ID | XML_BATCH_ID |
|-----|-----------|-------------|-----------|--------------|
| 2023 | 202208 | 990PF | 202340139349100614 | (col absent) |
| 2023 | 202308 | 990PF | 202323549349100802 | (col absent) |
| 2025 | 202408 | 990PF | 202520159349100472 | 2025_TEOS_XML_01A |
| 2025 | 202508 | 990PF | 202543579349100019 | 2025_TEOS_XML_12A |

Not in 2024 or 2026 indices. TY2023 (FYE 202308) filing sat in 2023 index; TY2024 (FYE 202408) appeared in 2025 index batch 01A (submitted Jan 2025).

## 5. Selective extract verified

`curl | bsdtar -xf - <filename>` streams from a 103.7 MB batch zip (`2025_TEOS_XML_01A.zip`) and extracts only `202520159349100472_public.xml` without persisting the zip.

- XML size: 100,231 bytes
- Parse: OK, root `{http://www.irs.gov/efile}Return`, 35 grant elements

## Recommendation

**Stage 3: target TY2023 + TY2024.** TY2023 fully filed, TY2024 substantially filed for calendar-year foundations. Y-o-Y comparison is the analytical payoff — TY2023-only forfeits it; TY2022-2024 adds noise without value.

Caveat: fiscal-year filers (Collins' Aug FYE) place their TY filing in the *following* calendar year's index. Stage 3 lookup must search current + prior index per EIN, not just one.
