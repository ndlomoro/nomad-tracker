/*
 NomadTracker - App Entry Point
 */

import SwiftUI
import CoreData

@main
struct NomadTrackerApp: App {
    @StateObject private var stayStore = StayStore()
    @StateObject private var alertManager = AlertManager()
    
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stayStore)
                .environmentObject(alertManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task {
                    // Request notification permission on launch
                    _ = await alertManager.requestPermission()
                }
        }
    }
}
