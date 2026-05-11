# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Open in Xcode (primary development workflow)
open NomadTracker.xcodeproj

# Regenerate xcodeproj from scratch (run after adding/removing files)
python3 generate_xcodeproj.py

# Build from command line
xcodebuild -project NomadTracker.xcodeproj -scheme NomadTracker -configuration Debug build

# Build for macOS specifically
xcodebuild -project NomadTracker.xcodeproj -scheme NomadTracker -destination 'platform=macOS' build
```

There are no automated tests currently. The test target is defined but not implemented.

## Architecture

**Targets:**
- `NomadTracker` — macOS 14+ app (configured as macOS despite `project.yml` also listing iOS 17 in options; `generate_xcodeproj.py` generates the actual `.xcodeproj`)
- `NomadTrackerWidget` — WidgetKit extension with two widgets: `CurrentStayWidget` and `YearSummaryWidget`
- `NomadTrackerIntents` — Siri/Shortcuts intents extension

**Data flow:**
1. `PersistenceController` (singleton) owns the Core Data stack and loads the visa database from `visa_database.json` + bootstraps travel history from `photos_import.json` on first launch
2. `StayStore` (`@MainActor ObservableObject`) fetches Core Data, exposes published arrays to the UI, and calls `VisaCalculator` for day-counting logic
3. On every mutation, `StayStore.syncToAppGroup()` serializes active stays to `UserDefaults(suiteName: "group.com.andeslabs.nomadtracker")` so widgets can read them
4. Widgets read `SharedStayData` from App Group; `Shared/SharedStayData.swift` is compiled into all three targets

**Key design decisions:**
- **Core Data model is created programmatically** in `PersistenceController.createModel()` — there is no `.xcdatamodeld` file driving it. This was done to avoid Xcode 26 model format incompatibilities. Do not add an `.xcdatamodeld` file; extend `createModel()` instead.
- `Stay` and `Country` are plain Swift structs used by the UI. `StayManagedObject` and `CountryManagedObject` are Core Data NSManagedObject subclasses; `toStay()` on the managed object produces the struct.
- `Stay.maxAllowedDays` hard-codes 90 as a fallback default. The authoritative limit comes from `StayStore.maxAllowedDays(for:)` → `Country.totalMaxDays` (`defaultStayDays + maxExtensionDays`).

## Visa Rule Types

`Country.ruleType` controls how `VisaCalculator` counts days:
- `calendar_year` — days reset Jan 1 each year (default)
- `rolling_90_180` — Schengen: max 90 days in any rolling 180-day window; counts all Schengen stays, not just the current country
- `rollingWindow` — defined but currently falls back to `calendarYear` logic

## Data Files

- `Data/visa_database.json` — authoritative source for 195+ countries; copied into the app bundle as a resource; loaded by both `PersistenceController` (into Core Data) and `StayStore` (into `[Country]` structs)
- `Data/photos_import.json` / `NomadTracker/Resources/photos_import.json` — pre-generated travel history from Apple Photos GPS; auto-imported on first launch if no stays exist
- `Scripts/import_photos_data.py` — generates `photos_import.json` from Apple Photos metadata

## Project Generation

`generate_xcodeproj.py` regenerates `NomadTracker.xcodeproj/project.pbxproj` programmatically. Run it whenever Swift files are added or removed, since Xcode won't auto-discover new files. `project.yml` (xcodegen format) documents intent but the actual build uses the generated `.xcodeproj`.
