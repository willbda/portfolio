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

A location-aware departure calculator for people with time blindness. Unlike standard "leave in 15 minutes" alerts, RunningBehind answers: *"What pace do I need to walk right now to arrive on time?"* It continuously recalculates required walking speed as time passes, translating abstract time into an embodied, physical metric.

Built with accessibility conformance, AppIntents integration (Siri, Shortcuts, Control Center widgets), and background GPS for live journey tracking. The architecture uses protocol-oriented design with a state machine governing the departure lifecycle (idle → preparing → departed → arrived).

**Stack:** Swift, SwiftUI, MapKit, CoreLocation, EventKit, ActivityKit (Live Activities)

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
