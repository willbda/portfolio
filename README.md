# David Williams — Portfolio

Analytical tools, data work, and application development from my work as Development Manager at ServeMinnesota and independent projects.

## What's Here

### `grant-management-system/`

**A grant intelligence platform for a five-person team managing $16M+ in funding.**

Before this system, answering "which funders support literacy programs in Hennepin County?" meant hours of manual cross-referencing across a CRM, a spreadsheet, and a shared drive full of nested folders. Preparing for a funder meeting meant opening six tabs and hoping you remembered which subfolder had last year's report. Prospecting meant gut instinct and institutional memory.

Now it's a query.

#### What it does

The system consolidates grant data from four sources — Google Sheets task tracking, a Bloomerang CRM, 23,000+ documents on a shared drive, and IRS 990 filings — into a single SQLite database with full-text search, geospatial queries, and analytical views.

A development officer can:
- Search across thousands of narrative documents by keyword and see highlighted snippets
- Ask which funders have historically supported a specific program area, and how much they gave
- Map service sites against funder territories to find geographic alignment
- See team workload distribution, deadline heatmaps, and win rates by fiscal year
- Track the full lifecycle of an opportunity from prospect to award to report

#### Why it's built this way

The core design problem: our data sources use different vocabularies, different structures, and different identifiers for the same things. A funder might appear as "Gates Foundation" in the spreadsheet, "Bill & Melinda Gates Foundation" in the CRM, and live inside a folder called `Gates_2025/`. A proposal status might be "1. Awarded" in one system and "awarded" in another.

Rather than writing custom code for each source, the ETL pipeline is **config-driven**. Adding a new data source requires only database rows — field mappings, status translations, program lookups — not Python changes. The `TransformCoordinator` uses bulk `INSERT...SELECT...JOIN` against configuration tables, so the same SQL handles every source.

On top of the raw data, **domain entities** provide the business model: Organizations have canonical identities with alias resolution. Opportunities group related records across systems — one grant application might span a Writing Schedule task, three CRM interaction notes, and a folder of proposal drafts. The database enforces these relationships, not the application code.

#### Architecture highlights

- **Two-tier fact table pattern** — A header row links to child tables (titles, statuses, dates, amounts, programs, notes), so different source shapes coexist without nullable columns or schema changes per source
- **SQL views as structural contracts** — All multi-table reads go through views. A Python `ViewTable` class fuses the typed dataclass and SQL metadata into one declaration, catching column mismatches at construction time
- **Config-driven ETL** — `FetchDispatcher` resolves route keys to API calls via database config. `SnapshotHasher` deduplicates via SHA-256 content hashing. `TransformCoordinator` decomposes JSON snapshots into normalized facts in a single transaction
- **SpatiaLite geospatial queries** — Service site addresses geocoded and matched against funder territory boundaries
- **FTS5 full-text search** — Porter stemming across 23,000+ extracted documents

**Stack:** Python 3.12, Flask, SQLite (WAL mode), SpatiaLite, Jinja2, Alpine.js, Plotly, Leaflet

Detailed documentation:
- [`architecture.md`](grant-management-system/architecture.md) — System design, data model, query DSL, and design decisions
- [`etl-pipeline-overview.md`](grant-management-system/etl-pipeline-overview.md) — How data flows from raw sources to structured, searchable records
- [`sample-queries.sql`](grant-management-system/sample-queries.sql) — Analytical queries against the database
- `screenshots/` — Application interface *(coming soon with anonymized data)*

### `notebooks/`
Jupyter notebooks demonstrating analytical work. All use synthetic data generated inline — fully self-contained, anyone can clone and run them.


### Happy to Have Lived

**A goal-planning app that starts with what matters, not what's due.**

Happy to Have Lived begins with values: what do you think is worthwhile? From there, you define goals that connect to those values, set time-boxed terms to focus your energy, and record actions — including imports from Apple Health. The Reflect tab shows how your values, goals, and actions connect, so you can see whether what you're doing aligns with what you care about.

#### Why this exists

I built this for myself. I'd been using various goal-tracking systems — spreadsheets, journaling, habit apps — and none of them captured the thing that actually mattered: whether the goals I was pursuing reflected what I valued, or just what felt urgent. I wanted a system where the first question is "what do you value?" and everything else flows from the answer.

The ten-week term structure comes from my own practice. Long enough to make real progress, short enough that the end is always visible. Each term is a chapter with a focus, not an open-ended to-do list.

#### How it works

The app is organized around four tabs:

- **Now** — Today's view. What's active, what needs attention, a daily greeting.
- **Plan** — Define values, set goals, create time-boxed terms. The facilitated start flow walks new users through articulating what matters before asking them to plan anything.
- **Record** — Log actions toward your goals. Import workouts from Apple Health so exercise counts as progress without manual entry.
- **Reflect** — See patterns. Value Connections shows which values your goals serve. Review past terms to understand what worked.

#### Screenshots

| Facilitated Start | Now | Plan | Reflect |
|:-:|:-:|:-:|:-:|
| ![Onboarding](happy-to-have-lived/screenshots/01-facilitated-start.png) | ![Daily view](happy-to-have-lived/screenshots/02-now.png) | ![Planning](happy-to-have-lived/screenshots/03-plan.png) | ![Reflection](happy-to-have-lived/screenshots/04-reflect.png) |
| Begin with what matters | Today's focus | Values → goals → terms | See how it connects |

| Values | Record |
|:-:|:-:|
| ![Values entry](happy-to-have-lived/screenshots/05-values.png) | ![Actions + Health](happy-to-have-lived/screenshots/06-record.png) |
| Articulate what you value | Log actions, import from Health |

#### Architecture

This is the project where I went deep on Swift and domain modeling. Unlike RunningBehind (where I prioritized shipping), Happy to Have Lived is where I practiced building a real data model from first principles — asking what a goal actually *is*, what it means for a value to connect to an action, how to represent progress without flattening it into a percentage.

Three-layer Swift Package Manager structure with normalized SQLite models (via GRDB), a centralized `@Observable` DataStore that bridges database observation to SwiftUI, and on-device language generation via Apple Intelligence. The database pushes changes, the store holds state, views react automatically.

**Stack:** Swift 6.2, SwiftUI, GRDB, SQLite, HealthKit, Apple Intelligence (Foundation Models), AppIntents

Currently in active development toward v1.0. This app is approved for testing via Apple TestFlight: https://testflight.apple.com/join/rrpQRxYJ

### RunningBehind

**A departure calculator for people who lose track of time.**

Standard calendar alerts say "leave in 15 minutes."  For some of us, 15 minutes from now is a nebulous feeling of not-quite-now. RunningBehind answers a different question: What pace do I need to get there on time? It continuously recalculates as time passes, translating a countdown into something concrete and embodied.

#### Why this exists

Someone close to me lives with time blindness. The problem isn't not knowing when to leave — it's that "20 minutes" and "2 minutes" feel the same until it's two minutes too late. RunningBehind reframes departure as a physical relationship between your body and a destination. When the required pace shifts from "easy stroll" to "brisk walk" to "you'd better run," that's legible in a way a ticking number isn't.

#### How it works

You pick a destination and an arrival time. The app calculates a route, factors in your prep time (coat, keys, shoes) and arrival buffer (parking, elevator, finding the room), and tells you: *right now, you'd need to walk at 3.2 mph.* That number updates live. As time passes without you leaving, the pace climbs. Color-coded urgency — green, amber, red — makes the state immediately visible.

Once you depart, GPS tracking switches the display: now it shows your actual pace against the required pace, so you know if you're on track or need to pick it up.

**Key features:**
- Real-time pace calculation with urgency visualization
- Prep checklists with live time recalculation as you check items off
- Calendar integration — upcoming events surface as suggested destinations
- Custom travel modes (walking, cycling, driving) with per-mode speed units
- Live Activities on the lock screen during active journeys
- Journey history for reviewing patterns

#### Screenshots

| Departure | Destination | Modes | Modality Editor |
|:-:|:-:|:-:|:-:|
| ![Departure screen](running-behind/screenshots/01-departure.png) | ![Destination detail](running-behind/screenshots/04-destination-detail.png) | ![Travel modes](running-behind/screenshots/02-modes.png) | ![Custom modality](running-behind/screenshots/03-modality-editor.png) |

**Urgency progression** — the same trip as time passes:

| Relaxed | Time passing | Running late | Journey in progress |
|:-:|:-:|:-:|:-:|
| ![Relaxed](running-behind/screenshots/05-relaxed-calculation.png) | ![Urgency rising](running-behind/screenshots/06-urgency-rising.png) | ![Running late](running-behind/screenshots/07-running-late.png) | ![Journey tracking](running-behind/screenshots/08-journey-in-progress.png) |
| 1.3 mph — plenty of time | 1.4 mph — options narrowing | 4.9 mph — you need to leave | Departed — live pace tracking |

#### Built with AI

RunningBehind was built primarily through prompting — Claude Code writing Swift while I focused on product decisions, scope discipline, and shipping. This was a deliberate choice: unlike the Grant Management System, where I went deep on architecture and data modeling, here the goal was to define a narrow feature set, get to the App Store, and learn what it takes to maintain a shipped product.

What I practiced: describing intent clearly enough to produce usable code, recognizing when generated code was structurally wrong even when it compiled, and saying no to features that didn't belong in v1.

The app is feature-complete and in testing. Currently used daily by the person I built it for.

**Stack:** Swift 6.2, SwiftUI, GRDB, SQLite, MapKit, CoreLocation, EventKit, ActivityKit

Read more: [`building-with-ai.md`](running-behind/building-with-ai.md) — prompting strategy, what I learned, and the user story

## Technical Stack

- **Languages**: Python, SQL, Swift, JavaScript (basic)
- **Frameworks**: Flask, SwiftUI, GRDB
- **Data**: SQLite, SpatiaLite, Pandas, ETL pipelines
- **Visualization**: matplotlib, seaborn, Folium
- **AI/ML**: Claude Code (daily production use), prompt engineering, RAG architecture understanding
- **Tools**: Jupyter, VS Code

## About Me

Ph.D. in Philosophy (Johns Hopkins, 2025). Development Manager at ServeMinnesota since 2021. Self-taught programmer. Native English, fluent French. Relocating to Geneva, Switzerland in 2026.

I learn domains fast by asking questions. My work sits at the intersection of systems-building, data analysis, and clear communication.

[LinkedIn](https://www.linkedin.com/in/williamsbdavid/) | williamsbdavid@gmail.com
