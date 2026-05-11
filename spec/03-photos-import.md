# NomadTracker — Photos Import Specification

## Overview

NomadTracker can import travel history from iCloud Photos by extracting GPS coordinates from photo metadata, geocoding them to countries, and generating stay records.

## Data Flow

```
iCloud Photos → Python Script → GPS Data → Geocoding → Country Stays → JSON → Core Data
```

## Step 1: Extract GPS Data from Photos

**Tool:** Python script using Apple Photos framework via `photos-geolocation-analytics` skill.

**Input:** User's iCloud Photos library on macOS.

**Output:** List of photos with:
- Timestamp (`dateCreated`)
- GPS coordinates (`latitude`, `longitude`)
- Location name (if available)

**Filtering:** Only photos with GPS metadata are extracted.

## Step 2: Geocode to Countries

**Tool:** Reverse geocoding via OpenStreetMap Nominatim or local database.

**Process:**
1. For each photo, reverse-geocode (lat, lon) → country code
2. Group photos by country
3. Sort by timestamp within each country

## Step 3: Generate Stay Records

**Algorithm:**
1. For each country, find consecutive photo clusters
2. A new stay begins when:
   - First photo in country, OR
   - Gap > 7 days between photos in same country
3. Stay ends when:
   - Last photo in country before next stay, OR
   - User leaves the country (photos appear in different country)

**Output format:** `photos_import.json`

```json
{
  "exported_at": "ISO 8601 timestamp",
  "source": "Apple Photos Library",
  "total_photos": 39935,
  "countries_visited": 24,
  "total_stays": 64,
  "stays": [
    {
      "country_code": "AR",
      "country_name": "Argentina",
      "entry_date": "2022-04-21T19:32:11.093000+00:00",
      "cities": ["Colegiales", "Retiro"],
      "exit_date": "2022-04-21T19:32:11.093000+00:00"
    }
  ]
}
```

## Step 4: Import to Core Data

**API:** `PersistenceController.importBundledPhotosData()` / `importStaysFromJSON(data:)`

**Process:**
1. Check import version in `UserDefaults` key `photosImportVersion`
2. If version differs from current, delete all existing stays and re-import clean
3. Parse JSON stays with robust date parsing (see Date Parsing below)
4. Filter out zero-duration and out-of-order stays
5. Auto-close stays with no exit date that are older than the visa allowance (see Ghost Stays below)
6. Save `StayManagedObject` records to Core Data
7. Store import version in `UserDefaults` on success

**Current data:** 64 raw stays from 39,935 photos → ~52 valid stays after filtering.

## Date Parsing

Photos export timestamps include microsecond fractional seconds (e.g., `2022-04-21T19:32:11.093000+00:00`). The default `ISO8601DateFormatter()` does not handle fractional seconds and silently returns `nil`, which caused all 44 affected entry dates to fall back to `Date()` (today).

The import uses a two-pass parser:

```swift
func parseDate(_ str: String) -> Date? {
    let withFractional = ISO8601DateFormatter()
    withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = withFractional.date(from: str) { return d }
    let plain = ISO8601DateFormatter()
    plain.formatOptions = [.withInternetDateTime]
    return plain.date(from: str)
}
```

Stays where the entry date cannot be parsed are skipped entirely.

## Zero-Duration Stay Filtering

GPS artifacts produce stays where `entry_date == exit_date`. These are skipped:

```swift
if let exit = exitDate, exit <= entryDate { continue }
```

## Ghost Active Stays

The photos pipeline only captures entry photos reliably. Many trips have no exit photo, leaving `exit_date` absent. Without an exit date, the domain model treats the stay as ongoing and computes `daysSpent` from entry to today — producing values of 500–900+ days for old trips.

During import, any stay with no recorded exit date that started more than 90 days ago is auto-closed at `entry + 90 days`:

```swift
if exitDate == nil {
    let daysSinceEntry = calendar.dateComponents([.day], from: entryDate, to: Date()).day ?? 0
    if daysSinceEntry > 90 {
        resolvedExit = calendar.date(byAdding: .day, value: 90, to: entryDate)
    }
}
```

This is a heuristic — 90 days is used as the default visa allowance. Stays the user genuinely has open (started within the last 90 days) are kept active. Users can correct auto-closed stays manually.

## Versioned Re-import

The import tracks a version string in `UserDefaults(suiteName: nil)` under key `photosImportVersion`. When the version changes, all existing stays are deleted and the import runs fresh. This allows data corrections to be deployed without requiring a database migration.

Current version: `v3`

## Known Limitations

- Cities extracted from GPS are approximate (reverse geocoded)
- No visa type detection — all imported stays default to `tourist`
- Auto-close at 90 days is a heuristic; actual trip length may differ
