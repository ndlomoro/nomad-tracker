# NomadTracker — UI Architecture Specification

## Navigation Structure

Tab-based navigation with 5 tabs:

```
ContentView (TabView)
├── DashboardView      (house.fill)     — Overview of active stays
├── StayTrackerView    (plus.circle.fill) — Add/edit/delete stays
├── HistoryView        (clock.arrow.circlepath) — Year-by-year history
├── AlertsView         (bell.badge.fill) — Alert configuration
└── SettingsView       (gearshape.fill) — Data export/import/reset
```

## View Details

### DashboardView
- Shows count of active stays and year total days
- Lists `CountryCardView` for each active stay
- Empty state: globe icon + "No active stays" message

### CountryCardView
- Displays country flag emoji (from ISO code)
- Shows days spent / max days
- Countdown ring visualization (`CountdownRingView`)
- Status color: green (safe), orange (warning), red (critical/expired)

### StayTrackerView
- List of all stays (active and past)
- Swipe-to-delete on each stay
- "Add Stay" button opens `AddStaySheet`
- Tap stay to edit (entry date, visa type, notes)

### AddStaySheet
- Country picker (searchable, filtered by `availableCountries`)
- Entry date picker (defaults to today)
- Visa type picker (Tourist, Digital Nomad, Temporary Resident, Transit, Other)
- Notes text field (optional)

### HistoryView
- Year picker (shows years with stays)
- Year summary: total days + per-country breakdown
- Empty state for years with no stays

### AlertsView
- Toggle switches for alert thresholds: 30, 15, 7, 3, 1 days
- Config persisted in UserDefaults

### SettingsView
- Export stays as JSON
- Import stays from JSON file
- Reset all data (destructive action)
- App version and credits

## Environment Objects

- `StayStore` — Central data store (stays, countries, calculations)
- `AlertManager` — Notification management

Both injected at `NomadTrackerApp` level.

## Theming

- Primary color: `Color.nomadBlue` (rgb: 0.2, 0.5, 0.9)
- Background: `Color.nomadBackground` (rgb: 0.97, 0.97, 0.98)
- Tab tint: `Color.nomadBlue`

## Widget Extensions

### CurrentStayWidget
- Shows current active stay
- Country flag + days remaining
- Updates via App Group UserDefaults

### YearSummaryWidget
- Shows current year total days
- Per-country breakdown
- Updates via App Group UserDefaults
