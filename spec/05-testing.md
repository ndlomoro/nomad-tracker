# NomadTracker — Testing Strategy

## Unit Tests

### VisaCalculator Tests
- Calendar year: verify day counting within Jan 1 – Dec 31
- Rolling 90/180: verify Schengen window aggregation across multiple countries
- Edge cases: stays spanning year boundaries, overlapping stays, same-day entry/exit
- Status thresholds: confirm safe/warning/critical/expired boundaries

### StayStore Tests
- CRUD operations: add, edit, delete, end stay
- Core Data persistence: verify saves survive process restart
- App Group sync: verify widget data matches main app state
- Year summary: verify correct day allocation across year boundaries

### PersistenceController Tests
- Database initialization: verify schema migration
- Concurrent access: multiple saves without corruption

## Integration Tests

### Photos Import Pipeline
- End-to-end: JSON import → Core Data → widget sync
- Verify imported stays appear in DashboardView and HistoryView

### Widget Data Flow
- Main app adds stay → widget reflects change within 10 seconds
- Year summary widget updates when stays cross year boundary

## Test Targets

```
NomadTrackerTests/
├── VisaCalculatorTests.swift
├── StayStoreTests.swift
├── PersistenceControllerTests.swift
└── PhotosImportTests.swift
```

## Coverage Goals

- VisaCalculator: 100% (core business logic)
- StayStore: 80%+ (CRUD + sync)
- Views: Smoke tests only (SwiftUI previews handle visual testing)
