/*
 YearSummaryWidget - Annual breakdown of days spent per country.
 Uses WidgetProvider for timeline data from App Group shared container.
 */

import WidgetKit
import SwiftUI


struct YearSummaryWidget: Widget {
    let kind: String = "YearSummary"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: YearSummaryWidgetProvider()) { entry in
            YearSummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Year Summary")
        .description("Shows your annual breakdown of days spent per country.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - View

struct YearSummaryWidgetEntryView: View {
    let entry: YearSummaryWidgetEntry
    
    private var totalDays: Int {
        entry.countries.reduce(0) { $0 + $1.daysSpent }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.nomadBlue)
                
                Text("\(entry.year) Summary")
                    .font(.headline)
                
                Spacer()
                
                Text("\(totalDays) total days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.nomadBlue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Divider()
            
            // Country list
            if entry.countries.isEmpty {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.bar",
                    description: Text("No stays logged this year")
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.countries.prefix(5)) { country in
                        YearCountryRow(country: country)
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Country Row

struct YearCountryRow: View {
    let country: SharedCountryYearData
    
    private var progress: Double {
        country.maxDays > 0 ? Double(country.daysSpent) / Double(country.maxDays) : 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Country name
            VStack(alignment: .leading, spacing: 4) {
                Text(country.countryName)
                    .font(.subheadline.bold())
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(Color.nomadBlue)
                            .frame(width: geo.size.width * min(progress, 1.0), height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            Spacer()
            
            // Days
            Text("\(country.daysSpent)/\(country.maxDays)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    YearSummaryWidget()
} timeline: {
    YearSummaryWidgetEntry(
        date: Date(),
        year: 2025,
        countries: [
            SharedCountryYearData(id: UUID(), countryName: "Colombia", countryCode: "CO", daysSpent: 45, maxDays: 90),
            SharedCountryYearData(id: UUID(), countryName: "Spain", countryCode: "ES", daysSpent: 30, maxDays: 90),
            SharedCountryYearData(id: UUID(), countryName: "Mexico", countryCode: "MX", daysSpent: 20, maxDays: 180),
        ]
    )
}
