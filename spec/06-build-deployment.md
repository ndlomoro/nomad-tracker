# NomadTracker — Build & Deployment

## Project Structure

```
nomad-tracker/
├── Project.yml              # XcodeGen project definition
├── NomadTracker.xcodeproj/  # Generated — do not edit manually
├── NomadTracker/            # Main app target
│   ├── App/                 # App entry point
│   ├── Data/                # Core Data models + persistence
│   ├── Models/              # Swift domain models
│   ├── Resources/           # Colors, visa_database.json
│   ├── ViewModel/           # StayStore, AlertManager, VisaCalculator
│   └── Views/               # SwiftUI views + dashboard components
├── NomadTrackerWidget/      # Widget extension target
├── Shared/                  # Shared code between targets
└── Data/                    # photos_import.json (import data)
```

## Build System

- **XcodeGen** — Project generated from `Project.yml`. Run `xcodegen generate` after config changes.
- **Minimum deployment:** macOS 15.0 / iOS 18.0
- **Build command (macOS):**
  ```
  xcodebuild -project NomadTracker.xcodeproj -scheme NomadTracker \
    -destination 'platform=macOS,arch=arm64' \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO build
  ```

## Targets

| Target | Platform | Purpose |
|--------|----------|---------|
| NomadTracker | macOS + iOS | Main app |
| NomadTrackerWidget | macOS + iOS | Desktop/mobile widgets |
| NomadTrackerIntents | iOS only | App Intents for Siri/Shortcuts |

## Code Signing

- Development: Automatic via Xcode
- Distribution: Ad Hoc / App Store via standard Apple Developer certificates
- Widgets require App Group entitlement: `group.com.andeslabs.nomadtracker`

## Continuous Integration

- GitHub Actions for macOS build verification on every push
- XcodeGen ensures project file consistency across developers
