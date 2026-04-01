# David Williams — Portfolio

Analytical tools, data work, and application development from my work as Development Manager at ServeMinnesota and independent projects.

## What's Here

### `grant-management-system/`
The project I built from scratch: a Flask/SQLite application that indexes 23,686 grant documents with full-text search, ETL pipelines, entity resolution, and geospatial queries.

- `architecture.md` — System design, data model, and technical decisions
- `screenshots/` — Application interface, search results, geospatial queries *(coming soon — screenshots will use anonymized data)*
- `sample-queries.sql` — Example analytical queries against the database
- `etl-pipeline-overview.md` — How documents flow from raw files to structured, searchable data

### `notebooks/`
Jupyter notebooks demonstrating analytical work. All use synthetic data generated inline — fully self-contained, anyone can clone and run them.


### Happy to Have Lived

A native iOS/macOS/visionOS application for structured goal planning and progress tracking. Built with Swift 6.2 and SwiftUI, it uses a three-layer architecture: normalized SQLite models (via GRDB), flat Codable data types for UI, and validated form data for input. A centralized `@Observable` DataStore bridges GRDB's `ValueObservation` to SwiftUI — the database pushes changes, the store holds state, and views react automatically.

Key features: hierarchical goals (goals, milestones, obligations, commitments), measurable progress tracking, Apple Health integration for importing workouts as actions, ten-week planning terms, and full JSON backup/restore. Currently in active development toward v1.0.

**Stack:** Swift 6.2, SwiftUI, GRDB, SQLite, HealthKit, AppIntents

### RunningBehind

**A departure calculator for people who lose track of time.**

Standard calendar alerts say "leave in 15 minutes." That's abstract — 15 minutes from now is a feeling, not a fact. RunningBehind answers a different question: *What pace do I need to walk right now to arrive on time?* It continuously recalculates as time passes, translating a countdown into something physical and embodied — a walking speed you can feel.

#### Why this exists

Someone close to me lives with time blindness. The problem isn't not knowing when to leave — it's that "20 minutes" and "5 minutes" feel the same until it's too late. RunningBehind reframes departure as a physical relationship between your body and a destination. When the required pace shifts from "easy stroll" to "brisk walk" to "you'd better run," that's legible in a way a ticking number isn't.

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

#### Architecture

Three-layer Swift Package Manager structure: **Models** (pure domain types, zero framework dependencies), **Database** (GRDB + SQLite with 10 migrations), and **AppServices** (coordinators that orchestrate route calculation, GPS tracking, and journey state). The app layer holds SwiftUI views and a centralized `@Observable` DataStore.

The journey lifecycle is a state machine: **planning → prepping → active → arrived**. Each transition changes what the UI displays and what the system tracks. Coordinators are stateless and testable — `DepartureCoordinator` takes a destination, time, and modality and returns a `DepartureCalculation`. No side effects, no global state.

All domain types are `Sendable` under Swift 6 strict concurrency. External services (MapKit, CoreLocation, EventKit) are abstracted behind protocols, so coordinators can be tested with in-memory fakes.

**Stack:** Swift 6.2, SwiftUI, GRDB, SQLite, MapKit, CoreLocation, EventKit, ActivityKit

**3,600 lines of tests** across domain logic, repositories, and coordinators using Swift Testing with in-memory SQLite.

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
