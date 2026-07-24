/*
 Color Assets - Nomad Tracker Design System
 */

import SwiftUI

// MARK: - Nomad Tracker Colors
extension Color {
    static let nomadBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    static let nomadGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let nomadOrange = Color(red: 0.95, green: 0.6, blue: 0.1)
    static let nomadRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let nomadPurple = Color(red: 0.5, green: 0.3, blue: 0.8)
}

// MARK: - Adaptive System Backgrounds (cross-platform)
extension Color {
    /// Primary content/card background that adapts to light/dark on both iOS and macOS.
    static var appBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }
}

// MARK: - Alert Colors
extension Color {
    static func statusColor(for daysRemaining: Int) -> Color {
        switch daysRemaining {
        case ...3: return .nomadRed
        case ...7: return .nomadOrange
        case ...15: return .yellow
        default: return .nomadGreen
        }
    }
}
