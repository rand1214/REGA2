# Quick Start Guide

## For iPad Users (Unsigned Build)

### Option 1: Download Pre-built IPA from GitHub
1. Go to the [GitHub Actions](../../actions) tab
2. Select the latest successful workflow run
3. Download the `app-unsigned-ipa` artifact
4. Use a tool like [Sideloadly](https://sideloadly.io/) or [AltStore](https://altstore.io/) to install on your iPad

### Option 2: Build Locally

#### Requirements
- Mac with Xcode installed
- Flutter SDK
- iPad with iOS 12.0+

#### Steps
```bash
# 1. Clone the repository
git clone <repository-url>
cd flutter_supabase_app

# 2. Install dependencies
flutter pub get

# 3. Create .env file with your Supabase credentials
cp .env.example .env
# Edit .env with your credentials

# 4. Build unsigned IPA
flutter build ios --release --no-codesign

# 5. The IPA will be at: build/ios/iphoneos/Runner.app
```

#### Install on iPad
- Use Xcode: Open `ios/Runner.xcworkspace` and run on device
- Or use a sideloading tool with the generated IPA

## For Developers

### Development Setup
```bash
git clone <repository-url>
cd flutter_supabase_app
flutter pub get
flutter run
```

### Project Structure
```
lib/
├── features/
│   ├── book/          # PDF reading and annotation
│   ├── home/          # Home screen
│   ├── questions/     # Quiz functionality
│   └── ...
├── core/              # Shared services and utilities
└── main.dart          # App entry point
```

### Key Features
- **PDF Viewer**: Read and annotate PDFs
- **Drawing Tools**: 
  - Highlighter (with color selection)
  - Pencil (freehand drawing)
  - Shapes (rectangle, circle)
- **Annotations**:
  - Sticky notes
  - Text boxes
  - Bookmarks
- **Backend**: Supabase for data persistence

### Building for Different Platforms

**iOS (Unsigned)**
```bash
flutter build ios --release --no-codesign
```

**iOS (Signed - requires Apple Developer account)**
```bash
flutter build ios --release
```

**Android**
```bash
flutter build apk --release
```

## Environment Variables

Create a `.env` file with:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

See `.env.example` for reference.

## Troubleshooting

### Build Issues
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### iOS Specific
- Ensure Xcode is up to date: `xcode-select --install`
- Update CocoaPods: `sudo gem install cocoapods`
- Clean build: `rm -rf ios/Pods ios/Podfile.lock`

### Device Issues
- Enable Developer Mode on iPad (Settings > Privacy & Security)
- Trust the developer certificate
- Restart the device if installation fails

## Support

For issues or questions, please open a GitHub issue.

## License

All rights reserved.
