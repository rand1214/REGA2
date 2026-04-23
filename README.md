# REGA2 - Flutter Supabase App

A Flutter application integrated with Supabase backend.

## Features

- Supabase authentication and database integration
- Modern Flutter UI
- Cross-platform support (iOS, Android)

## Setup

1. Clone the repository
2. Copy `.env.example` to `.env` and fill in your Supabase credentials
3. Run `flutter pub get`
4. Run `flutter run`

## Building

### iOS (Unsigned IPA)
The project includes a GitHub Actions workflow that automatically builds an unsigned IPA on push to main/master branch.

To download the IPA:
1. Go to the Actions tab in GitHub
2. Select the latest workflow run
3. Download the `app-unsigned-ipa` artifact

### Manual Build
```bash
flutter build ios --release --no-codesign
```

## Environment Variables

Required environment variables (see `.env.example`):
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key

## License

All rights reserved.
