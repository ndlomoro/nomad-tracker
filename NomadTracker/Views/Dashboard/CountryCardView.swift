/*
 CountryCardView - Displays an active stay with countdown ring
 Features: tap feedback, haptic feedback, smooth animations, status indicators
 */

import SwiftUI

struct CountryCardView: View {
    let stay: Stay
    
    @EnvironmentObject var stayStore: StayStore
    @State private var isPressed = false
    @State private var showDetail = false
    
    private var status: StayStatus {
        stayStore.stayStatus(for: stay)
    }
    
    private var country: Country? {
        stayStore.availableCountries.first { $0.id == stay.countryId }
    }
    
    private var progress: Double {
        let maxD = country?.totalMaxDays ?? stay.maxAllowedDays
        return min(1.0, Double(stay.daysSpent) / Double(maxD))
    }
    
    private var ringColor: Color {
        switch status {
        case .safe, .active: return .nomadGreen
        case .warning: return .nomadOrange
        case .critical, .expired: return .nomadRed
        }
    }
    
    private var flagEmoji: String {
        country?.flagEmoji ?? ""
    }
    
    var body: some View {
        Button(action: {
            #if os(iOS)
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif

            // Navigate to detail
            showDetail = true
        }) {
            HStack(spacing: 16) {
                // Countdown Ring
                CountdownRingView(
                    progress: progress,
                    daysRemaining: stay.daysRemaining,
                    maxDays: country?.totalMaxDays ?? stay.maxAllowedDays,
                    color: ringColor
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(flagEmoji)
                            .font(.title2)
                        Text(stay.countryName)
                            .font(.headline)
                        if stay.isActive {
                            Text("Active")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.nomadGreen.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(status.message)
                        .font(.subheadline)
                        .foregroundStyle(ringColor)
                        .fontWeight(.medium)
                    
                    Text("Entered \(stay.entryDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let notes = stay.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appBackground)
                    .shadow(
                        color: ringColor.opacity(isPressed ? 0.15 : 0.08),
                        radius: isPressed ? 12 : 8,
                        x: 0,
                        y: isPressed ? 4 : 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .sheet(isPresented: $showDetail) {
            if let country {
                CountryDetailView(country: country, stayStore: stayStore)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CountryCardView(stay: Stay(
            id: UUID(),
            countryId: "MX",
            countryName: "Mexico",
            entryDate: Date().addingTimeInterval(-86400 * 45),
            exitDate: nil,
            visaType: .tourist,
            notes: "Working remotely from Playa del Carmen",
            createdAt: Date()
        ))
        
        CountryCardView(stay: Stay(
            id: UUID(),
            countryId: "ES",
            countryName: "Spain",
            entryDate: Date().addingTimeInterval(-86400 * 75),
            exitDate: nil,
            visaType: .tourist,
            notes: nil,
            createdAt: Date()
        ))
    }
    .environmentObject(StayStore())
    .padding()
}
