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
        guard let summary = SharedYearSummaryData.loadFromFile() else {
            return YearSummaryWidgetEntry(date: Date(), year: currentYear, countries: [])
        }
        return YearSummaryWidgetEntry(date: Date(), year: summary.year, countries: summary.countries)
    }
}
