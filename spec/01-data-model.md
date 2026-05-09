# NomadTracker — Data Model Specification

## Core Data Entities

### CountryManagedObject

Represents a country and its visa rules. Loaded from `visa_database.json` at app launch.

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | String | ISO 3166-1 alpha-2 code (e.g., "US", "DE") |
| `name` | String | Full country name (e.g., "Germany") |
| `region` | String | Geographic region (e.g., "Europe", "South America") |
| `defaultStayDays` | Int16 | Default allowed stay duration (e.g., 90) |
| `maxExtensionDays` | Int16 | Maximum extension days available |
| `ruleType` | String | Visa rule: `calendar_year`, `rolling_90_180`, `rolling_window` |
| `multipleEntry` | Bool | Whether multiple entries are allowed |
| `visaRequired` | Bool | Whether a visa is required for entry |
| `schengen` | Bool | Whether country is part of Schengen zone |
| `notes` | String? | Additional notes about visa rules |

**Total Max Days:** `defaultStayDays + maxExtensionDays`

**Data Source:** `visa_database.json` bundled with the app. Contains 195+ countries.

### StayManagedObject

Represents a stay in a country. Created manually or imported from Photos.

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | UUID | Unique identifier for the stay |
| `countryId` | String | ISO code of the country (FK to Country.id) |
| `countryName` | String | Denormalized country name |
| `entryDate` | Date | Date/time of entry |
| `exitDate` | Date? | Date/time of exit (nil = still in country) |
| `visaType` | String | Visa type: `tourist`, `digital_nomad`, `temporary_resident`, `transit`, `other` |
| `notes` | String? | User notes about this stay |
| `createdAt` | Date | When the stay record was created |
| `daysSpent` | Int16 | Computed days spent (cached) |
| `daysRemaining` | Int16 | Computed days remaining (cached) |
| `maxAllowedDays` | Int16 | Country-specific max days (cached) |

**Active Stay:** `exitDate == nil`

**Sort Order:** `entryDate` descending (most recent first)

## Domain Models (Swift structs)

### Country

Pure Swift struct for UI binding. Loaded from JSON, NOT persisted in Core Data.

```swift
struct Country: Identifiable, Codable, Hashable {
    let id: String              // ISO 3166-1 alpha-2
    let name: String
    let region: String
    let defaultStayDays: Int
    let maxExtensionDays: Int
    let ruleType: RuleType
    let multipleEntry: Bool
    let visaRequired: Bool
    let visaType: String?
    let isSchengen: Bool
    let digitalNomadVisa: DigitalNomadVisa?
    let notes: String?
}
```

### Stay

Pure Swift struct for UI binding. Fetched from Core Data on demand.

```swift
struct Stay: Identifiable, Codable {
    let id: UUID
    let countryId: String
    let countryName: String
    let entryDate: Date
    let exitDate: Date?
    let visaType: VisaType
    let notes: String?
    let createdAt: Date
}
```

### StayStatus

Enum representing visa compliance status.

```swift
enum StayStatus {
    case safe(daysRemaining: Int)       // > 30 days remaining
    case warning(daysRemaining: Int)    // 15-30 days remaining
    case critical(daysRemaining: Int)   // 3-14 days remaining
    case expired(daysOver: Int)         // Over limit
    case active(daysSpent: Int, daysRemaining: Int)
}
```

### YearSummary

Annual breakdown of days per country.

```swift
struct YearSummary: Identifiable {
    let id = UUID()
    let year: Int
    let totalDays: Int
    let countryDays: [String: Int]  // country_name -> days
}
```

### AlertConfig

User-configurable alert thresholds.

```swift
struct AlertConfig: Codable {
    var thresholds: [Int] = [30, 15, 7, 3, 1]
}
```

Stored in `UserDefaults` under key `nomad_alert_config`.

## Shared Data (App Group)

### SharedStayData

Struct for sharing stay data with widgets via `UserDefaults(suiteName: AppGroup.suiteName)`.

```swift
struct SharedStayData: Codable {
    let id: UUID
    let countryName: String
    let countryCode: String
    let daysSpent: Int
    let daysRemaining: Int
    let maxDays: Int
    let entryDate: Date
    let exitDate: Date?
    let visaType: String
    let notes: String?
}
```

**Sync Keys in App Group UserDefaults:**
- `nomad_active_stays` — JSON array of active stays
- `nomad_current_stay` — JSON dict of most recent active stay
- `nomad_year_summary` — JSON dict of current year summary
