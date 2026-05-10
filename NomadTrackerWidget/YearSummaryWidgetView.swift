/*
 YearSummaryWidgetView - Widget showing yearly stay summary
 Uses SharedStayData and SharedYearSummaryEntry from App Group.
 */

import WidgetKit
import SwiftUI

struct YearSummaryWidgetView: View {
    var entry: YearSummaryWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📊 Year Summary")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(entry.year)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if entry.countries.isEmpty {
                HStack {
                    Spacer()
                    Text("No stays recorded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.countries.prefix(4), id: \.countryName) { country in
                        HStack {
                            Text(country.countryName)
                                .font(.caption2)
                                .lineLimit(1)
                            Spacer()
                            Text("\(country.daysSpent)d")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            HStack {
                Text("Total: \(entry.countries.reduce(0) { $0 + $1.daysSpent }) days")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

#Preview(as: .systemSmall) {
    YearSummaryWidget()
} timeline: {
    YearSummaryWidgetEntry(
        date: Date(),
        year: Calendar.current.component(.year, from: Date()),
        countries: [
            SharedCountryYearData(id: UUID(), countryName: "France", countryCode: "FR", daysSpent: 15, maxDays: 90),
            SharedCountryYearData(id: UUID(), countryName: "Spain", countryCode: "ES", daysSpent: 30, maxDays: 90),
        ]
    )
}
