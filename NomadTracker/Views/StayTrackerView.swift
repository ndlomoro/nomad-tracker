/*
 StayTrackerView - Tab view for logging and managing stays.
 Shows active stays with quick end-stay action, and provides access to AddStaySheet.
 */

import SwiftUI

struct StayTrackerView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var stayStore: StayStore
    
    // MARK: - State
    
    @State private var showAddStaySheet: Bool = false
    @State private var stayToEdit: Stay?
    @State private var stayToEnd: Stay?
    @State private var showEndConfirmation: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if stayStore.activeStays.isEmpty {
                    emptyState
                } else {
                    activeStaysList
                }
            }
            .navigationTitle("Track Stays")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddStaySheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.nomadBlue)
                    }
                }
            }
            .sheet(isPresented: $showAddStaySheet) {
                AddStaySheet()
            }
            .sheet(item: $stayToEdit) { stay in
                AddStaySheet(editStay: stay)
            }
            .confirmationDialog(
                "End Stay in \(stayToEnd?.countryName ?? "")?",
                isPresented: $showEndConfirmation,
                titleVisibility: .visible
            ) {
                Button("End Today") {
                    if let stay = stayToEnd {
                        stayStore.endStay(stayId: stay.id, exitDate: Date())
                    }
                    stayToEnd = nil
                }
                
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will mark your stay as ended. You can still view it in History.")
            }
        }
    }
    
    // MARK: - Active Stays List
    
    private var activeStaysList: some View {
        List {
            Section("Active Stays") {
                ForEach(stayStore.activeStays) { stay in
                    activeStayRow(stay)
                }
            }
            
            Section("Quick Add") {
                Button {
                    showAddStaySheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.nomadBlue)
                        Text("Log a New Stay")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Active Stay Row
    
    private func activeStayRow(_ stay: Stay) -> some View {
        let status = stayStore.stayStatus(for: stay)
        let maxDays = stayStore.maxAllowedDays(for: stay.countryId)
        
        return VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text(countryFlagEmoji(for: stay.countryId))
                    .font(.title3)
                
                VStack(alignment: .leading) {
                    Text(stay.countryName)
                        .font(.headline)
                    
                    Text(stay.visaType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Days remaining badge
                daysRemainingBadge(status: status)
            }
            
            // Progress bar
            ProgressBar(
                progress: Double(stay.daysSpent) / Double(maxDays),
                color: statusColor(for: status)
            )
            .frame(height: 6)
            
            // Details
            HStack {
                Label("\(stay.daysSpent) days", systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label(stay.entryDate.formatted(date: .abbreviated, time: .omitted), systemImage: "arrow.right.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Actions
            HStack(spacing: 12) {
                Button {
                    stayToEdit = stay
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.nomadBlue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button {
                    stayToEnd = stay
                    showEndConfirmation = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.checkered")
                        Text("End Stay")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.nomadOrange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Days Remaining Badge
    
    private func daysRemainingBadge(status: StayStatus) -> some View {
        let (days, color) = daysAndColor(for: status)
        
        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text("\(days)d")
                .font(.caption.bold())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func daysAndColor(for status: StayStatus) -> (Int, Color) {
        switch status {
        case .safe(let days):
            return (days, .green)
        case .active(_, let remaining):
            return (remaining, .green)
        case .warning(let days):
            return (days, .orange)
        case .critical(let days):
            return (days, .red)
        case .expired(let days):
            return (-days, .red)
        }
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
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.nomadBlue.opacity(0.6))
            
            Text("No Active Stays")
                .font(.title3.bold())
            
            Text("Log your current stay to start tracking visa days.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showAddStaySheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Your Stay")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.nomadBlue)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private func countryFlagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 0x1F1E6
        return String(
            countryCode.uppercased().utf16.map {
                Character(UnicodeScalar(base + UInt32($0 - 0x41))!)
            }
        )
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .cornerRadius(3)
                
                // Fill
                Rectangle()
                    .fill(color)
                    .cornerRadius(3)
                    .frame(width: min(geo.size.width * max(0, min(progress, 1)), geo.size.width))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StayTrackerView()
        .environmentObject(StayStore())
}
