// NomadTracker.xcodeproj - Project Configuration
// iOS 17+ / macOS 14+ SwiftUI App with WidgetKit

// TARGETS:
//   1. NomadTracker (iOS App)
//   2. NomadTrackerWidget (Widget Extension)
//   3. NomadTrackerTests

// FRAMEWORKS:
//   - SwiftUI
//   - WidgetKit
//   - Intents
//   - Core Data
//   - UserNotifications
//   - MapKit
//   - Charts

// PROJECT STRUCTURE:
//
// NomadTracker/
// ├── App/
// │   ├── NomadTrackerApp.swift          // @main entry point
// │   └── AppDependencies.swift          // DI container
// │
// ├── Models/
// │   ├── Country.swift                  // Country + visa rules
// │   ├── Stay.swift                     // Entry/exit record
// │   ├── VisaAlert.swift               // Alert config
// │   └── CoreData/NomadTrackerModel.xcdatamodeld/
// │
// ├── Views/
// │   ├── ContentView.swift             // Main tab navigation
// │   ├── Dashboard/
// │   │   ├── DashboardView.swift        // Current status overview
// │   │   ├── CountryCardView.swift      // Per-country status card
// │   │   └── CountdownRingView.swift    // Circular progress
// │   │
// │   ├── Tracker/
// │   │   ├── StayTrackerView.swift      // Log entry/exit
// │   │   ├── CountryPickerView.swift    // Country selection
// │   │   └── DateRangePickerView.swift  // Entry/exit dates
// │   │
// │   ├── History/
// │   │   ├── HistoryView.swift          // Past stays timeline
// │   │   ├── YearSummaryView.swift      // Annual breakdown
// │   │   └── ExportView.swift           // Export travel history
// │   │
// │   ├── Alerts/
// │   │   ├── AlertsView.swift           // Active alerts list
// │   │   └── AlertSettingsView.swift    // Configure thresholds
// │   │
// │   └── Settings/
// │       ├── SettingsView.swift         // App settings
// │       └── PassportCountryView.swift  // User's nationality
// │
// ├── ViewModel/
// │   ├── StayTrackerViewModel.swift     // Core tracking logic
// │   ├── AlertManager.swift            // Notification scheduler
// │   └── VisaCalculator.swift          // Day counting + rules
// │
// ├── Services/
// │   ├── CoreDataStack.swift           // Persistence container
// │   ├── LocationService.swift         // GPS auto-detection
// │   └── ExportService.swift           // PDF/CSV export
// │
// ├── Data/
// │   ├── visa_database.json            // 195+ countries
// │   └── VisaDatabaseLoader.swift      // JSON → Core Data
// │
// └── Resources/
//     ├── Assets.xcassets               // App icons, colors
//     └── Preview Content/
//
// NomadTrackerWidget/
// ├── NomadTrackerWidgetBundle.swift
// ├── CurrentStayWidget.swift           // Active country widget
// ├── YearSummaryWidget.swift          // Annual breakdown widget
// └── WidgetEntry.swift               // Timeline entry
