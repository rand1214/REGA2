# Screen Flow Update

## New Navigation Flow

### 1. Splash Screen (/)
- Shows traffic light animation
- Always navigates to Welcome screens
- Updates last login time if user is authenticated

### 2. Welcome Screens (/welcome)
- 3 swipeable welcome screens (Welcomer 1, 2, 3)
- User can swipe through or tap "Next" button
- Always navigates to Home screen after completion

### 3. Home Screen (/home)
- Main app screen with bottom navigation
- Checks authentication status on load
- If user NOT authenticated:
  - Shows profile setup bottom sheet (40px from top)
  - Bottom sheet is NOT dismissible (user must complete setup or recover account)
  - Bottom sheet contains:
    - Profile picture picker (optional)
    - Name input (required, minimum 2 words)
    - "Start" button → Creates account and shows recovery code
    - "Recover Account" button → Navigates to recovery screen

### 4. Recovery Screen (/recovery)
- Accessible from profile setup bottom sheet
- User enters 6-digit recovery code
- On success → Navigates to Home screen

## Changes Made

### Files Modified:
1. **lib/main.dart**
   - Changed `/welcome` route from `WelcomeStartScreen` to `WelcomeScreenWrapper`
   - Removed `/profile-setup` route (now a bottom sheet)

2. **lib/features/splash/screen/splash_screen.dart**
   - Removed authentication check logic
   - Always navigates to `/welcome` after animation

3. **lib/features/home/screen/home_screen.dart**
   - Added authentication check in `initState()`
   - Shows `ProfileSetupBottomSheet` if user not authenticated
   - Bottom sheet is non-dismissible

### Files Created:
1. **lib/features/profile_setup/widgets/profile_setup_bottom_sheet.dart**
   - Converted ProfileSetupScreen to a bottom sheet widget
   - Height: `screenHeight - 40` (40px from top)
   - Contains all profile setup UI
   - Has "Start" and "Recover Account" buttons

## User Experience

### First Time User:
1. Opens app → Splash screen
2. Swipes through 3 welcome screens
3. Arrives at Home screen
4. Bottom sheet appears automatically (40px from top)
5. User enters name and optionally uploads avatar
6. Taps "Start" → Account created
7. Sees recovery code screen → Must save code
8. Returns to Home screen (authenticated)

### Returning User (Authenticated):
1. Opens app → Splash screen
2. Swipes through 3 welcome screens
3. Arrives at Home screen
4. No bottom sheet (already authenticated)
5. Can use app normally

### User Recovering Account:
1. Opens app → Splash screen
2. Swipes through 3 welcome screens
3. Arrives at Home screen
4. Bottom sheet appears
5. Taps "Recover Account" button
6. Enters 6-digit recovery code
7. On success → Returns to Home screen (authenticated)

## Technical Details

### Bottom Sheet Configuration:
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,  // Allows custom height
  isDismissible: false,      // Cannot dismiss by tapping outside
  enableDrag: false,         // Cannot drag to dismiss
  backgroundColor: Colors.transparent,
  builder: (context) => const ProfileSetupBottomSheet(),
);
```

### Bottom Sheet Height:
```dart
Container(
  height: screenHeight - 40, // 40px from top
  // ...
)
```

## Benefits

1. **Simpler Flow**: All users see welcome screens first
2. **Better UX**: Profile setup is contextual (appears when needed)
3. **Less Navigation**: No separate profile setup screen
4. **Consistent**: Same route for all users, different UI based on auth status
5. **Non-intrusive**: Bottom sheet doesn't block entire screen
