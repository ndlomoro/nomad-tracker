# NomadTracker — Alert & Notification System

## Overview

The alert system monitors active stays and triggers native notifications when visa limits approach configurable thresholds.

## AlertManager

```swift
@MainActor
class AlertManager: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var enabled: Bool = true
}
```

## NotificationItem

```swift
struct NotificationItem: Identifiable, Codable {
    let id: UUID
    let stayId: UUID
    let title: String
    let body: String
    let type: NotificationType
    let createdAt: Date
    let read: Bool
}
```

## Notification Types

| Type | Trigger | Example |
|------|---------|---------|
| `info` | Stay added | "Stay in Germany started" |
| `warning` | 30/15 days remaining | "15 days left in Spain" |
| `critical` | 7/3/1 days remaining | "3 days left — plan exit!" |
| `expired` | Over limit | "Overstayed Thailand by 5 days" |

## Thresholds

Configurable in `AlertsView`. Defaults: `[30, 15, 7, 3, 1]` days.

- Stored in `UserDefaults` under `nomad_alert_config`
- Toggling a threshold enables/disables alerts at that level
- Changes persist across app restarts

## Monitoring Cycle

1. `AlertManager` observes `StayStore.activeStays` via Combine
2. On change, runs `VisaCalculator.calculateRemainingDays` for each active stay
3. Compares result against enabled thresholds
4. If threshold crossed, creates `NotificationItem` and triggers native notification
5. Deduplication: same threshold + same stay = no repeat notification

## Native Notifications

- Uses macOS `UserNotifications` framework
- Request permission on first launch
- Badge count reflects unread notifications
- Tap notification → opens AlertsView tab
