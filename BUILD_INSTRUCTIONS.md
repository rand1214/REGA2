# Build Instructions for iPad (Unsigned)

## Prerequisites
- Flutter SDK installed
- Xcode installed (for iOS builds)
- CocoaPods installed

## Setup

### 1. Clone and Install Dependencies
```bash
git clone <repository-url>
cd flutter_supabase_app
flutter pub get
```

### 2. Environment Configuration
Create a `.env` file in the project root with your Supabase credentials:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Build for iPad (Unsigned)

#### Option A: Build and Run on Connected iPad
```bash
flutter run -d <device-id>
```

To find your device ID:
```bash
flutter devices
```

#### Option B: Build IPA for Unsigned Deployment
```bash
flutter build ios --no-codesign
```

This creates an unsigned IPA at: `build/ios/ipa/flutter_supabase_app.ipa`

#### Option C: Build for Simulator
```bash
flutter run
```

### 4. Manual Installation on iPad (Unsigned)

For unsigned builds, you'll need to use one of these methods:

**Method 1: Using Xcode**
```bash
open ios/Runner.xcworkspace
```
- Select "Runner" in Xcode
- Go to Signing & Capabilities
- Uncheck "Automatically manage signing"
- Set Team to "None"
- Build and run on device

**Method 2: Using ios-app-installer or similar tools**
- Use third-party tools to install the unsigned IPA on your iPad

### 5. Device Requirements
- iPad with iOS 12.0 or later
- Developer Mode enabled (Settings > Privacy & Security > Developer Mode)
- Trust the developer certificate (Settings > General > VPN & Device Management)

## Troubleshooting

### Build Fails with Code Signing Error
Ensure you're using the `--no-codesign` flag:
```bash
flutter build ios --no-codesign
```

### App Won't Install on Device
1. Enable Developer Mode on iPad
2. Trust the developer certificate
3. Ensure the IPA is built for the correct architecture (arm64)

### Dependencies Issues
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

## Project Structure
- `/lib` - Dart source code
- `/ios` - iOS-specific configuration
- `/assets` - Images, icons, and other assets
- `/pubspec.yaml` - Project dependencies

## Features
- PDF reading with annotations
- Highlighter tool with color selection
- Pencil drawing tool
- Shape drawing (rectangle, circle)
- Sticky notes
- Bookmarks
- Text boxes
- Supabase backend integration

## Notes
- This build is unsigned and intended for development/testing only
- For App Store distribution, proper code signing is required
- The app supports both iPhone and iPad orientations
