/*
 NomadTrackerIntents - AppIntents configuration for iOS 17+ widgets
 Provides widget family selection and stay filtering.
 */

import AppIntents
import SwiftUI

// MARK: - Widget Configuration Intent
struct NomadTrackerWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Nomad Tracker Widget Configuration"
    static let description = IntentDescription("Configure which stay information to display on the widget.")

    @Parameter(title: "Widget Style", default: .currentStay)
    var style: WidgetStyle

    @Parameter(title: "Show Notes", default: false)
    var showNotes: Bool
}

// MARK: - Widget Style
enum WidgetStyle: String, Enumerable {
    case currentStay = "current"
    case yearSummary = "summary"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation("Widget Style")

    var displayRepresentation: DisplayRepresentation {
        switch self {
        case .currentStay:
            return DisplayRepresentation(title: "Current Stay")
        case .yearSummary:
            return DisplayRepresentation(title: "Year Summary")
        }
    }

    static var elementDisplayRepresentation: ElementDisplayRepresentation = ElementDisplayRepresentation(
        includedProperties: [.displayRepresentation]
    )

    static var defaultQuery: ElementGroupIntentQuery<WidgetStyle> = WidgetStyleElementGroupQuery()
}

// MARK: - Query for WidgetStyle (renamed to avoid shadowing)
struct WidgetStyleElementGroupQuery: ElementGroupIntentQuery {
    func defaultResult() -> WidgetStyle {
        .currentStay
    }

    func results() -> [WidgetStyle] {
        WidgetStyle.allCases
    }
}

// MARK: - Add Stay Intent
struct AddStayIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a Stay"
    static let description = IntentDescription("Add a new stay to your tracker.")

    @Parameter(title: "Country Name", description: "The country you're visiting")
    var countryName: String

    @Parameter(title: "Entry Date", description: "When did you enter the country?", default: Date.now)
    var entryDate: Date

    @Parameter(title: "Visa Type", default: .tourist)
    var visaType: VisaTypeIntent

    func perform() async -> ShowsAlertResult {
        // In a real app, this would save to the database via AppGroup shared storage
        // For now, just return success
        return .alert("Stay added for \(countryName)")
    }
}

// MARK: - Visa Type for Intents
enum VisaTypeIntent: String, Enumerable {
    case tourist = "tourist"
    case digitalNomad = "digital_nomad"
    case temporaryResident = "temporary_resident"
    case transit = "transit"
    case other = "other"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation("Visa Type")

    var displayRepresentation: DisplayRepresentation {
        switch self {
        case .tourist:
            return DisplayRepresentation(title: "Tourist")
        case .digitalNomad:
            return DisplayRepresentation(title: "Digital Nomad")
        case .temporaryResident:
            return DisplayRepresentation(title: "Temporary Resident")
        case .transit:
            return DisplayRepresentation(title: "Transit")
        case .other:
            return DisplayRepresentation(title: "Other")
        }
    }

    static var elementDisplayRepresentation: ElementDisplayRepresentation = ElementDisplayRepresentation(
        includedProperties: [.displayRepresentation]
    )

    static var defaultQuery: ElementGroupIntentQuery<VisaTypeIntent> = VisaTypeElementGroupQuery()
}

struct VisaTypeElementGroupQuery: ElementGroupIntentQuery {
    func defaultResult() -> VisaTypeIntent {
        .tourist
    }

    func results() -> [VisaTypeIntent] {
        VisaTypeIntent.allCases
    }
}
