/*
 CurrentStayProvider - Timeline provider for the Current Stay widget.
 Reads SharedStayData from App Group container.
 */

import WidgetKit
import SwiftUI

struct CurrentStayProvider: TimelineProvider {

    // MARK: - Placeholder
    func placeholder(in context: Context) -> CurrentStayWidgetEntry {
        CurrentStayWidgetEntry(
            date: Date(),
            stays: [],
            summary: "Loading..."
        )
    }

    // MARK: - Snapshot
    func getSnapshot(in context: Context, completion: @escaping (CurrentStayWidgetEntry) -> Void) {
        let stays = SharedStayData.loadFromFile()
        let active = stays.filter { $0.isActive }
        completion(
            CurrentStayWidgetEntry(
                date: Date(),
                stays: active,
                summary: active.isEmpty ? "No active stays" : "\(active.count) active"
            )
        )
    }

    // MARK: - Timeline
    func getTimeline(in context: Context, completion: @escaping (Timeline<CurrentStayWidgetEntry>) -> Void) {
        let stays = SharedStayData.loadFromFile()
        let activeStays = stays.filter { $0.isActive }

        let entry = CurrentStayWidgetEntry(
            date: Date(),
            stays: activeStays,
            summary: activeStays.isEmpty ? "No active stays" : "\(activeStays.count) active"
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
