# UV Index Alert

An iOS app that checks the UV index at your location every hour and sends you a notification when it's time to put on sunscreen.

## Features

- Uses your current location to get the real-time UV index
- Sends local push notifications when UV exceeds your threshold
- Background refresh checks every hour automatically
- Adjustable UV threshold (default: 3)
- No accounts, no API keys, completely free — uses the [Open-Meteo API](https://open-meteo.com/)

## Setup

1. Open `UVIndexAlert.xcodeproj` in Xcode
2. Select your team under Signing & Capabilities
3. Build and run on your iPhone

The app will ask for location and notification permissions on first launch.

## How It Works

- **Open-Meteo API** — free weather API, no key needed, provides real-time UV index data
- **CoreLocation** — gets your GPS coordinates
- **BGTaskScheduler** — runs a background refresh approximately every hour
- **Local notifications** — alerts you directly on your phone, no server required

## Requirements

- iOS 17+
- Xcode 15+
