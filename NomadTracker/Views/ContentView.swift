/*
 ContentView - Main Tab Navigation
 */

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            StayTrackerView()
                .tabItem {
                    Label("Track", systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)
            
            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color.nomadBlue)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
