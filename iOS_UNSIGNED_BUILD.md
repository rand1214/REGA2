# iOS Unsigned Build Guide for iPad

## Overview
This guide explains how to build and deploy an unsigned iOS app for iPad development and testing.

## What is an Unsigned Build?
- **Unsigned**: Not code-signed with an Apple Developer certificate
- **Development Only**: Intended for testing, not App Store distribution
- **Requires Sideloading**: Must be installed via tools like Xcode, Sideloadly, or AltStore
- **No Expiration**: Unlike provisioning profiles, unsigned builds don't expire

## Prerequisites

### System Requirements
- macOS 11.0 or later
- Xcode 13.0 or later
- Flutter SDK (3.0+)
- CocoaPods

### Device Requirements
- iPad with iOS 12.0 or later
- Developer Mode enabled
- USB connection to Mac (for Xcode installation)

## Building Unsigned IPA

### Method 1: Using Flutter CLI (Recommended)

```bash
# Navigate to project directory
cd flutter_supabase_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build unsigned IPA
flutter build ios --release --no-codesign
```

**Output Location**: `build/ios/iphoneos/Runner.app`

### Method 2: Using Xcode

```bash
# Open the workspace
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Runner" in the left panel
# 2. Go to "Signing & Capabilities"
# 3. Uncheck "Automatically manage signing"
# 4. Set Team to "None"
# 5. Select your iPad from the device list
# 6. Press Cmd+B to build
# 7. Press Cmd+R to run on device
```

## Installation Methods

### Method 1: Xcode (Easiest for Development)

```bash
# Build and run directly on connected iPad
flutter run -d <device-id>

# Or use Xcode
open ios/Runner.xcworkspace
# Select your iPad and press Cmd+R
```

**Advantages**:
- Simplest method
- Direct debugging support
- No additional tools needed

**Requirements**:
- Mac with Xcode
- iPad connected via USB
- Developer Mode enabled on iPad

### Method 2: Sideloadly (Recommended for Distribution)

1. Download [Sideloadly](https://sideloadly.io/)
2. Connect iPad via USB
3. Open Sideloadly
4. Drag and drop the IPA file
5. Select your Apple ID
6. Click "Start"

**Advantages**:
- Works with any IPA
- No Xcode required
- Can install multiple apps

### Method 3: AltStore

1. Download [AltStore](https://altstore.io/)
2. Install AltStore on iPad
3. Connect iPad to Mac
4. Open AltStore on iPad
5. Go to "My Apps" > "+"
6. Select the IPA file

**Advantages**:
- Persistent installation
- Automatic refresh
- Community support

## Troubleshooting

### Build Fails with Code Signing Error
```bash
# Ensure you're using --no-codesign flag
flutter build ios --release --no-codesign

# If still failing, clean and rebuild
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
flutter build ios --release --no-codesign
```

### App Won't Install on iPad

**Check Developer Mode**:
- Settings > Privacy & Security > Developer Mode (toggle ON)

**Trust Developer Certificate**:
- Settings > General > VPN & Device Management
- Find your developer certificate and tap "Trust"

**Restart Device**:
- Force restart iPad: Hold power + volume down for 10 seconds

**Check Architecture**:
```bash
# Ensure building for arm64 (iPad)
flutter build ios --release --no-codesign --verbose
```

### Installation Fails with Sideloadly

1. Update Xcode: `xcode-select --install`
2. Update CocoaPods: `sudo gem install cocoapods`
3. Disconnect and reconnect iPad
4. Try again

### App Crashes on Launch

1. Check console output: `flutter logs`
2. Verify .env file exists with correct credentials
3. Check Supabase connectivity
4. Review iOS build logs: `flutter build ios --verbose`

## Device Management

### Enable Developer Mode (iOS 16+)
1. Settings > Privacy & Security
2. Scroll down to "Developer Mode"
3. Toggle ON
4. Restart device

### Trust Developer Certificate
1. Settings > General > VPN & Device Management
2. Find your certificate under "Developer App"
3. Tap and select "Trust"

### Remove App
- Long press app icon > Remove App > Delete App

## Performance Tips

### Optimize Build Size
```bash
flutter build ios --release --no-codesign --split-debug-info
```

### Faster Development Builds
```bash
flutter build ios --debug --no-codesign
```

### Enable Verbose Logging
```bash
flutter build ios --release --no-codesign --verbose
```

## Security Notes

⚠️ **Important**: Unsigned builds are for development only:
- Do NOT distribute to end users
- Do NOT use in production
- Do NOT store sensitive data without encryption
- Credentials should be in .env (not committed to git)

## Continuous Integration

GitHub Actions automatically builds unsigned IPAs on push:
1. Go to Actions tab
2. Select latest workflow
3. Download `app-unsigned-ipa` artifact

See `.github/workflows/build-ios-unsigned.yml` for configuration.

## Additional Resources

- [Flutter iOS Build Documentation](https://flutter.dev/docs/deployment/ios)
- [Xcode Documentation](https://developer.apple.com/xcode/)
- [Sideloadly Documentation](https://sideloadly.io/)
- [AltStore Documentation](https://altstore.io/)

## Support

For issues or questions:
1. Check this guide
2. Review Flutter documentation
3. Open a GitHub issue
4. Check existing issues for solutions
