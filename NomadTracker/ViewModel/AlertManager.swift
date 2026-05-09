/*
 AlertManager - Schedules local notifications for visa deadline alerts
 */

import Foundation
import UserNotifications

class AlertManager: NSObject, ObservableObject {
    @Published var activeAlerts: [VisaAlert] = []
    
    private let thresholds = [30, 15, 7, 3, 1]
    
    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [
                .badge, .sound, .alert
            ])
        } catch {
            print("❌ Alert permission denied: \(error)")
            return false
        }
    }
    
    // MARK: - Schedule Alerts for All Active Stays
    func scheduleAllAlerts() {
        UNUserNotificationCenter.current().delegate = self
        
        // Cancel existing alerts
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule new alerts based on active stays
        // This will be called from the ViewModel with actual stay data
    }
    
    // MARK: - Schedule Alert for Specific Stay
    func scheduleAlert(
        for stayId: String,
        countryName: String,
        daysRemaining: Int,
        threshold: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = "🌍 Nomad Tracker Alert"
        content.body = "\(countryName): \(threshold) days remaining in your visa allowance"
        content.sound = .default
        content.badge = 1
        
        // Calculate trigger date
        let triggerDate = Calendar.current.date(
            byAdding: .day,
            value: threshold,
            to: Date()
        ) ?? Date().addingTimeInterval(86400 * Double(threshold))
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "alert_\(stayId)_\(threshold)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule alert: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AlertManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle tap on notification
        completionHandler()
    }
}

// MARK: - Alert Model
struct VisaAlert: Identifiable {
    let id: UUID
    let stayId: String
    let countryName: String
    let threshold: Int
    let triggered: Bool
    let scheduledDate: Date
    
    var message: String {
        switch threshold {
        case 30: return "🟡 30 days remaining in \(countryName)"
        case 15: return "🟠 15 days remaining in \(countryName)"
        case 7:  return "🔴 7 days — plan exit from \(countryName)"
        case 3:  return "🚨 3 days — urgent: \(countryName)"
        case 1:  return "⚠️ LAST DAY in \(countryName)"
        default: return "\(threshold) days remaining in \(countryName)"
        }
    }
}
