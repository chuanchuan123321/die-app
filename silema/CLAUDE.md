# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application named "silema". It's currently a basic starter project with Android platform support.

**Tech Stack:**
- Flutter SDK 3.10.7+ (Dart)
- Material Design 3 (Material 3 theming with Colors.deepPurple seed)
- Android platform (iOS not yet added)

## Development Commands

**Install dependencies:**
```bash
flutter pub get
```

**Run the app (requires connected device or emulator):**
```bash
flutter run
```

**Build for Android:**
```bash
flutter build apk                    # Debug APK
flutter build appbundle              # Release bundle for Play Store
```

**Run tests:**
```bash
flutter test                         # Run all tests
flutter test test/widget_test.dart   # Run specific test file
```

**Analyze code:**
```bash
flutter analyze                      # Static analysis using linter rules
```

**Hot Reload:** Press `r` in the terminal or save changes in IDE while app is running. Press `R` for hot restart.

## Project Structure

```
lib/
  main.dart          # App entry point, contains MyApp and MyHomePage widgets
test/
  widget_test.dart   # Widget tests using flutter_test
android/             # Android-specific configuration and build files
```

## Architecture

- **Widget-based**: Follows Flutter's everything-is-a-widget paradigm
- **State Management**: Uses basic `StatefulWidget` with `setState()` for local state
- **Theming**: Material 3 design system with color scheme seeded from `Colors.deepPurple`

## Adding iOS Platform

iOS platform is not yet configured. To add it:
```bash
flutter create --platforms=ios .
```

## Dependencies

Located in `pubspec.yaml`:
- `flutter` (SDK)
- `cupertino_icons: ^1.0.8`
- `flutter_lints: ^6.0.0` (dev, for linting)

To add new dependencies, update `pubspec.yaml` and run `flutter pub get`.
