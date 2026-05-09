/*
 Country Model - Represents a country with visa rules
 */

import Foundation

struct Country: Identifiable, Codable, Hashable {
    let id: String  // ISO 3166-1 alpha-2
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
    
    // MARK: - Computed
    var totalMaxDays: Int {
        defaultStayDays + maxExtensionDays
    }
    
    var displayName: String {
        "\(name) (\(id))"
    }
    
    // MARK: - Rule Types
    enum RuleType: String, Codable {
        case calendarYear = "calendar_year"
        case rolling90_180 = "rolling_90_180"
        case rollingWindow = "rolling_window"
        
        var description: String {
            switch self {
            case .calendarYear: return "Calendar Year"
            case .rolling90_180: return "90/180 Rolling Window"
            case .rollingWindow: return "Custom Rolling Window"
            }
        }
    }
    
    // MARK: - Digital Nomad Visa
    struct DigitalNomadVisa: Codable, Hashable {
        let available: Bool
        let durationDays: Int?
        let renewable: Bool?
        let name: String?
    }
}

// MARK: - Coding from JSON
extension Country {
    init?(from dict: [String: Any]) {
        guard let code = dict["code"] as? String,
              let name = dict["name"] as? String else { return nil }
        
        self.id = code
        self.name = name
        self.region = dict["region"] as? String ?? "Unknown"
        self.defaultStayDays = dict["default_stay_days"] as? Int ?? 90
        self.maxExtensionDays = dict["max_extension_days"] as? Int ?? 0
        self.ruleType = Self.parseRuleType(dict["rule_type"] as? String)
        self.multipleEntry = dict["multiple_entry"] as? Bool ?? true
        self.visaRequired = dict["visa_required"] as? Bool ?? false
        self.visaType = dict["visa_type"] as? String
        self.isSchengen = dict["schengen"] as? Bool ?? false
        self.digitalNomadVisa = Self.parseDNV(dict["digital_nomad_visa"] as? [String: Any])
        self.notes = dict["notes"] as? String
    }
    
    private static func parseRuleType(_ value: String?) -> RuleType {
        switch value {
        case "rolling_90_180": return .rolling90_180
        case "rolling_window": return .rollingWindow
        default: return .calendarYear
        }
    }
    
    private static func parseDNV(_ dict: [String: Any]?) -> DigitalNomadVisa? {
        guard let dict = dict, let available = dict["available"] as? Bool else { return nil }
        return DigitalNomadVisa(
            available: available,
            durationDays: dict["duration_days"] as? Int,
            renewable: dict["renewable"] as? Bool,
            name: dict["name"] as? String
        )
    }
}
