/*
 CountryCardView - Displays visa status for a single country stay
 Dark mode compatible with proper contrast.
 */

import SwiftUI

struct CountryCardView: View {
    let stay: Stay
    
    var countryFlag: String {
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
        return min(1.0, max(0, Double(spent) / Double(maxDays)))
    }
    
    var statusColor: Color {
        if daysRemaining <= 3 { return .nomadRed }
        if daysRemaining <= 15 { return .nomadOrange }
        return .nomadGreen
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Flag
            Text(countryFlag)
                .font(.system(size: 36))
            
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
                size: 56,
                color: statusColor
            )
            .overlay(
                Text("\(daysRemaining)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.05))
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        CountryCardView(stay: PreviewHelpers.sampleStay)
        CountryCardView(stay: PreviewHelpers.criticalStay)
        CountryCardView(stay: PreviewHelpers.expiredStay)
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
    
    static var criticalStay: Stay {
        Stay(
            id: UUID(),
            countryId: "CO",
            countryName: "Colombia",
            entryDate: Calendar.current.date(byAdding: .day, value: -87, to: Date())!,
            exitDate: nil,
            visaType: .tourist,
            notes: nil,
            createdAt: Date()
        )
    }
    
    static var expiredStay: Stay {
        Stay(
            id: UUID(),
            countryId: "DE",
            countryName: "Germany",
            entryDate: Calendar.current.date(byAdding: .day, value: -95, to: Date())!,
            exitDate: nil,
            visaType: .tourist,
            notes: nil,
            createdAt: Date()
        )
    }
}
