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

**API:** `StayStore.importStaysFromJSON()`

**Process:**
1. Parse JSON into `[Stay]` array
2. Create `StayManagedObject` for each stay
3. Save to Core Data
4. Sync to App Group for widgets

**Current data:** 64 stays across 24 countries from 39,935 photos.

## Known Issues

- Single-day stays (entry == exit) may be noise — consider filtering stays < 1 day
- Cities extracted from GPS are approximate (reverse geocoded)
- No visa type detection — all imported stays default to `tourist`
