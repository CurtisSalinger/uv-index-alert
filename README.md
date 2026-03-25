# UV Index Alert

An iOS app that checks the UV index at your location every hour and sends you a notification when it's time to put on sunscreen. Includes a home screen widget.

## Features

- Real-time UV index for your current location
- Push notifications when UV exceeds your threshold
- Background refresh checks every hour
- **Home screen widget** (small & medium sizes) with color-coded UV display
- Adjustable UV threshold slider (default: 3)
- No accounts, no API keys, completely free

## Screenshots

The app shows your current UV index with color-coded levels:
- **Green** (0-2): Low — no protection needed
- **Yellow** (3-5): Moderate — wear sunscreen
- **Orange** (6-7): High — sunscreen is a must
- **Red** (8-10): Very high — avoid the sun
- **Purple** (11+): Extreme — stay inside

## Setup

1. Open `UVIndexAlert.xcodeproj` in Xcode 15+
2. Select your team under **Signing & Capabilities**
3. Build and run on your iPhone (iOS 17+)

The app will ask for **location** and **notification** permissions on first launch.

### Adding the Widget

After installing the app:
1. Long-press your home screen
2. Tap the **+** button (top left)
3. Search for "UV Alert"
4. Choose small or medium size
5. Tap "Add Widget"

## Architecture

| Component | Purpose |
|---|---|
| `ContentView.swift` | Main UI with UV display, threshold slider |
| `LocationManager.swift` | CoreLocation wrapper, shares coords with widget |
| `UVManager.swift` | Fetches UV from Open-Meteo API |
| `NotificationManager.swift` | Local push notifications |
| `UserSettings.swift` | Persists threshold via AppStorage |
| `AppConstants.swift` | Shared App Group keys for app/widget communication |
| `UVIndexAlertWidget.swift` | WidgetKit home screen widget (small + medium) |
| `AppIconView.swift` | Programmatic app icon design |

## How It Works

- **[Open-Meteo API](https://open-meteo.com/)** — free weather API, no key needed
- **CoreLocation** — gets your GPS coordinates
- **BGTaskScheduler** — hourly background refresh
- **App Groups** — shares location/UV data between app and widget
- **WidgetKit** — home screen widget refreshes hourly

## Requirements

- iOS 17+
- Xcode 15+
