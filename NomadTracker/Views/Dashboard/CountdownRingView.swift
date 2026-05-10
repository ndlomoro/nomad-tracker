/*
 CountdownRingView - Circular progress indicator for visa days
 */

import SwiftUI

struct CountdownRingView: View {
    let progress: Double
    let size: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.25), lineWidth: 5)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        CountdownRingView(progress: 0.17, size: 80, color: .nomadGreen)
        CountdownRingView(progress: 0.5, size: 80, color: .nomadOrange)
        CountdownRingView(progress: 0.95, size: 80, color: .nomadRed)
    }
    .padding()
}
