# Recovery Code Update: 6 Digits → 8 Digits

## Summary
Updated the recovery code system from 6 digits to 8 digits across the entire application.

## Changes Made

### 1. Code Generation (`device_auth_service.dart`)
**Before:** Generated 6-digit codes (100000 to 999999)
```dart
final code = random.nextInt(900000) + 100000;
```

**After:** Generates 8-digit codes (10000000 to 99999999)
```dart
final code = random.nextInt(90000000) + 10000000;
```

### 2. Code Formatting (`device_auth_service.dart`)
**Before:** Format as XXX-XXX (e.g., 123-456)
```dart
if (code.length != 6) return code;
return '${code.substring(0, 3)}-${code.substring(3)}';
```

**After:** Format as XXXX-XXXX (e.g., 1234-5678)
```dart
if (code.length != 8) return code;
return '${code.substring(0, 4)}-${code.substring(4)}';
```

### 3. Code Validation (`device_auth_service.dart`)
Updated two validation checks:

**In `restoreAccountWithCode()`:**
- Changed from `cleanCode.length != 6` to `cleanCode.length != 8`

**In `submitRecoveryRequest()`:**
- Changed from `cleanCode.length != 6` to `cleanCode.length != 8`
- Updated error message from "٦ ژمارە" to "٨ ژمارە"

### 4. UI Input Field (`recovery_code_entry_bottom_sheet.dart`)
**Before:**
- maxLength: 7 (6 digits + 1 dash)
- Auto-dash after 3 digits
- Hint text: "123-456"

**After:**
- maxLength: 9 (8 digits + 1 dash)
- Auto-dash after 4 digits
- Hint text: "1234-5678"

**Auto-formatting logic:**
```dart
// Auto-format with dash after 4 digits
if (digitsOnly.length > 4) {
  final formatted = '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}';
  // ...
}
```

### 5. Documentation Updates
Updated references in:
- `RECOVERY_SYSTEM_IMPLEMENTATION.md`
  - Changed "6 digits" to "8 digits" in validation description
  - Updated user flow description

## Format Examples

| Old Format (6 digits) | New Format (8 digits) |
|-----------------------|------------------------|
| 123-456               | 1234-5678             |
| 987-654               | 9876-5432             |
| 100-000               | 1000-0000             |
| 999-999               | 9999-9999             |

## User Experience

### Code Entry
1. User starts typing: `1234`
2. After 4th digit, dash is automatically added: `1234-`
3. User continues: `1234-5678`
4. Total length: 9 characters (8 digits + 1 dash)

### Code Display
- Recovery code display screen shows formatted code: `1234-5678`
- Status screen shows formatted code: `1234-5678`
- Copy function copies the full code with dash

## Technical Details

### Random Number Generation
- **Range:** 10,000,000 to 99,999,999
- **Total possible codes:** 90,000,000 (90 million)
- **Previous range:** 900,000 (900 thousand)
- **Security improvement:** 100x more possible codes

### Validation
- Strips all non-digit characters before validation
- Accepts codes with or without dash
- Validates exact length of 8 digits
- Shows Kurdish error message if invalid

## Files Modified

1. `lib/core/services/device_auth_service.dart`
   - `generateRecoveryCode()` - Updated range
   - `formatRecoveryCode()` - Updated format logic
   - `restoreAccountWithCode()` - Updated validation
   - `submitRecoveryRequest()` - Updated validation and error message

2. `lib/features/profile_setup/widgets/recovery_code_entry_bottom_sheet.dart`
   - Updated maxLength from 7 to 9
   - Updated auto-dash logic from 3 to 4 digits
   - Updated hint text from "123-456" to "1234-5678"

3. `RECOVERY_SYSTEM_IMPLEMENTATION.md`
   - Updated documentation references

## Backward Compatibility

⚠️ **Breaking Change:** Existing 6-digit recovery codes will no longer work.

If you have existing users with 6-digit codes:
1. Run a migration to regenerate 8-digit codes for all users
2. Notify users of the change
3. Provide a grace period with both formats supported

## Testing Checklist

- [x] Generate new 8-digit recovery code
- [x] Format displays as XXXX-XXXX
- [x] Auto-dash appears after 4th digit
- [x] Validation accepts 8 digits
- [x] Validation rejects 6 digits
- [x] Validation rejects other lengths
- [x] Copy function works with new format
- [x] Recovery request submission works
- [x] Status screen displays formatted code
- [x] Error messages show correct digit count (٨)

## Security Benefits

1. **Increased entropy:** 90 million vs 900 thousand possible codes
2. **Harder to brute force:** 100x more attempts needed
3. **Better collision resistance:** Lower chance of duplicate codes
4. **Future-proof:** More room for growth

## Performance Impact

- Negligible: Random number generation is equally fast
- No database schema changes required
- No additional storage space needed
- Same hashing performance (SHA-256)
