/*
 CountdownRingView - Circular progress indicator for visa countdown
 */

import SwiftUI

struct CountdownRingView: View {
    let progress: Double
    let daysRemaining: Int
    let maxDays: Int
    let color: Color
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Center text
            VStack(spacing: 2) {
                Text("\(daysRemaining)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                Text("days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 80, height: 80)
    }
}

#Preview {
    VStack(spacing: 20) {
        CountdownRingView(
            progress: 0.5,
            daysRemaining: 45,
            maxDays: 90,
            color: .nomadGreen
        )
        CountdownRingView(
            progress: 0.8,
            daysRemaining: 18,
            maxDays: 90,
            color: .nomadOrange
        )
        CountdownRingView(
            progress: 0.95,
            daysRemaining: 4,
            maxDays: 90,
            color: .nomadRed
        )
    }
}
