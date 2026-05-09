/*
 HistoryView - Shows past stays grouped by year with expandable summary cards.
 Each year shows total days per country; tap to expand individual stays.
 */

import SwiftUI

struct HistoryView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var stayStore: StayStore
    
    // MARK: - State
    
    @State private var expandedYears: Set<Int> = []
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if stayStore.allStays.isEmpty {
                    emptyState
                } else {
                    yearPickerAndList
                }
            }
            .navigationTitle("History")
            
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Picker("Year", selection: $selectedYear) {
                        ForEach(availableYears.reversed(), id: \.self) { year in
                            Text("\(year)")
                                .tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
    
    // MARK: - Year Picker & List
    
    private var yearPickerAndList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Year summary card
                yearSummaryCard
                
                // Stays for selected year
                staysForSelectedYear
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color.nomadBackground)
    }
    
    // MARK: - Year Summary Card
    
    private var yearSummaryCard: some View {
        let summary = stayStore.yearSummary(year: selectedYear)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.nomadBlue)
                
                Text("\(selectedYear) Summary")
                    .font(.headline)
                
                Spacer()
                
                Text("\(summary.totalDays) days total")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.nomadBlue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if summary.countryDays.isEmpty {
                Text("No stays recorded this year")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(summary.countryDays.sorted(by: { $0.key < $1.key })), id: \.key) { countryName, days in
                    CountrySummaryRow(countryName: countryName, days: days, year: selectedYear)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    // MARK: - Stays for Selected Year
    
    private var staysForSelectedYear: some View {
        let stays = staysInYear(selectedYear)
        
        return Group {
            if stays.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stays in \(selectedYear)")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    ForEach(stays) { stay in
                        StayHistoryRow(stay: stay, stayStore: stayStore)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
            }
        }
    }
    
    // MARK: - All Years View (when no year selected)
    
    private var allYearsView: some View {
        let summaries = stayStore.allYearSummaries()
        
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(summaries) { summary in
                YearGroupCard(
                    summary: summary,
                    isExpanded: expandedYears.contains(summary.year),
                    stays: staysInYear(summary.year)
                ) { year in
                    withAnimation {
                        if expandedYears.contains(year) {
                            expandedYears.remove(year)
                        } else {
                            expandedYears.insert(year)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("No History Yet")
                .font(.title3.bold())
            
            Text("Your past stays will appear here once you log and end them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private var availableYears: [Int] {
        let years = stayStore.allStays.map {
            Calendar.current.component(.year, from: $0.entryDate)
        }
        let currentYear = Calendar.current.component(.year, from: Date())
        let allYears = years + [currentYear]
        return Array(Set(allYears)).sorted()
    }
    
    private func staysInYear(_ year: Int) -> [Stay] {
        let calendar = Calendar.current
        return stayStore.allStays.filter { stay in
            let entryYear = calendar.component(.year, from: stay.entryDate)
            let exitDate = stay.exitDate ?? Date()
            let exitYear = calendar.component(.year, from: exitDate)
            return entryYear == year || exitYear == year || (entryYear < year && exitYear > year)
        }.sorted { $0.entryDate > $1.entryDate }
    }
}

// MARK: - Country Summary Row

struct CountrySummaryRow: View {
    let countryName: String
    let days: Int
    let year: Int
    
    private var flagEmoji: String {
        // Try to find the country code from the name (simplified)
        let code = countryName.prefix(2).uppercased()
        let base: UInt32 = 0x1F1E6
        return String(
            code.utf16.map {
                Character(UnicodeScalar(base + UInt32($0 - 0x41)) ?? UnicodeScalar(0x2753)!)
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(flagEmoji)
                .font(.title3)
            
            Text(countryName)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(days) days")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stay History Row

struct StayHistoryRow: View {
    let stay: Stay
    @ObservedObject var stayStore: StayStore
    
    @State private var expanded: Bool = false
    
    private var status: StayStatus {
        stayStore.stayStatus(for: stay)
    }
    
    private var maxDays: Int {
        stayStore.maxAllowedDays(for: stay.countryId)
    }
    
    private var flagEmoji: String {
        let base: UInt32 = 0x1F1E6
        return String(
            stay.countryId.uppercased().utf16.map {
                Character(UnicodeScalar(base + UInt32($0 - 0x41))!)
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(flagEmoji)
                    .font(.title3)
                
                VStack(alignment: .leading) {
                    Text(stay.countryName)
                        .font(.subheadline.bold())
                    
                    Text(stay.visaType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stay.daysSpent) days")
                        .font(.caption.bold())
                    
                    Text(stay.displayEnd)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    withAnimation { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress
            ProgressBar(
                progress: Double(stay.daysSpent) / Double(maxDays),
                color: statusColor(for: status)
            )
            .frame(height: 4)
            
            // Details (expandable)
            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    LabeledContent("Entry", value: stay.entryDate.formatted(date: .long, time: .omitted))
                    LabeledContent("Exit", value: stay.displayEnd)
                    LabeledContent("Days", value: "\(stay.daysSpent) of \(maxDays)")
                    
                    if let notes = stay.notes {
                        LabeledContent("Notes", value: notes)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(for status: StayStatus) -> Color {
        switch status {
        case .safe: return .green
        case .active: return .green
        case .warning: return .orange
        case .critical: return .red
        case .expired: return .red
        }
    }
}

// MARK: - Year Group Card (for all-years view)

struct YearGroupCard: View {
    let summary: StayStore.YearSummary
    let isExpanded: Bool
    let stays: [Stay]
    let onToggle: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                onToggle(summary.year)
            } label: {
                HStack {
                    Text("\(summary.year)")
                        .font(.headline)
                    
                    Text("\(summary.totalDays) days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(stays.count) stay\(stays.count != 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            // Country breakdown
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(summary.countryDays.sorted(by: { $0.value > $1.value })), id: \.key) { countryName, days in
                        HStack {
                            Text(countryName)
                                .font(.subheadline)
                            Spacer()
                            Text("\(days) days")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Individual stays
                    ForEach(stays) { stay in
                        StayHistoryRow(stay: stay, stayStore: StayStore())
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .environmentObject(StayStore())
}
