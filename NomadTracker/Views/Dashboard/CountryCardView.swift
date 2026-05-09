/*
 CountryCardView - Displays visa status for a single country stay
 Uses Stay type from StayStore (plain Swift struct, not CoreData).
 */

import SwiftUI

struct CountryCardView: View {
    let stay: Stay
    
    var countryFlag: String {
        // Convert ISO country code to regional indicator emoji
        let code = stay.countryId.uppercased()
        guard code.count == 2,
              let c1 = code.unicodeScalars.first,
              let c2 = code.unicodeScalars.last else {
            return "🏳️"
        }
        let offset = UInt32(c1.value) - 0x41 + 0x1F1E6
        let offset2 = UInt32(c2.value) - 0x41 + 0x1F1E6
        return String(UnicodeScalar(offset)!) + String(UnicodeScalar(offset2)!)
    }
    
    var daysRemaining: Int {
        stay.daysRemaining
    }
    
    var progress: Double {
        let spent = stay.daysSpent
        let maxDays = stay.maxAllowedDays
        return min(1.0, Double(spent) / Double(maxDays))
    }
    
    var statusColor: Color {
        if daysRemaining <= 3 { return .red }
        if daysRemaining <= 15 { return .orange }
        return .green
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Flag
            Text(countryFlag)
                .font(.system(size: 40))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(stay.countryName)
                    .font(.headline)
                
                Text("\(stay.daysSpent) days spent · \(daysRemaining) remaining")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(stay.visaType.displayName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Progress Ring
            CountdownRingView(
                progress: progress,
                size: 60,
                color: statusColor
            )
            .overlay(
                Text("\(daysRemaining)")
                    .font(.caption2)
                    .fontWeight(.bold)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        CountryCardView(stay: PreviewHelpers.sampleStay)
    }
    .padding()
}

// MARK: - Preview Helpers
enum PreviewHelpers {
    static var sampleStay: Stay {
        Stay(
            id: UUID(),
            countryId: "FR",
            countryName: "France",
            entryDate: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
            exitDate: nil,
            visaType: .tourist,
            notes: nil,
            createdAt: Date()
        )
    }
}
