# NomadTracker — macOS Local Build & Widget Setup

## Overview

NomadTracker runs on macOS 14+ as a native SwiftUI app with a WidgetKit extension. This spec documents how to build and run the app locally without an Apple Developer Program account.

## Build System

The project uses a hand-written `generate_xcodeproj.py` script (not XcodeGen) to regenerate `NomadTracker.xcodeproj/project.pbxproj` from scratch. Run it after adding or removing Swift source files.

```bash
python3 generate_xcodeproj.py     # regenerate xcodeproj
open NomadTracker.xcodeproj       # open in Xcode
```

> **Note:** `project.yml` is kept for documentation of intent but the actual build uses the generated `.xcodeproj`. Do not rely on `project.yml` being in sync.

## Targets

| Target | SDK | Deployment | Purpose |
|--------|-----|------------|---------|
| NomadTracker | macosx | 14.0 | Main app |
| NomadTrackerWidget | macosx | 14.0 | Desktop widget extension |
| NomadTrackerIntents | macosx | 14.0 | Siri/Shortcuts intents |

## Code Signing (No Developer Account)

Both targets use ad-hoc signing so the app runs locally without an Apple Developer Program membership:

```
CODE_SIGN_IDENTITY = "-"
CODE_SIGNING_REQUIRED = NO
CODE_SIGNING_ALLOWED = YES
```

Neither target has entitlements that require provisioning profiles. App Group entitlements were removed (see Widget Data Sharing below).

## Widget Extension Embedding

The widget `.appex` bundle must be embedded inside the main app bundle so macOS can discover it. The project includes:

- A `PBXCopyFilesBuildPhase` ("Embed App Extensions") on the NomadTracker target with `dstSubfolderSpec = 13` (PlugIns folder)
- A `PBXTargetDependency` from NomadTracker → NomadTrackerWidget so the widget builds first

Final layout on disk:
```
NomadTracker.app/
└── Contents/
    └── PlugIns/
        └── NomadTrackerWidget.appex/
```

## Widget Info.plist

`GENERATE_INFOPLIST_FILE = YES` silently drops `NSExtensionPointIdentifier` on macOS SDK 26.x. A static `NomadTrackerWidget/Info.plist` is provided instead with `GENERATE_INFOPLIST_FILE = NO`. The key entry is:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

## Widget Data Sharing

App Group entitlements (`com.apple.security.application-groups`) require a paid developer account. Data is instead shared via a file written to a directory both the app and widget can access:

```
~/Library/Application Support/com.andeslabs.nomadtracker/
├── shared_stays.json      # Active stays (read by CurrentStayWidget)
└── year_summary.json      # Current-year country breakdown (read by YearSummaryWidget)
```

The `FileStorage` enum in `Shared/SharedStayData.swift` provides the shared directory URL. Both the app and the widget extension read from this path directly — no entitlements required.

`StayStore.syncToAppGroup()` writes both files and calls `WidgetCenter.shared.reloadAllTimelines()` after every mutation.

## WidgetKit Constraints

- `containerBackground(.fill.tertiary, for: .widget)` must wrap widget content instead of `Color(.systemBackground)` (UIKit-only)
- `ScrollView` is not supported inside widget views — use `VStack` with `.prefix(N)` to limit rows
- Widget timeline refreshes every 30 minutes for CurrentStay, 1 hour for YearSummary
