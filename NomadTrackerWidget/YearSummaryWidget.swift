/*
 YearSummaryWidget - Annual breakdown of days spent per country
 */

import WidgetKit
import SwiftUI

struct YearSummaryWidget: Widget {
    let kind: String = "YearSummary"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: YearSummaryProvider()) { entry in
            YearSummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Year Summary")
        .description("Shows your annual breakdown of days spent per country.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Provider
struct YearSummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> YearSummaryEntry {
        YearSummaryEntry(date: Date(), year: Calendar.current.component(.year, from: Date()), countries: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (YearSummaryEntry) -> Void) {
        let entry = YearSummaryEntry(
            date: Date(),
            year: Calendar.current.component(.year, from: Date()),
            countries: []
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<YearSummaryEntry>) -> Void) {
        var entries: [YearSummaryEntry] = []
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let countries = fetchYearSummary(year: currentYear)
        
        let entry = YearSummaryEntry(
            date: Date(),
            year: currentYear,
            countries: countries
        )
        entries.append(entry)
        
        // Update weekly
        let nextUpdate = Calendar.current.date(
            byAdding: .day, value: 7,
            to: Date()
        ) ?? Date().addingTimeInterval(7 * 86400)
        
        completion(Timeline(entries: entries, policy: .after(nextUpdate)))
    }
    
    private func fetchYearSummary(year: Int) -> [YearCountryData] {
        return []
    }
}

// MARK: - Entry
struct YearSummaryEntry: TimelineEntry {
    let date: Date
    let year: Int
    let countries: [YearCountryData]
}

// MARK: - Country Data
struct YearCountryData: Identifiable {
    let id: UUID
    let countryName: String
    let countryCode: String
    let daysSpent: Int
    let maxDays: Int
}

// MARK: - View
struct YearSummaryWidgetEntryView: View {
    let entry: YearSummaryEntry
    
    private var totalDays: Int {
        entry.countries.reduce(0) { $0 + $1.daysSpent }
    }
    
    var body: some View {
        VStack(alignment: leading, spacing: 12) {
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
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(entry.countries) { country in
                            YearCountryRow(country: country)
                        }
                    }
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

// MARK: - Country Row
struct YearCountryRow: View {
    let country: YearCountryData
    
    private var progress: Double {
        Double(country.daysSpent) / Double(country.maxDays)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Country name
            VStack(alignment: leading, spacing: 4) {
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
    YearSummaryEntry(
        date: Date(),
        year: 2025,
        countries: [
            YearCountryData(id: UUID(), countryName: "Colombia", countryCode: "CO", daysSpent: 45, maxDays: 90),
            YearCountryData(id: UUID(), countryName: "Spain", countryCode: "ES", daysSpent: 30, maxDays: 90),
            YearCountryData(id: UUID(), countryName: "Mexico", countryCode: "MX", daysSpent: 20, maxDays: 180),
        ]
    )
}
