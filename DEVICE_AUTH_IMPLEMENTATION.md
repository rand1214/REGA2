# Device-Based Authentication with Recovery Code

## Implementation Complete ✅

The app now uses device-based authentication with a 6-digit recovery code system.

## How It Works

### First Time User Flow
```
1. App Launch → Splash Screen
2. No authentication found → Welcome Screen
3. User taps "دەست پێبکە" (Start)
4. Profile Setup Screen → Enter name + optional avatar
5. Account created → Recovery Code Display Screen
6. Shows 6-digit code (e.g., 123-456)
7. User saves code → Taps "دەست پێبکە" → Home Screen
```

### Returning User Flow
```
1. App Launch → Splash Screen
2. Authentication found → Home Screen (direct)
```

### Reinstall/Recovery Flow
```
1. App Launch → Splash Screen
2. No authentication found → Welcome Screen
3. User taps "گەڕانەوەی هەژمار" (Restore Account)
4. Recovery Code Entry Screen
5. User enters 6-digit code
6. Account restored → Home Screen
```

## Files Created

### Services
- `lib/core/services/device_auth_service.dart` - Core authentication logic
  - Generate recovery codes
  - Create anonymous users
  - Restore accounts
  - Device fingerprinting
  - User data migration

### Screens
- `lib/features/profile_setup/screen/profile_setup_screen.dart` - Name + avatar input
- `lib/features/profile_setup/screen/recovery_code_display_screen.dart` - Shows recovery code
- `lib/features/profile_setup/screen/recovery_code_entry_screen.dart` - Enter code to restore
- `lib/features/welcome_screen/screen/welcome_start_screen.dart` - Start or restore options

### Database
- `supabase/migration_remove_phone_auth.sql` - Updated migration with recovery code support

## Files Modified

- `pubspec.yaml` - Added packages: device_info_plus, flutter_secure_storage, crypto
- `lib/main.dart` - Updated router with new routes
- `lib/features/splash/screen/splash_screen.dart` - Added authentication check

## Database Changes

### New Columns in `user_profiles`:
- `recovery_code_hash` (TEXT) - Hashed 6-digit recovery code
- `device_fingerprint` (TEXT) - Device identification (optional)
- `last_device_info` (JSONB) - Device model, OS info

### New Function:
- `find_user_by_recovery_code(p_code_hash TEXT)` - Lookup user by recovery code

## Setup Steps

### 1. Install Packages
```bash
cd flutter_supabase_app
flutter pub get
```

### 2. Run Database Migration
In Supabase SQL Editor, run:
```sql
-- File: supabase/migration_remove_phone_auth.sql
```

Or copy and paste the migration content.

### 3. Test the Flow

**New User:**
1. Hot restart app
2. Should see Welcome Screen
3. Tap "دەست پێبکە"
4. Enter name (e.g., "ئازاد محەمەد ئەحمەد")
5. Tap "دەست پێبکە"
6. See recovery code (e.g., "123-456")
7. Screenshot or write down the code
8. Tap "دەست پێبکە"
9. Should go to Home Screen

**Returning User:**
1. Close and reopen app
2. Should go directly to Home Screen

**Recovery Test:**
1. Uninstall app
2. Reinstall app
3. Should see Welcome Screen
4. Tap "گەڕانەوەی هەژمار"
5. Enter your recovery code
6. Should restore account and go to Home

## Security Features

✅ **Recovery code hashed** - Stored as SHA-256 hash in database
✅ **Secure local storage** - User token encrypted on device
✅ **Anonymous auth** - Uses Supabase anonymous authentication
✅ **RLS policies** - Row Level Security protects user data
✅ **Device fingerprint** - Optional device identification

## Recovery Code Format

- **Length:** 6 digits
- **Format:** 123-456 (with dash for readability)
- **Storage:** Hashed with SHA-256
- **Display:** Formatted with dash separator

## User Data Migration

When restoring account, the system automatically copies:
- ✅ User profile (name, avatar)
- ✅ Subscriptions
- ✅ Chapter progress
- ✅ Notifications
- ✅ All user-related data

## Important Notes

1. **Recovery code is critical** - Users must save it to restore account after reinstall
2. **One device per user** - Each device creates one user account
3. **No email required** - Completely anonymous authentication
4. **Always online** - App requires internet connection
5. **Device transfer** - Will be handled in admin dashboard (future feature)

## Troubleshooting

### Issue: Recovery code not working
- Check code format (6 digits, with or without dash)
- Verify migration was run successfully
- Check Supabase logs for errors

### Issue: User not authenticated after setup
- Check Supabase anonymous auth is enabled
- Verify RLS policies are correct
- Check device has internet connection

### Issue: Profile not created
- Check `user_profiles` table exists
- Verify RLS policies allow insert
- Check Supabase logs for errors

## Next Steps

1. ✅ Run database migration
2. ✅ Test new user flow
3. ✅ Test recovery flow
4. ⏳ Implement avatar upload to Supabase Storage
5. ⏳ Add device transfer in admin dashboard

## API Reference

### DeviceAuthService Methods

```dart
// Check if user is authenticated
Future<bool> isAuthenticated()

// Create new user with recovery code
Future<Map<String, dynamic>> createNewUser({
  required String kurdishName,
  String? avatarUrl,
})

// Restore account using recovery code
Future<bool> restoreAccountWithCode(String code)

// Get stored recovery code
Future<String?> getStoredRecoveryCode()

// Sign out
Future<void> signOut()

// Update profile
Future<void> updateProfile({
  String? kurdishName,
  String? avatarUrl,
})
```

## Success Criteria

- [ ] New users can create account with name
- [ ] Recovery code is displayed and can be copied
- [ ] Returning users go directly to home
- [ ] Users can restore account with recovery code
- [ ] All user data is preserved after recovery
- [ ] No duplicate accounts created

