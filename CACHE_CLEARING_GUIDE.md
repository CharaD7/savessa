# Flutter App Cache Clearing Guide

## Overview

This document provides instructions on how to restart a Flutter app with an empty cache. Clearing the cache can help resolve various issues like stale data, outdated configurations, or unexpected behaviors.

## Steps to Clear Cache and Restart the App

### 1. Clear Flutter Build Cache

The first step is to clear the Flutter build cache using the `flutter clean` command:

```bash
flutter clean
```

This command deletes the following directories and files:
- `build/` directory - Contains build artifacts
- `.dart_tool/` directory - Contains Dart-specific cache files
- `.flutter-plugins-dependencies` file - Contains plugin dependency information
- Various ephemeral directories and configuration files

### 2. Get Fresh Dependencies

After clearing the cache, you should get fresh dependencies:

```bash
flutter pub get
```

This command downloads all the packages specified in the pubspec.yaml file.

### 3. Fix Any Build Issues

When restarting with an empty cache, you might encounter build issues that were previously masked by cached files. In our case, we had to fix:

#### NDK Version Mismatch

We updated the NDK version in `android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "com.example.savessa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"  // Updated from flutter.ndkVersion
    
    // ...
}
```

#### Null Safety Issues

We fixed a null safety issue in `lib/features/auth/presentation/screens/register_screen.dart` by adding a null assertion operator:

```dart
// Before
final existingUser = await dbService.getUserByEmail(userData['email']);

// After
final existingUser = await dbService.getUserByEmail(userData['email']!);
```

### 4. Run the App

Finally, run the app on a device or emulator:

```bash
flutter run -d <device_id>
```

## Common Issues and Solutions

### 1. NDK Version Mismatch

**Issue**: Your project is configured with one Android NDK version, but plugins require a different version.

**Solution**: Update the NDK version in `android/app/build.gradle.kts` to match the required version.

### 2. Null Safety Errors

**Issue**: After clearing the cache, the compiler might detect null safety issues that were previously overlooked.

**Solution**: Fix the null safety issues by properly handling nullable types, using null assertion operators where appropriate, or providing default values.

### 3. Firebase Configuration Issues

**Issue**: Firebase initialization might fail after clearing the cache if the configuration files are missing or incorrect.

**Solution**: Ensure that Firebase is properly configured with the correct `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files.

## Best Practices

1. **Regular Cache Clearing**: Periodically clear the cache during development to ensure your app works correctly without relying on cached data.

2. **Version Control**: Make sure your project is committed to version control before clearing the cache, in case you need to revert changes.

3. **Dependency Management**: Keep your dependencies up to date to avoid compatibility issues when clearing the cache.

4. **Error Handling**: Implement proper error handling in your app to gracefully handle issues that might arise when running with a fresh cache.

## Conclusion

Restarting a Flutter app with an empty cache is a useful troubleshooting technique that can help resolve various issues. By following the steps outlined in this guide, you can ensure that your app runs correctly with a clean state.