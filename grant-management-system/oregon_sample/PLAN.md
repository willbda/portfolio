# Oregon Sample Database — Plan

Written by Claude Code on 2026-04-23.

A sister to `../mock/`, but populated with **real** Oregon arts/culture and
recreation/sports nonprofits (from IRS BMF) and **real** grant history (from
IRS 990 bulk data). Runs inside the normal GMS app against an isolated
config dir — no CRM/Google secrets needed. Built in response to a challenge
from a friend: reimplement GMS around Oregon A/N concerns.

## Guiding constraints

- **Real funders, real history.** Unlike `mock/`, names are not Faker-generated.
  This is the deliberate difference from the existing portfolio mock.
- **No secrets required.** Launches via `GMS_CONFIG_DIR=/tmp/gms-oregon-scratch`
  per ADR 009 (`/Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/grant_management_system/project_management/docs/adr/009-credential-storage-and-connector-configuration.md`).
  Until ADR 009 lands, `env -i` fallback works.
- **Reproducible.** Every fetched artifact (TIGER shapefile, BMF CSV, 990 XML)
  is cached under `oregon_sample/` and gitignored. Scripts re-run cleanly.
- **Idempotent ingestion.** Each stage can re-run without duplicating rows,
  mirroring the `ON CONFLICT` patterns from the MN scripts.

## Pipeline

Four stages, each a script, each producing a cached artifact consumed by the
next.

### Stage 1 — Geography (`01_fetch_geography.py`)

Fetches Oregon administrative boundaries from TIGER/Line 2025 (state FIPS 41):

- **Counties** — `tl_2025_41_county.zip` (36 polygons)
- **Places** — `tl_2025_41_place.zip` (cities, CDPs)
- **Tribal lands** — `tl_2025_us_aiannh.zip` filtered to OR
- Reprojected to EPSG:4326.
- Cached under `oregon_sample/geo_data/` (gitignored).
- Deferred: the 7 Regional Arts Councils service areas — synthesized from
  county groupings rather than fetched as polygons.

Mirrors the pattern from `../mock/generate_mock.py` (school-district loader)
and `grant_management_system/scripts/import_mn_counties.py`.

### Stage 2 — Funders + Grantees from BMF (`02_fetch_funders.py`)

Source: `https://www.irs.gov/pub/irs-soi/eo_or.csv` (IRS Business Master File
for Oregon).

Two cuts:

- **Funders** — Oregon private foundations (FOUNDATION codes 02/03/04) and
  NTEE T-code grantmakers (T20, T21, T22, T30). All private foundations are
  included regardless of A/N alignment — their giving patterns are what we
  care about, and the 990-PF parsing pipeline treats them uniformly.
- **Grantees (canonical orgs)** — Oregon 501(c)(3) public charities with NTEE
  starting `A*` (Arts/Culture) or `N*` (Recreation/Sports).

Both go into the canonical-org tables (`funders` / `legal_entities` /
`funder_legal_entities` / `funder_aliases`) using the Bernie Registry pattern
from `register_mn_grantmakers.py`. Addresses land in `addresses` +
`entity_addresses` using the `ingest_bmf_addresses.py` pattern, but simplified
— the BMF CSV has street-level data directly, no geocoded-CSV sidecar needed.

Output: `oregon_sample/funder_data/funders.csv` + `grantees.csv` (cached
extracts; reproducible from `eo_or.csv`).

### Stage 3 — 990 history (`03_fetch_990_history.py`)

For each funder EIN identified in Stage 2:

1. Grep IRS bulk index CSVs
   (`https://apps.irs.gov/pub/epostcard/990/xml/{YEAR}/index_{YEAR}.csv`) for
   tax periods 202212–202412.
2. For each matching row, fetch only the specific `{OBJECT_ID}_public.xml`
   from its batch zip (the cherry-pick pattern from
   `workflow_irs_990_refresh.md`).
3. Parse 990 (Schedule I `RecipientTable`) or 990-PF (Part XV
   `GrantOrContributionPdDurYrGrp`) using a unified parser in
   `oregon_sample/lib/parse_990.py`.
4. Write a `profiles.json` in the shape consumed by
   `grant_management_system/scripts/import_990_profiles.py`.

The unified parser is **new code** — the reference implementation currently
lives in a GMS notebook (`irs_990_grant_mapping.ipynb`) and the extractor
script referenced by `import_990_profiles.py` is missing. We write it here,
and GMS can adopt it later.

Cache raw XMLs under `oregon_sample/xml_cache/{ein}_{tax_year}.xml`
(gitignored).

### Stage 4 — Assembly (`04_build_db.py`)

1. Copy `../schema/draft_schema.sql` → `oregon_sample/oregon.db`.
2. Load SpatiaLite extension, create SRID metadata.
3. Load Oregon counties/places from Stage 1 into `geo_places` +
   `geo_place_geoids`.
4. Register Stage 2 funders and grantees into the canonical-org tables,
   with addresses.
5. Ingest Stage 3 `profiles.json` into `irs_990_filings` + `irs_990_grants`.
6. Generate a small set of synthetic opportunities + applications linking
   canonical orgs to geographies, so the GMS opportunity views have data to
   render. (This is the only synthetic layer — the orgs and grant history
   are real.)
7. Emit `user_settings.yaml` and launch instructions.

## Research outcomes (2026-04-23)

Three background agents resolved the Stage 2/3/4 open questions. Findings
live in `research_bmf.md`, `research_990_indices.md`, and the schema audit
summary below.

### BMF (`research_bmf.md`)

- `eo_or.csv` has 26,793 rows, all 28 standard BMF columns, 22,166 OR
  501(c)(3)s.
- **Do not filter funders by A/N NTEE.** Most OR foundations give
  cross-category. Split by **FOUNDATION code**, not NTEE:
  - **Grantees** — `SUBSECTION=03 AND NTEE LIKE 'A%' OR 'N%' AND FOUNDATION
    IN (09..18)`. ~3,800 rows. This is the realistic applicant pool.
  - **Funders** — `FOUNDATION IN (02,03,04)` statewide (1,146 private
    foundations, the 990-PF universe) ∪ `NTEE LIKE 'T2%' OR 'T30%'` (596
    grantmaking public charities / community foundations).
- **Hybrid orgs exist** (e.g. Mt Hood Ski Racing League is A/N and FOUND=04 —
  both grantee-shaped and funder-shaped). The `organizations.is_grantmaker`
  boolean in the existing schema handles this natively; our assembly script
  sets `is_grantmaker=1` for anything in the funder set.

### 990 indices (`research_990_indices.md`)

- Indices for 2023/2024/2025/2026 are all live. 2026 is a partial-year index.
- **2023 index lacks `XML_BATCH_ID`** (9 cols, not 10) — Stage 3 needs a
  fallback batch-lookup for rows pulled from the 2023 index.
- **Fiscal-year filers**: a foundation with an August FYE (like Collins
  Foundation) files TY202308 into the **2023** index and TY202408 into the
  **2025** index. Stage 3 lookup must search *current + prior* calendar-year
  indices per EIN, not just one.
- **Selective extract verified** via `curl | bsdtar -xf - <filename>` — pulls
  one 100 KB XML out of a 103 MB batch zip without persisting the zip. 35
  grant elements parsed cleanly.
- **Decision: Stage 3 targets TY2023 + TY2024.** TY2023 fully filed, TY2024
  substantially filed for calendar-year foundations. Y-o-Y comparison is the
  analytical payoff; single-year forfeits it.
- **EIN verification is mandatory**: the workflow doc's example Collins EIN
  (`930347943`) is wrong — correct Oregon Collins is `742254030`. Every
  funder EIN coming out of Stage 2 must be confirmed against at least one
  index before Stage 3 fetches anything.

### Schema audit (portfolio `draft_schema.sql`)

GMS has already migrated from `funders` → `organizations`. Portfolio schema
reflects the new names. Oregon scripts therefore use:

| MN-era name | Portfolio schema name |
|---|---|
| `funders` (bernie_id, canonical_name) | **`organizations`** (+ `is_grantmaker`) |
| `funder_legal_entities` | **`org_legal_entities`** |
| `funder_aliases` | **`org_aliases`** |
| `entity_addresses.entity_type='funder'` | **`entity_addresses.entity_type='organization'`** |

Other required tables all present: `legal_entities`, `bn_sequence`,
`bn_audit_log`, `ref_cities`, `addresses`, `geo_places` (uses
`geometry_json` — JSON fallback, not SpatiaLite), `geo_place_geoids`,
`irs_990_filings`, `irs_990_grants`.

### Known schema gap: `is_mn` in `irs_990_grants`

`irs_990_grants.is_mn` is hard-coded into the schema snapshot. For Oregon
we'll **write 0 into `is_mn`** and add a sibling column via a Stage 4 ALTER
TABLE: `is_or INTEGER DEFAULT 0`. Long-term fix (generalize to
`in_state TEXT` with a two-char code) belongs in the canonical GMS schema,
not this portfolio sample.

## Launch

```bash
# With ADR 009 (future):
GMS_CONFIG_DIR=/tmp/gms-oregon-scratch \
  DATABASE_PATH=.../oregon_sample/oregon.db \
  SETTINGS_PATH=.../oregon_sample/user_settings.yaml \
  python -m sources.app.run --port 5002

# Today (pre-ADR-009):
env -i HOME=$HOME PATH=$PATH \
  DATABASE_PATH=.../oregon_sample/oregon.db \
  SETTINGS_PATH=.../oregon_sample/user_settings.yaml \
  python -m sources.app.run --port 5002
```

## Artifacts produced

- `oregon_sample/oregon.db` — SQLite + SpatiaLite, gitignored.
- `oregon_sample/geo_data/` — cached TIGER shapefiles, gitignored.
- `oregon_sample/funder_data/` — cached BMF extracts (eo_or.csv + filtered
  CSVs), gitignored.
- `oregon_sample/xml_cache/` — cached 990 XMLs, gitignored.
- `oregon_sample/lib/` — Python helpers (990 parser, TIGER loader), checked in.
- `oregon_sample/01_*.py` … `04_*.py` — stage scripts, checked in.
- `oregon_sample/user_settings.yaml` — GMS launch config, checked in.
- `oregon_sample/PLAN.md` — this file, checked in.
- `oregon_sample/README.md` — launch instructions, checked in.

## Final state (end of 2026-04-23 session)

oregon.db now holds:

| Metric | Value |
|---|---|
| Canonical orgs | **5,036** (1,333 grantmakers + 3,703 arts/rec grantees) |
| Geocoded addresses | 3,380 (67% rooftop-precision, remainder PO-box / typo) |
| Org → county links | **5,061** (99% coverage; 3,379 via lat/lon, 1,582 via city fallback) |
| 990 filings loaded | **1,729** (TY2023 + TY2024) |
| Grant records | **29,097** (21,397 OR-in-state) |
| Grant → org matches | **2,089** (582 distinct OR grantees linked to 990 giving) |
| OR in-state grant dollars captured | **$1,009,000,000** |
| Top-funded OR recipient (unfiltered) | University of Oregon Foundation — $286M from 25 funders |
| Top-matched OR grantee | Portland Art Museum — 35 funders, 61 grants, $4.8M |

Working UI paths in the Flask app (run against oregon.db on port 5002):

- `/organizations/` — All Orgs / All Grantmakers / Prospects tabs work; 5,036 rows
- `/organizations/<bn>` — real BMF address, EIN, aliases; IRS 990 panel for funders (TY2023/TY2024 selector, grantmaking grant count)
- `/organizations/<bn>/990` — full 990 view with recipient / location / purpose / amount columns sorted by grant size
- `/geo/edit?entity_type=organization&entity_id=<bn>` — county polygon rendering; auto-linked via Stage 2c

## Progress (2026-04-23)

- ✅ **Stage 1** — `01_fetch_geography.py`: 36 counties, 426 places, 24
  tribal lands in `geo_data/geography.json` (1 MB, EPSG:4326).
- ✅ **Stage 4 init** — `04_build_db.py --reset`: `oregon.db` created from
  `draft_schema.sql`, `is_or` column added to `irs_990_grants`, bn_sequence
  seeded, 486 geo_places loaded (counties as `county`, places as `city`,
  tribal lands as `custom` since the schema CHECK doesn't allow
  `tribal_land`). 462 geoids indexed.
- ✅ **GMS serving oregon.db** on `http://127.0.0.1:5002/` via `env -i +
  absolute-python-path` — headed Chromium open so runs update the UI live.
- ✅ **Stage 2** — `02_fetch_funders.py`: 5,036 organizations registered
  from IRS BMF (eo_or.csv, 26,793 rows). Breakdown:
  - 1,333 grantmakers (PFs with FOUND 02/03/04 + T2x/T30 grantmakers)
  - 3,703 grantees (A/N 501c3 public charities, FOUND 09-18)
  - 5,036 org addresses, 292 OR cities. Top cities by org count:
    Portland (1,248), Eugene (260), Salem (234), Bend (210).
- ✅ Research tasks 3 (BMF), 4 (990 indices), 5 (schema) complete.
- ⏭ **Task #9 essential before Stage 3** — EIN verification. Spot check:
  BMF has only *one* "Collins Foundation" in OR (EIN 936021893, Portland).
  The 990 research agent surfaced 742254030 as "the real Collins"; the
  workflow doc has 930347943. Three different numbers across three sources
  means we must programmatically confirm every funder EIN against the 990
  indices before Stage 3 fetches anything.
- ⏭ **Stage 3** — TY2023 + TY2024 990 history pulls with fiscal-year-aware
  index search across current + prior calendar-year indices.
- ⏭ **Stage 4 finalization** — grant import + synthetic opportunities.
