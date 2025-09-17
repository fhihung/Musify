# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Musify is a Flutter-based music streaming application that provides offline listening support, playlist management, and multi-language support. The app is GPL v3.0 licensed and focused on providing a free, no-ads music experience.

## Essential Commands

### Development and Build
- `flutter run` - Run the app in debug mode
- `flutter build apk` - Build APK for Android
- `flutter build appbundle` - Build Android App Bundle
- `flutter clean` - Clean build cache
- `flutter pub get` - Install dependencies

### Code Quality
- `flutter analyze` - Run static analysis (uses custom rules from analysis_options.yaml)
- `flutter test` - Run all tests
- `dart format .` - Format Dart code

### Version Management
- `./update.sh` - Updates version.dart with current version from pubspec.yaml
- Always run `update.sh` after changing the version in pubspec.yaml

### Database Checking
- `./checkdb.sh` - Runs database checker script (dart scripts/checker.dart > checker.txt)

## Architecture

### Core Structure
- **lib/main.dart** - Main entry point with app initialization and theme management
- **lib/main_fdroid.dart** - F-Droid specific build variant
- **lib/API/musify.dart** - Main API layer for music data and streaming
- **lib/services/** - Core services including audio, settings, data management
- **lib/screens/** - UI screens (home, search, playlist, settings, etc.)
- **lib/widgets/** - Reusable UI components

### Key Services
- **AudioService** (lib/services/audio_service.dart) - Handles music playback with just_audio
- **SettingsManager** (lib/services/settings_manager.dart) - App preferences and configuration
- **DataManager** (lib/services/data_manager.dart) - Data persistence and caching
- **RouterService** (lib/services/router_service.dart) - Navigation management with go_router

### Data Storage
- **Hive boxes**: 'settings', 'user', 'userNoBackup', 'cache' - Local data storage
- **lib/DB/** - Database models for albums and playlists

### Localization
- Supports 22 languages with Flutter's localization system
- Language definitions in `main.dart` with `appLanguages` map
- Localization files in lib/localization/

### Theming
- Dynamic color support (Android 12+) via dynamic_color package
- Custom themes in lib/style/ with accent colors and dark/light modes
- Pure black theme option for OLED displays

## Build Variants
- Regular build (main.dart) - includes update checking
- F-Droid build (main_fdroid.dart) - excludes update functionality

## Important Notes
- The app uses audio_service for background playback
- Custom lint rules are strictly enforced via analysis_options.yaml
- Version updates require running update.sh script
- App links supported for playlist sharing (musify://playlist/custom/)