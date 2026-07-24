/*
 Stay Model - Records a stay in a country
 */

import Foundation

struct Stay: Identifiable, Codable {
    let id: UUID
    let countryId: String  // ISO code
    let countryName: String
    let entryDate: Date
    let exitDate: Date?    // nil = still in country
    let visaType: VisaType
    let notes: String?
    let createdAt: Date
    
    // MARK: - Computed
    var isActive: Bool {
        exitDate == nil
    }
    
    var daysSpent: Int {
        Stay.elapsedDays(from: entryDate, to: exitDate ?? Date())
    }

    // MARK: - Static Helpers

    /// Calculate elapsed calendar days between two dates.
    /// Uses start-of-day normalization to avoid fractional-day drift.
    static func elapsedDays(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: start)
        let endOfDay = calendar.startOfDay(for: end)
        let interval = endOfDay.timeIntervalSince(startOfDay)
        return max(0, Int(interval / 86400))
    }

    static func elapsedDays(from start: Date) -> Int {
        elapsedDays(from: start, to: Date())
    }

    
    // Default max allowed days (90). Override via StayStore.maxAllowedDays(for:)
    // for country-specific values.
    var maxAllowedDays: Int {
        90
    }
    
    var daysRemaining: Int {
        max(0, maxAllowedDays - daysSpent)
    }
    
    var displayEnd: String {
        if let exitDate {
            exitDate.formatted(date: .abbreviated, time: .omitted)
        } else {
            "Still here"
        }
    }
}

// MARK: - Visa Type
enum VisaType: String, Codable, CaseIterable {
    case tourist = "tourist"
    case digitalNomad = "digital_nomad"
    case temporaryResident = "temporary_resident"
    case transit = "transit"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .tourist: return "🏖️ Tourist"
        case .digitalNomad: return "💻 Digital Nomad"
        case .temporaryResident: return "🏠 Temporary Resident"
        case .transit: return "✈️ Transit"
        case .other: return "📋 Other"
        }
    }
}

// MARK: - Stay Status
enum StayStatus {
    case safe(daysRemaining: Int)
    case warning(daysRemaining: Int)
    case critical(daysRemaining: Int)
    case expired(daysOver: Int)
    case active(daysSpent: Int, daysRemaining: Int)
    
    var color: String {
        switch self {
        case .safe: return "green"
        case .active: return "green"
        case .warning: return "orange"
        case .critical: return "red"
        case .expired: return "red"
        }
    }
    
    var message: String {
        switch self {
        case .safe(let days):
            return "\(days) days remaining"
        case .active(let spent, let remaining):
            return "Day \(spent) of \(remaining) allowed"
        case .warning(let days):
            return "⚠️ Only \(days) days left"
        case .critical(let days):
            return "🚨 \(days) days — plan exit!"
        case .expired(let days):
            return "❌ Overstayed by \(days) days"
        }
    }
}
