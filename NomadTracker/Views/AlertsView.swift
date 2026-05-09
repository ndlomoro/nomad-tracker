/*
 AlertsView - Shows configured visa deadline alerts, their status,
 and allows toggling alert thresholds (30/15/7/3/1 days remaining).
 */

import SwiftUI

struct AlertsView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var stayStore: StayStore
    @EnvironmentObject var alertManager: AlertManager
    
    // MARK: - State
    
    @State private var permissionRequested: Bool = false
    @State private var hasPermission: Bool = false
    @State private var showPermissionAlert: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    notificationPermissionSection
                    
                    if hasPermission {
                        thresholdConfigurationSection
                        activeAlertsSection
                    } else {
                        permissionRequiredNotice
                    }
                }
                .padding()
            }
            .navigationTitle("Alerts")
            
            .background(Color.nomadBackground)
            .onAppear {
                checkNotificationPermission()
            }
        }
    }
    
    // MARK: - Permission Section
    
    private var notificationPermissionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(Color.nomadBlue)
                
                Text("Notifications")
                    .font(.headline)
                
                Spacer()
                
                StatusBadge(
                    text: hasPermission ? "Enabled" : "Off",
                    color: hasPermission ? .green : .gray
                )
            }
            
            if !hasPermission && !permissionRequested {
                Button {
                    requestNotificationPermission()
                } label: {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                        Text("Enable Notifications")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.nomadBlue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
            } else if !hasPermission && permissionRequested {
                Text("Notifications are disabled in Settings. Enable them to receive visa deadline alerts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    // MARK: - Threshold Configuration
    
    private var thresholdConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Color.nomadPurple)
                
                Text("Alert Thresholds")
                    .font(.headline)
                
                Spacer()
            }
            
            Text("Get notified when you have this many days remaining:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 10) {
                ForEach(stayStore.availableThresholds, id: \.self) { threshold in
                    AlertThresholdRow(
                        threshold: threshold,
                        isEnabled: stayStore.alertConfig.thresholds.contains(threshold)
                    ) {
                        stayStore.toggleThreshold(threshold)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    // MARK: - Active Alerts Section
    
    private var activeAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundStyle(Color.nomadOrange)
                
                Text("Active Alerts")
                    .font(.headline)
                
                Spacer()
                
                Text("\(activeAlertCount)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.nomadOrange.opacity(0.15))
                    .cornerRadius(6)
            }
            
            if stayStore.activeStays.isEmpty {
                Text("No active stays to monitor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(stayStore.activeStays) { stay in
                    ActiveAlertCard(
                        stay: stay,
                        stayStore: stayStore,
                        enabledThresholds: stayStore.alertConfig.thresholds
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    // MARK: - Permission Required Notice
    
    private var permissionRequiredNotice: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 50))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("Alerts Disabled")
                .font(.title3.bold())
            
            Text("Enable notifications to receive visa deadline alerts before you overstay.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(40)
    }
    
    // MARK: - Helpers
    
    private var activeAlertCount: Int {
        stayStore.activeStays.count * stayStore.alertConfig.thresholds.count
    }
    
    private func checkNotificationPermission() {
#if os(iOS)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                hasPermission = settings.authorizationStatus == .authorized ||
                               settings.authorizationStatus == .provisional
            }
        }
#else
        hasPermission = true
#endif
    }
    
    private func requestNotificationPermission() {
        permissionRequested = true
        Task {
            let granted = await alertManager.requestPermission()
            hasPermission = granted
            if granted {
                alertManager.scheduleAllAlerts()
            }
        }
    }
}

// MARK: - Alert Threshold Row

struct AlertThresholdRow: View {
    let threshold: Int
    let isEnabled: Bool
    let onToggle: () -> Void
    
    private var icon: String {
        switch threshold {
        case 30: return "🟡"
        case 15: return "🟠"
        case 7: return "🔴"
        case 3: return "🚨"
        case 1: return "⚠️"
        default: return "🔔"
        }
    }
    
    private var description: String {
        switch threshold {
        case 30: return "30 days remaining — plan ahead"
        case 15: return "15 days remaining — start looking"
        case 7: return "7 days remaining — plan exit"
        case 3: return "3 days remaining — urgent"
        case 1: return "Last day — leave today"
        default: return "\(threshold) days remaining"
        }
    }
    
    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(threshold) days")
                        .font(.subheadline.bold())
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(isEnabled))
                    .labelsHidden()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Active Alert Card

struct ActiveAlertCard: View {
    let stay: Stay
    @ObservedObject var stayStore: StayStore
    let enabledThresholds: [Int]
    
    private var status: StayStatus {
        stayStore.stayStatus(for: stay)
    }
    
    private var maxDays: Int {
        stayStore.maxAllowedDays(for: stay.countryId)
    }
    
    private var flagEmoji: String {
        let base: UInt32 = 0x1F1E6
        return String(
            stay.countryId.uppercased().utf16.map {
                Character(UnicodeScalar(base + UInt32($0 - 0x41))!)
            }
        )
    }
    
    private var remainingDays: Int {
        switch status {
        case .safe(let d): return d
        case .active(_, let r): return r
        case .warning(let d): return d
        case .critical(let d): return d
        case .expired(let d): return -d
        }
    }
    
    private var upcomingThresholds: [Int] {
        enabledThresholds.filter { $0 <= remainingDays && $0 > 0 }
            .sorted(by: >)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text(flagEmoji)
                    .font(.title3)
                
                VStack(alignment: .leading) {
                    Text(stay.countryName)
                        .font(.subheadline.bold())
                    
                    Text("Day \(stay.daysSpent) of \(maxDays)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                StatusBadge(
                    text: "\(remainingDays)d left",
                    color: statusColor(for: remainingDays)
                )
            }
            
            // Progress
            ProgressBar(
                progress: Double(stay.daysSpent) / Double(maxDays),
                color: statusColor(for: remainingDays)
            )
            .frame(height: 4)
            
            // Upcoming alerts
            if !upcomingThresholds.isEmpty {
                HStack(spacing: 6) {
                    ForEach(upcomingThresholds, id: \.self) { threshold in
                        AlertChip(threshold: threshold)
                    }
                }
            } else {
                Text("All alert thresholds passed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func statusColor(for days: Int) -> Color {
        switch days {
        case ..<0: return .red
        case ...3: return .red
        case ...7: return .orange
        case ...15: return .yellow
        default: return .green
        }
    }
}

// MARK: - Alert Chip

struct AlertChip: View {
    let threshold: Int
    
    private var color: Color {
        switch threshold {
        case 30: return .yellow
        case 15: return .orange
        case 7: return .red
        case 3: return .red
        case 1: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text("\(threshold)d")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(6)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption.bold())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    AlertsView()
        .environmentObject(StayStore())
        .environmentObject(AlertManager())
}
