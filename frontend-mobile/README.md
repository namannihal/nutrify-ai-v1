# frontend-mobile (Flutter)

This folder contains a starter Flutter app scaffold to begin replicating the Nutrify-AI web UI and functionality for mobile.

📘 **New to the project?** Check out our [Development Guide](DEVELOPMENT.md) for complete setup and running instructions.

## What's Included
- Minimal Flutter project manifest (`pubspec.yaml`)
- Core app entry (`lib/main.dart`) with navigation and Provider-based auth
- Pages: Landing, Dashboard, Auth, Chat, Nutrition, Fitness
- Basic API service (`lib/services/api.dart`) that mirrors the web frontend endpoints
- Auth provider (`lib/providers/auth_provider.dart`) to manage token and user state
- Simple widgets and navigation drawer

## Development Setup

### Prerequisites
1. Install Flutter:
```bash
brew install flutter  # On macOS
flutter doctor       # Check setup and missing dependencies
```

2. Platform Development Tools:
   - iOS (macOS only):
     ```bash
     brew install cocoapods
     xcode-select --install
     # Install Xcode from App Store
     ```
   - Android:
     - Install Android Studio from https://developer.android.com/studio
     - Install the Flutter and Dart plugins in Android Studio
     - Set up Android SDK in Android Studio

3. Set up Development Device:
   - iOS Simulator: Xcode > Open Developer Tool > Simulator
   - Android Emulator: Android Studio > Device Manager > Create Device
   - Physical Device: Enable USB debugging and connect via USB

### First Run
1. Get Dependencies:
```bash
cd frontend-mobile
flutter pub get
```

2. iOS-specific Setup:
```bash
cd ios
pod install
cd ..
```

3. Run the App:
```bash
flutter run   # Choose a device when prompted
```

## Development Tips
- Hot Reload: Press 'r' to see changes instantly
- Full Restart: Press 'R' when state changes needed
- Help Menu: Press 'h' for all commands
- Quit: Press 'q' to exit

## Configuration
API Base URL (`lib/services/api.dart`):
- iOS Simulator: `http://localhost:8000/api/v1`
- Android Emulator: `http://10.0.2.2:8000/api/v1`
- Physical Device: Use your machine's local network IP

## Development Notes
- State Management: Provider pattern
- Architecture: Mirrors web frontend structure
- Testing: Run tests with `flutter test`
- IDE Support: VS Code or Android Studio recommended
- iOS Builds: Always open Runner.xcworkspace (not .xcodeproj)

## Troubleshooting
1. iOS Build Issues:
   ```bash
   cd ios
   pod install --repo-update
   ```

2. Clean Build:
   ```bash
   flutter clean
   flutter pub get
   ```

3. Reset iOS Simulator:
   - Simulator > Device > Erase All Content and Settings

— agent suggestion — Ayush Ram
