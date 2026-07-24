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

Only files under `NomadTracker/Resources/` are bundled into the app (see `generate_xcodeproj.py`). The `Data/` copies are the checked-in masters — keep the two in sync when editing.

- `visa_database.json` — authoritative source for 195+ countries; `NomadTracker/Resources/visa_database.json` is the bundled copy, `Data/visa_database.json` the master. Loaded by both `PersistenceController` (into Core Data) and `StayStore` (into `[Country]` structs)
- `photos_import.json` — pre-generated travel history from Apple Photos GPS; bundled copy `NomadTracker/Resources/photos_import.json`, master `Data/photos_import.json`; auto-imported on first launch if no stays exist
- `Scripts/import_photos_data.py` — generates `photos_import.json` from Apple Photos metadata

## Project Generation

**Do NOT run `generate_xcodeproj.py`.** Despite its docstring (and older guidance), it produces a `project.pbxproj` that this Xcode cannot open — products are emitted as `PBXNativeTarget` instead of `PBXFileReference`, build-phase UUIDs don't match their objects, there are no `PBXBuildFile` entries, and it hardcodes `SDKROOT = iphoneos` on a macOS app. It also `shutil.rmtree()`s the whole `.xcodeproj` first, destroying the real project file and the untracked `xcshareddata/` scheme. `project.yml` (xcodegen) is likewise stale/aspirational.

**The real `NomadTracker.xcodeproj/project.pbxproj` is hand-/Xcode-maintained** (objectVersion 77, proper `PBXBuildFile`s, per-target macOS/iOS build settings). To add or remove a source/resource file, edit it in Xcode (which maintains the pbxproj correctly), or hand-edit the pbxproj: add a `PBXFileReference`, a `PBXBuildFile`, a child entry in the owning `PBXGroup`, and an entry in the target's Sources/Resources build phase.

- **Target membership is by group/build-phase, not by folder path.** The app target (`NomadTracker`) and `Shared/` compile together; `NomadTrackerWidget` and `NomadTrackerIntents` are separate extensions. `NomadTrackerIntents` is still configured `SDKROOT = iphoneos` and requires a signing team, so it won't build for a macOS destination without setup — the app scheme does not depend on it.
- **Only files under `NomadTracker/Resources/` are bundled** (see Data Files above); the app's `.xcassets` folder is referenced as a whole, so assets inside it (e.g. `AppIcon`) need no separate pbxproj entry.
- **No duplicate type names in one target.** Two files defining the same type cause a redeclaration error. (This bit the now-removed `Views/History/HistoryView.swift`, which duplicated `Views/HistoryView.swift`.)
