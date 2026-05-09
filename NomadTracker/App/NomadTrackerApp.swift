/*
 NomadTrackerApp - Entry Point
 iOS 17+ / macOS 14+
 */

import SwiftUI
import WidgetKit

@main
struct NomadTrackerApp: App {
    @StateObject private var alertManager = AlertManager()
    @StateObject private var coreDataStack = CoreDataStack()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.container.viewContext)
                .environmentObject(alertManager)
                .onAppear {
                    // Load visa database on first launch
                    VisaDatabaseLoader.shared.loadIfNeeded(into: coreDataStack.container.viewContext)
                    // Schedule alerts
                    alertManager.scheduleAllAlerts()
                }
        }
        
        // Widget configuration
        WidgetExtension {
            CurrentStayWidget()
            YearSummaryWidget()
        }
    }
}

// MARK: - Widget Extension Target
struct WidgetExtension: Scenes {
    var body: some Scenes {
        Widget {
            CurrentStayWidget()
            YearSummaryWidget()
        }
    }
}
