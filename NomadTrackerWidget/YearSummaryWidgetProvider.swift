/*
 YearSummaryWidgetProvider - Timeline provider for the Year Summary widget.
 Reads year summary data from App Group container.
 */

import WidgetKit
import SwiftUI

struct YearSummaryWidgetProvider: TimelineProvider {

    // MARK: - Placeholder
    func placeholder(in context: Context) -> YearSummaryWidgetEntry {
        YearSummaryWidgetEntry(
            date: Date(),
            year: Calendar.current.component(.year, from: Date()),
            countries: []
        )
    }

    // MARK: - Snapshot
    func getSnapshot(in context: Context, completion: @escaping (YearSummaryWidgetEntry) -> Void) {
        let entry = loadYearSummary()
        completion(entry)
    }

    // MARK: - Timeline
    func getTimeline(in context: Context, completion: @escaping (Timeline<YearSummaryWidgetEntry>) -> Void) {
        let entry = loadYearSummary()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Private

    private func loadYearSummary() -> YearSummaryWidgetEntry {
        let currentYear = Calendar.current.component(.year, from: Date())
        let appGroupDefaults = UserDefaults(suiteName: AppGroup.suiteName)

        guard let defaults = appGroupDefaults,
              let data = defaults.data(forKey: "nomad_year_summary"),
              let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return YearSummaryWidgetEntry(date: Date(), year: currentYear, countries: [])
        }

        let year = dict["year"] as? Int ?? currentYear
        let countriesArray = dict["countries"] as? [[String: Any]] ?? []

        var countries: [SharedCountryYearData] = []
        for item in countriesArray {
            let name = item["countryName"] as? String ?? "Unknown"
            let days = item["daysSpent"] as? Int ?? 0
            countries.append(
                SharedCountryYearData(
                    id: UUID(),
                    countryName: name,
                    countryCode: "",
                    daysSpent: days,
                    maxDays: 90
                )
            )
        }

        return YearSummaryWidgetEntry(date: Date(), year: year, countries: countries)
    }
}
