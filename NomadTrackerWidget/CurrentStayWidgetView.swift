/*
 CurrentStayWidgetView - Widget showing the current active stay
 Uses SharedStayData from App Group.
 */

import WidgetKit
import SwiftUI

struct CurrentStayWidgetView: View {
    var entry: SharedStayData
    
    var progress: Double {
        guard entry.maxDays > 0 else { return 0 }
        return min(1.0, Double(entry.daysSpent) / Double(entry.maxDays))
    }
    
    var statusColor: Color {
        if entry.daysRemaining <= 3 { return .red }
        if entry.daysRemaining <= 15 { return .orange }
        return .green
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🌍 Nomad Tracker")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if entry.isActive {
                    Text("Active")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            
            HStack(alignment: .top, spacing: 12) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(statusColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(entry.daysRemaining)")
                            .font(.system(.caption, design: .rounded).bold())
                        Text("days left")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 60, height: 60)
                
                // Stay info
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.countryName)
                        .font(.headline)
                    
                    Text("\(entry.daysSpent) / \(entry.maxDays) days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(entry.visaType.capitalized)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

#Preview(as: .systemSmall) {
    CurrentStayWidget()
} timeline: {
    CurrentStayWidgetEntry(
        date: Date(),
        stays: [
            SharedStayData(
                id: UUID(),
                countryName: "France",
                countryCode: "FR",
                daysSpent: 15,
                daysRemaining: 75,
                maxDays: 90,
                entryDate: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
                exitDate: nil,
                visaType: "tourist",
                notes: "Working remotely"
            )
        ],
        summary: "1 active stay"
    )
}
