/*
 CountryCardView - Displays visa status for a single country stay
 */

import SwiftUI

struct CountryCardView: View {
    let stay: Stay  // Core Data NSManagedObject conforming to Stay protocol
    
    @State private var expanded = false
    
    var body: some View {
        VStack(alignment: leading, spacing: 12) {
            // Header
            HStack {
                // Country flag + name
                HStack(spacing: 12) {
                    Text(countryFlag)
                        .font(.title2)
                    
                    VStack(alignment: leading) {
                        Text(stay.countryName)
                            .font(.headline)
                        
                        Text(stay.visaType.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    statusBadge
                }
                
                // Expand button
                Button {
                    withAnimation { expanded.toggle() }
                } label {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Countdown ring
            CountdownRingView(
                daysSpent: stay.daysSpent,
                daysRemaining: stay.daysRemaining,
                maxDays: stay.maxAllowedDays
            )
            .frame(height: 120)
            
            // Details (expandable)
            if expanded {
                detailsSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
    
    // MARK: - Country Flag Emoji
    private var countryFlag: String {
        let isoCodes = UnicodeScalar(stay.countryId.utf8.map { UnicodeScalar($0 + 0x1F1A5 - 0x41) })
        return String(isoCodes)
    }
    
    // MARK: - Status Badge
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text("\(stay.daysRemaining)d")
                .font(.caption.bold())
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Status Color
    private var statusColor: Color {
        switch stay.daysRemaining {
        case ...3: return .red
        case ...7: return .orange
        case ...15: return .yellow
        default: return .green
        }
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: leading, spacing: 8) {
            LabeledContent("Entry Date", value: stay.entryDate.formatted(date: .long, time: .omitted))
            LabeledContent("Days Spent", value: "\(stay.daysSpent)")
            LabeledContent("Days Remaining", value: "\(stay.daysRemaining)")
            if let notes = stay.notes {
                LabeledContent("Notes", value: notes)
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(.top, 8)
    }
}

// MARK: - Preview
#Preview {
    CountryCardView(stay: MockStay.activeStay)
}
