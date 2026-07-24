/*
 NomadTracker - App Entry Point
 */

import SwiftUI
import CoreData

@main
struct NomadTrackerApp: App {
    @StateObject private var stayStore = StayStore()
    @StateObject private var alertManager = AlertManager()
    @State private var showOnboarding = false
    
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingView()
                } else {
                    ContentView()
                }
            }
            .environmentObject(stayStore)
            .environmentObject(alertManager)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .task {
                // Check if first launch
                showOnboarding = !UserDefaults.standard.bool(forKey: "has_completed_onboarding")
                
                // Request notification permission on launch
                let granted = await alertManager.requestPermission()
                
                // Sync database to shared file storage for widgets
                stayStore.syncToAppGroup()
                
                // Initialize alerts from active stays if permission granted
                if granted {
                    alertManager.scheduleAllAlerts(for: stayStore.activeStays)
                }
            }
        }
    }
}
