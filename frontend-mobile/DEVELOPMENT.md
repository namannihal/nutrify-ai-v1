# Nutrify Mobile Development Guide

This guide covers setting up your development environment and running the Nutrify mobile app on both iOS and Android platforms.

## Table of Contents
- [Initial Setup](#initial-setup)
  - [Flutter Installation](#flutter-installation)
  - [IDE Setup](#ide-setup)
  - [Project Setup](#project-setup)
- [iOS Development](#ios-development)
  - [Prerequisites](#ios-prerequisites)
  - [Setup Steps](#ios-setup)
  - [Running on iOS](#running-on-ios)
  - [Common iOS Issues](#common-ios-issues)
- [Android Development](#android-development)
  - [Prerequisites](#android-prerequisites)
  - [Setup Steps](#android-setup)
  - [Running on Android](#running-on-android)
  - [Common Android Issues](#common-android-issues)
- [Development Tips](#development-tips)
- [Troubleshooting](#troubleshooting)

## Initial Setup

### Flutter Installation
1. Install Flutter using Homebrew:
   ```bash
   brew install flutter
   ```

2. Verify installation:
   ```bash
   flutter doctor
   ```

3. Follow any additional setup instructions from `flutter doctor` output.

### IDE Setup
Choose one or both:

#### Visual Studio Code
1. Install VS Code from https://code.visualstudio.com
2. Install required extensions:
   - Flutter
   - Dart
   - Flutter Widget Snippets
3. Command Palette (⌘ + Shift + P) > Flutter: Run Flutter Doctor

#### Android Studio
1. Download from https://developer.android.com/studio
2. Install Flutter and Dart plugins:
   - Preferences > Plugins > Search "Flutter" > Install
   - Accept plugin dependencies (Dart)
3. Configure Flutter SDK path in Android Studio

### Project Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/nutrify-me/nutrify-ai-v1.git
   cd nutrify-ai-v1/frontend-mobile
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

## iOS Development

### iOS Prerequisites
- macOS computer (required for iOS development)
- Xcode 15.0 or later
- CocoaPods
- iOS Simulator or physical iOS device
- Apple Developer account (for physical device deployment)

### iOS Setup
1. Install Xcode from Mac App Store

2. Install Command Line Tools:
   ```bash
   xcode-select --install
   ```

3. Install CocoaPods:
   ```bash
   brew install cocoapods
   ```

4. Accept Xcode license:
   ```bash
   sudo xcodebuild -license accept
   ```

5. Set up iOS dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```

### Running on iOS

#### Simulator
1. Open iOS Simulator:
   ```bash
   open -a Simulator
   ```
   Or: Xcode > Open Developer Tool > Simulator

2. Run the app with clean build (recommended):
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. If you encounter build issues, try the following:
   ```bash
   # Clean everything
   flutter clean
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter pub get
   flutter run
   ```

4. For specific simulator:
   ```bash
   # List available simulators
   xcrun simctl list devices
   
   # Run on specific simulator
   flutter run -d <simulator-id>
   ```

#### Physical Device
1. Open ios/Runner.xcworkspace in Xcode
2. Sign in with Apple ID
3. Select your team in Signing & Capabilities
4. Connect iOS device via USB
5. Trust developer on device
6. Select device in Xcode and run

### Common iOS Issues
1. CocoaPods installation fails:
   ```bash
   cd ios
   pod repo update
   pod install --repo-update
   ```

2. Xcode build fails:
   - Clean build folder: Xcode > Product > Clean Build Folder
   - Reset iOS Simulator: Simulator > Device > Erase All Content and Settings
   - Complete cleanup:
     ```bash
     flutter clean
     cd ios
     rm -rf Pods Podfile.lock
     pod install
     cd ..
     flutter pub get
     ```

3. App doesn't uninstall properly:
   ```bash
   # Get simulator ID
   xcrun simctl list devices
   
   # Uninstall app from simulator
   xcrun simctl uninstall <simulator-id> com.example.nutritifyAiV1
   
   # Erase simulator (if needed)
   xcrun simctl erase <simulator-id>
   ```

## Android Development

### Android Prerequisites
- Android Studio
- Android SDK
- Android Emulator or physical Android device
- JDK 11 or later

### Android Setup
1. Install Android Studio:
   ```bash
   brew install --cask android-studio
   ```

2. First-time Android Studio setup:
   - Launch Android Studio
   - Complete setup wizard
   - Install Android SDK
   - Install System Images for emulation

3. Set up Android SDK:
   ```bash
   flutter config --android-sdk /path/to/android/sdk
   ```

4. Accept Android licenses:
   ```bash
   flutter doctor --android-licenses
   ```

### Running on Android

#### Emulator
1. Create an emulator:
   - Android Studio > Tools > Device Manager
   - Create Virtual Device
   - Select device definition (e.g., Pixel 6)
   - Download and select system image (recommend: API 33)
   - Complete AVD creation

2. Start emulator:
   ```bash
   flutter emulators --launch <emulator_id>
   # or start from Android Studio Device Manager
   ```

3. Run app:
   ```bash
   flutter run
   ```

#### Physical Device
1. Enable Developer Options on device:
   - Settings > About Phone
   - Tap Build Number 7 times
   - Enable USB Debugging in Developer Options

2. Connect device via USB

3. Run app:
   ```bash
   flutter run
   ```

### Common Android Issues
1. Gradle sync fails:
   ```bash
   flutter clean
   flutter pub get
   cd android
   ./gradlew clean
   cd ..
   ```

2. SDK location not found:
   - Create local.properties in android/ folder:
     ```properties
     sdk.dir=/Users/YOUR_USER/Library/Android/sdk
     ```

## Development Tips
1. Hot Reload (⌘ + \ or 'r'):
   - Updates UI without losing state
   - Use for most code changes

2. Hot Restart (⌘ + Shift + \ or 'R'):
   - Resets state but faster than full restart
   - Use when Hot Reload insufficient

3. Performance Profile:
   ```bash
   flutter run --profile
   ```

4. Release Build:
   ```bash
   # iOS
   flutter build ios

   # Android
   flutter build apk
   # or
   flutter build appbundle
   ```

## Troubleshooting

### General Issues
1. Clean project:
   ```bash
   flutter clean
   flutter pub get
   ```

2. Verify setup:
   ```bash
   flutter doctor -v
   ```

3. Update Flutter:
   ```bash
   flutter upgrade
   ```

### Platform-Specific
- iOS: Always use .xcworkspace, never .xcodeproj
- Android: Invalidate Caches in Android Studio if sync issues persist

### App Structure

The app follows a clean architecture with the following structure:

```
lib/
├── main.dart          # App entry point and navigation setup
├── models/           # Data models
│   └── user.dart    # User model for authentication
├── pages/           # UI screens
│   ├── landing.dart    # Landing/welcome page
│   ├── dashboard.dart  # Main dashboard with progress tracking
│   ├── nutrition.dart  # Nutrition planning and tracking
│   ├── fitness.dart   # Workout tracking
│   └── chat.dart      # AI coach interface
├── providers/       # State management
│   └── auth_provider.dart  # Authentication state
└── services/        # Backend services
    └── api.dart     # API client for backend communication

### Development Environment
- API URL Configuration:
  ```dart
  // lib/services/api.dart
  // iOS Simulator
  final baseUrl = 'http://localhost:8000/api/v1';
  // Android Emulator
  final baseUrl = 'http://10.0.2.2:8000/api/v1';
  // Physical Device
  final baseUrl = 'http://<your-machine-ip>:8000/api/v1';
  ```

Key Features:
- Material 3 design system implementation
- Provider pattern for state management
- Bottom navigation with IndexedStack for efficient page management
- Shared preferences for persistent authentication
- Gradient-based theming with consistent color scheme

Remember to check the backend is running before starting the app. The default backend URL is configured in `lib/services/api.dart`.