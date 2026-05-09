/*
 CurrentStayWidget - Home screen widget showing active stays.
 Uses WidgetProvider for timeline data from App Group shared container.
 */

import WidgetKit
import SwiftUI

extension Color {
    static let nomadBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    static let nomadBackground = Color(red: 0.97, green: 0.97, blue: 0.98)
}


struct CurrentStayWidget: Widget {
    let kind: String = "CurrentStay"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CurrentStayProvider()) { entry in
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

// MARK: - View

struct CurrentStayWidgetEntryView: View {
    let entry: CurrentStayWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
    let stay: SharedStayData
    
    private var progress: Double {
        stay.progress
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
            VStack(alignment: .leading, spacing: 2) {
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
    CurrentStayWidgetEntry(
        date: Date(),
        stays: [
            SharedStayData(
                id: UUID(),
                countryName: "Colombia",
                countryCode: "CO",
                daysSpent: 45,
                daysRemaining: 45,
                maxDays: 90,
                entryDate: Date().addingTimeInterval(-45 * 86400),
                exitDate: nil,
                visaType: "tourist",
                notes: nil
            ),
            SharedStayData(
                id: UUID(),
                countryName: "Spain",
                countryCode: "ES",
                daysSpent: 78,
                daysRemaining: 12,
                maxDays: 90,
                entryDate: Date().addingTimeInterval(-78 * 86400),
                exitDate: nil,
                visaType: "tourist",
                notes: nil
            )
        ],
        summary: "2 active stays"
    )
}
