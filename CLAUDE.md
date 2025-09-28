# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application named "photo_view" - a standard Flutter project setup with cross-platform support for Android, iOS, macOS, Linux, Windows, and web.

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the application on connected device/simulator
- `flutter run -d chrome` - Run on web browser
- `flutter run -d android` - Run on Android device/emulator
- `flutter run -d ios` - Run on iOS simulator (macOS only)
- `flutter hot-reload` or press `r` in terminal - Hot reload changes
- `flutter hot-restart` or press `R` in terminal - Hot restart application

### Build Commands
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app (macOS only)
- `flutter build web` - Build web application
- `flutter build windows` - Build Windows application
- `flutter build macos` - Build macOS application (macOS only)
- `flutter build linux` - Build Linux application

### Testing and Analysis
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run specific test file
- `flutter analyze` - Run static analysis (uses analysis_options.yaml)

### Package Management
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter pub outdated` - Check for outdated packages

## Code Architecture

### Project Structure
- `lib/main.dart` - Main application entry point with MaterialApp setup
- `test/widget_test.dart` - Basic widget tests for the counter functionality
- Platform-specific directories: `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`

### Current Implementation
The application is a standard Flutter counter demo app with:
- `MyApp` - Root MaterialApp widget with Material Design theme
- `MyHomePage` - StatefulWidget implementing a counter with increment functionality
- Material Design with deep purple color scheme
- Standard Flutter app structure with AppBar, body, and FloatingActionButton

### Dependencies
- `flutter` - Core Flutter SDK
- `cupertino_icons` - iOS-style icons
- `flutter_lints` - Recommended linting rules (dev dependency)
- `flutter_test` - Testing framework (dev dependency)

## Development Notes

### Code Style
- Uses `flutter_lints` package with standard Flutter linting rules
- Analysis configuration in `analysis_options.yaml`
- Follows standard Flutter/Dart conventions

### Testing
- Widget tests are set up in `test/` directory
- Run tests with `flutter test`
- Basic counter functionality test included

### Platform Support
All major platforms supported with platform-specific configuration directories.