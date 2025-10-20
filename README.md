# Mr Sleep

Sleep cycle calculator and AlarmKit companion built for iOS 26 so you can fall asleep on time and wake up refreshed.

[Download on the App Store](https://apps.apple.com/us/app/mr-sleep-sleep-calculator/id6751219678)

<img width="1320" height="2868" alt="Simulator Screenshot - iPhone 17 Pro Max - 2025-10-01 at 22 59 16" src="https://github.com/user-attachments/assets/5f448b37-8d69-461b-8347-dddea624834f" />

## Highlights
- Calculates optimal wake-up targets using 90-minute cycles plus a 15-minute fall-asleep buffer
- One-tap quick naps, custom alarms, and shortcuts powered by AlarmKit
- Built-in Sleep Guide with approachable tips and accessible design

## Requirements
- Xcode 26 or newer with the iOS 26 SDK
- iPhone or iPad running iOS 26 or later
- Apple developer account to enable AlarmKit entitlements on device

## Build & Run
1. Clone the repo and open `Mr Sleep.xcodeproj` in Xcode 26+
2. Select the `Mr Sleep` scheme and target an iOS 26 simulator or device
3. Confirm the AlarmKit capability is present in Signing & Capabilities
4. Build and run (`⌘R`) to explore wake-up plans, quick naps, and the Sleep Guide

## Project Structure
- `Mr Sleep/App` – App entry point and lazy AlarmKit container
- `Mr Sleep/Models` – Sleep cycle math, persistence, and intent metadata
- `Mr Sleep/Views` – SwiftUI screens for calculations, alarms, and guidance

## Contributing
Issues and pull requests are welcome—please keep them focused and describe the change clearly.

## License
Copyright © 2025 Magdoub. All rights reserved.
