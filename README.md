# 🌍 Nomad Tracker

> Track your days in every country. Never overstay a visa again.

Built for digital nomads who need to track days spent per country per year to avoid visa overstays. Features a home screen widget, real-time countdown alerts, and a comprehensive visa database covering 195+ countries.

## Features

- **📊 Country Day Tracker** — Log entry/exit dates, auto-calculate days remaining
- **⏰ Smart Alerts** — Get notified 30/15/7/3 days before visa deadline
- **🗺️ Home Screen Widget** — See your current status at a glance
- **📋 Visa Database** — 195+ countries with tourist stay limits
- **🔄 Rolling Window** — Handles 90/180 rules (Schengen), rolling periods, and calendar-year limits
- **📤 Export** — Download your travel history for immigration purposes

## Tech Stack

- iOS/macOS app with WidgetKit
- Swift/SwiftUI
- Core Data for local storage
- NotificationCenter for alerts

## Getting Started

```bash
cd nomad-tracker
open NomadTracker.xcodeproj
```

## Visa Database

Comprehensive stay-limit data in `Data/visa_database.json` covering:
- Tourist visa-free allowances
- Digital nomad visa durations
- Rolling vs. calendar-year rules
- Visa-on-arrival countries
- Multiple-entry allowances

## License

MIT
