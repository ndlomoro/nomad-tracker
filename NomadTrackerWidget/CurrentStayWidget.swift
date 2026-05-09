/*
 CurrentStayWidget - Home screen widget showing active stays
 */

import WidgetKit
import SwiftUI

struct CurrentStayWidget: Widget {
    let kind: String = "CurrentStay"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CurrentStayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Current Stay")
        .description("Shows your active country stay and days remaining.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
}

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), stays: [], summary: "Loading...")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = WidgetEntry(date: Date(), stays: [], summary: "Snapshot")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        var entries: [WidgetEntry] = []
        
        // Fetch from Core Data via App Group
        let stays = fetchActiveStays()
        let summary = generateSummary(stays: stays)
        
        let entry = WidgetEntry(date: Date(), stays: stays, summary: summary)
        entries.append(entry)
        
        // Next update at midnight
        let nextMidnight = Calendar.current.date(
            byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date().addingTimeInterval(86400)
        
        let timeline = Timeline(
            entries: entries,
            policy: .after(nextMidnight)
        )
        completion(timeline)
    }
    
    private func fetchActiveStays() -> [WidgetStayData] {
        // Fetch from Core Data shared container
        return []
    }
    
    private func generateSummary(stays: [WidgetStayData]) -> String {
        guard !stays.isEmpty else { return "No active stays" }
        return "\(stays.count) active stay\(stays.count > 1 ? "s" : "")"
    }
}

// MARK: - Entry
struct WidgetEntry: TimelineEntry {
    let date: Date
    let stays: [WidgetStayData]
    let summary: String
}

// MARK: - Widget Stay Data
struct WidgetStayData: Identifiable {
    let id: UUID
    let countryName: String
    let countryCode: String
    let daysSpent: Int
    let daysRemaining: Int
    let maxDays: Int
}

// MARK: - View
struct CurrentStayWidgetEntryView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(alignment: leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "globe.americas.fill")
                    .foregroundStyle(Color.nomadBlue)
                
                Text("Nomad Tracker")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(entry.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Active stays
            if entry.stays.isEmpty {
                ContentUnavailableView(
                    "No Active Stays",
                    systemImage: "map.pin.slash",
                    description: Text("Log a stay to start tracking")
                )
            } else {
                ForEach(entry.stays.prefix(3)) { stay in
                    WidgetStayRow(stay: stay)
                }
            }
        }
        .padding()
        .background {
            Rectangle()
                .fill(Color(.systemBackground))
                .cornerRadius(16)
        }
    }
}

// MARK: - Stay Row
struct WidgetStayRow: View {
    let stay: WidgetStayData
    
    private var progress: Double {
        Double(stay.daysSpent) / Double(stay.maxDays)
    }
    
    private var statusColor: Color {
        switch stay.daysRemaining {
        case ...3: return .red
        case ...7: return .orange
        case ...15: return .yellow
        default: return .green
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress indicator
            Circle()
                .stroke(statusColor.opacity(0.3), lineWidth: 4)
                .overlay {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            statusColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 36, height: 36)
                .overlay {
                    Text("\(stay.daysRemaining)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(statusColor)
                }
            
            // Country info
            VStack(alignment: leading, spacing: 2) {
                Text(stay.countryName)
                    .font(.subheadline.bold())
                
                Text("Day \(stay.daysSpent) of \(stay.maxDays)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    CurrentStayWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        stays: [
            WidgetStayData(
                id: UUID(),
                countryName: "Colombia",
                countryCode: "CO",
                daysSpent: 45,
                daysRemaining: 45,
                maxDays: 90
            ),
            WidgetStayData(
                id: UUID(),
                countryName: "Spain",
                countryCode: "ES",
                daysSpent: 78,
                daysRemaining: 12,
                maxDays: 90
            )
        ],
        summary: "2 active stays"
    )
}
