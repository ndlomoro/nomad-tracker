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

// MARK: - File-based shared storage (no App Group entitlement required)

enum FileStorage {
    static var sharedDirectory: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("com.andeslabs.nomadtracker", isDirectory: true)
    }

    static func ensureDirectory() {
        guard let dir = sharedDirectory else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
}

// MARK: - SharedStayData file persistence

extension SharedStayData {
    static func saveToFile(_ stays: [SharedStayData]) {
        FileStorage.ensureDirectory()
        guard let dir = FileStorage.sharedDirectory else { return }
        let url = dir.appendingPathComponent("shared_stays.json")
        guard let data = try? JSONEncoder().encode(stays) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func loadFromFile() -> [SharedStayData] {
        guard let dir = FileStorage.sharedDirectory,
              let data = try? Data(contentsOf: dir.appendingPathComponent("shared_stays.json")),
              let stays = try? JSONDecoder().decode([SharedStayData].self, from: data)
        else { return [] }
        return stays
    }
}

// MARK: - Year summary file persistence

struct SharedYearSummaryData: Codable {
    let year: Int
    let countries: [SharedCountryYearData]

    static func saveToFile(_ data: SharedYearSummaryData) {
        FileStorage.ensureDirectory()
        guard let dir = FileStorage.sharedDirectory else { return }
        let url = dir.appendingPathComponent("year_summary.json")
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: url, options: .atomic)
    }

    static func loadFromFile() -> SharedYearSummaryData? {
        guard let dir = FileStorage.sharedDirectory,
              let data = try? Data(contentsOf: dir.appendingPathComponent("year_summary.json")),
              let summary = try? JSONDecoder().decode(SharedYearSummaryData.self, from: data)
        else { return nil }
        return summary
    }
}
