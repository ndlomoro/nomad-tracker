/*
 CountdownRingView - Circular progress indicator for visa days remaining
 */

import SwiftUI

struct CountdownRingView: View {
    let daysSpent: Int
    let daysRemaining: Int
    let maxDays: Int
    
    private var progress: Double {
        Double(daysSpent) / Double(maxDays)
    }
    
    private var ringColor: Color {
        switch daysRemaining {
        case ...3: return .red
        case ...7: return .orange
        case ...15: return .yellow
        default: return .green
        }
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 100, height: 100)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: 12,
                        lineCap: .round
                    )
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Center text
            VStack(spacing: 2) {
                Text("\(daysRemaining)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(ringColor)
                
                Text("days left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 120)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        CountdownRingView(daysSpent: 10, daysRemaining: 80, maxDays: 90)
        CountdownRingView(daysSpent: 75, daysRemaining: 15, maxDays: 90)
        CountdownRingView(daysSpent: 87, daysRemaining: 3, maxDays: 90)
    }
}
