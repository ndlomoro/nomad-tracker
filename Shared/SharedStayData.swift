/*
 SharedStayData - Codable struct shared between the main app and widget extension.
 Lives in a shared framework/module so both targets can access it.
 */

import Foundation
import WidgetKit

// MARK: - Shared Stay Data

struct SharedStayData: Identifiable, Codable, Hashable {
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
    
    // MARK: - Computed
    
    var isActive: Bool {
        exitDate == nil
    }
    
    var displayEnd: String {
        if let exitDate {
            exitDate.formatted(date: .abbreviated, time: .omitted)
        } else {
            "Still here"
        }
    }
    
    var progress: Double {
        guard maxDays > 0 else { return 0 }
        return Double(daysSpent) / Double(maxDays)
    }
    
    var statusColor: String {
        switch daysRemaining {
        case ..<0: return "red"
        case ...3: return "red"
        case ...7: return "orange"
        case ...15: return "yellow"
        default: return "green"
        }
    }
}

// MARK: - Current Stay Widget Entry (TimelineEntry)

struct CurrentStayWidgetEntry: TimelineEntry {
    let date: Date
    let stays: [SharedStayData]
    let summary: String
    
    init(date: Date = Date(), stays: [SharedStayData] = [], summary: String = "") {
        self.date = date
        self.stays = stays
        self.summary = summary
    }
}

// MARK: - Year Summary Widget Entry (TimelineEntry)

struct YearSummaryWidgetEntry: TimelineEntry {
    let date: Date
    let year: Int
    let countries: [SharedCountryYearData]
    
    init(date: Date = Date(), year: Int, countries: [SharedCountryYearData] = []) {
        self.date = date
        self.year = year
        self.countries = countries
    }
}

// MARK: - Shared Year Summary Data

struct SharedCountryYearData: Identifiable, Codable, Hashable {
    let id: UUID
    let countryName: String
    let countryCode: String
    let daysSpent: Int
    let maxDays: Int
}

// MARK: - Shared Alert Configuration

struct SharedAlertConfig: Codable, Hashable {
    var enabled: Bool
    var thresholds: [Int]
    var passportCountryCode: String
    var lastExportDate: Date?
    
    static let `default` = SharedAlertConfig(
        enabled: true,
        thresholds: [30, 15, 7, 3, 1],
        passportCountryCode: "US",
        lastExportDate: nil
    )
}

// MARK: - App Group Constants

enum AppGroup {
    static let suiteName = "group.com.andeslabs.nomadtracker"
    
    enum Keys {
        static let stays = "shared_stays_data"
        static let alertConfig = "shared_alert_config"
        static let lastSyncDate = "shared_last_sync_date"
    }
}

// MARK: - Persistence Helpers

extension SharedStayData {
    static func saveToAppGroup(_ stays: [SharedStayData]) {
        let defaults = UserDefaults(suiteName: AppGroup.suiteName)
        guard let defaults else { return }
        do {
            let data = try JSONEncoder().encode(stays)
            defaults.set(data, forKey: AppGroup.Keys.stays)
            defaults.set(Date(), forKey: AppGroup.Keys.lastSyncDate)
        } catch {
            print("❌ Failed to save stays to app group: \(error)")
        }
    }
    
    static func loadFromAppGroup() -> [SharedStayData] {
        let defaults = UserDefaults(suiteName: AppGroup.suiteName)
        guard let defaults,
              let data = defaults.data(forKey: AppGroup.Keys.stays) else {
            return []
        }
        do {
            return try JSONDecoder().decode([SharedStayData].self, from: data)
        } catch {
            print("❌ Failed to load stays from app group: \(error)")
            return []
        }
    }
}

extension SharedAlertConfig {
    func saveToAppGroup() {
        let defaults = UserDefaults(suiteName: AppGroup.suiteName)
        guard let defaults else { return }
        do {
            let data = try JSONEncoder().encode(self)
            defaults.set(data, forKey: AppGroup.Keys.alertConfig)
        } catch {
            print("❌ Failed to save alert config: \(error)")
        }
    }
    
    static func loadFromAppGroup() -> SharedAlertConfig {
        let defaults = UserDefaults(suiteName: AppGroup.suiteName)
        guard let defaults,
              let data = defaults.data(forKey: AppGroup.Keys.alertConfig) else {
            return .default
        }
        do {
            return try JSONDecoder().decode(SharedAlertConfig.self, from: data)
        } catch {
            print("❌ Failed to load alert config: \(error)")
            return .default
        }
    }
}
