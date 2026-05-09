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
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    CountdownRingView(progress: 0.33, size: 80, color: .green)
}
