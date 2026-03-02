# Recovery Tracking & Duplicate User Fix

## Changes Implemented ✅

### 1. Fixed Duplicate User Bug
**Problem:** Recovery was creating 2 users (old + new)
**Solution:** Now updates existing user instead of creating new one

**Old Flow (Buggy):**
```
1. Find user by recovery code
2. Create NEW anonymous user
3. Copy data from old to new
4. Delete old user
Result: 2 rows temporarily, potential data loss
```

**New Flow (Fixed):**
```
1. Find user by recovery code
2. Update existing user's device info
3. Increment recovery count
4. Update timestamps
Result: 1 row always, no duplicates ✅
```

### 2. Added Recovery Tracking

**New columns in `user_profiles`:**
- `recovery_count` (INTEGER) - How many times account was recovered
- `last_recovery_at` (TIMESTAMP) - When account was last recovered

**Behavior:**
- Starts at 0 for new users
- Increments by 1 each time recovery code is used
- Timestamp updated on each recovery

### 3. Added Login Tracking

**New column in `user_profiles`:**
- `last_login_at` (TIMESTAMP) - When user last opened the app

**Behavior:**
- Set to NOW() when user creates account
- Updated every time user opens the app
- Updated when user recovers account

### 4. Removed english_name Field

**Removed from:**
- `user_profiles` table
- All code references
- Migration scripts

**Reason:** Not needed, only using Kurdish name

## Database Changes

### New Columns
```sql
-- Recovery tracking
recovery_count INTEGER DEFAULT 0
last_recovery_at TIMESTAMP WITH TIME ZONE

-- Login tracking
last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

### New Indexes
```sql
-- For faster queries
CREATE INDEX idx_user_profiles_last_login ON user_profiles(last_login_at DESC);
CREATE INDEX idx_user_profiles_last_recovery ON user_profiles(last_recovery_at DESC);
```

### New Function
```sql
-- Increments recovery count atomically
CREATE FUNCTION increment_recovery_count(user_id UUID) RETURNS INTEGER
```

## Code Changes

### device_auth_service.dart

**createNewUser():**
- Added `recovery_count: 0`
- Added `last_login_at: NOW()`

**restoreAccountWithCode():**
- ✅ No longer creates new user
- ✅ Updates existing user's device info
- ✅ Increments recovery_count
- ✅ Sets last_recovery_at
- ✅ Sets last_login_at
- ✅ Removed _copyUserData() method

**New method:**
- `updateLastLogin()` - Updates last_login_at timestamp

### splash_screen.dart

**_checkAuthAndNavigate():**
- Calls `updateLastLogin()` when user is authenticated
- Tracks every app launch

## Migration Steps

### 1. Run Updated Migration

In Supabase SQL Editor, run the updated migration file:
```
supabase/migration_remove_phone_auth.sql
```

This will:
- Drop `phone_number` column
- Drop `english_name` column
- Add `recovery_count` column
- Add `last_recovery_at` column
- Add `last_login_at` column
- Create indexes
- Create `increment_recovery_count()` function

### 2. Clean Up Existing Data (Optional)

If you have test users with duplicates:

```sql
-- Find duplicate users
SELECT recovery_code_hash, COUNT(*) 
FROM user_profiles 
WHERE recovery_code_hash IS NOT NULL
GROUP BY recovery_code_hash 
HAVING COUNT(*) > 1;

-- Keep only the most recent user for each recovery code
-- (Run this carefully!)
DELETE FROM user_profiles
WHERE id NOT IN (
  SELECT DISTINCT ON (recovery_code_hash) id
  FROM user_profiles
  WHERE recovery_code_hash IS NOT NULL
  ORDER BY recovery_code_hash, created_at DESC
);
```

### 3. Test the Flow

**Test Recovery (No Duplicates):**
1. Create new account → Get recovery code
2. Check database: 1 row in user_profiles ✅
3. Uninstall app
4. Reinstall app
5. Enter recovery code
6. Check database: Still 1 row (same row) ✅
7. Check recovery_count: Should be 1
8. Check last_recovery_at: Should be current time

**Test Login Tracking:**
1. Open app
2. Check last_login_at: Should be current time
3. Close app
4. Open app again
5. Check last_login_at: Should be updated

## Benefits

✅ **No duplicate users** - Only 1 row per user always
✅ **Track recovery usage** - See how many times account was recovered
✅ **Track user activity** - See when user last logged in
✅ **Better analytics** - Can identify inactive users
✅ **Cleaner database** - No orphaned rows
✅ **Faster recovery** - No data copying needed

## Database Schema

### user_profiles Table (Updated)

```sql
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY,
    kurdish_name TEXT,
    avatar_url TEXT,
    recovery_code_hash TEXT,
    device_fingerprint TEXT,
    last_device_info JSONB,
    recovery_count INTEGER DEFAULT 0,
    last_recovery_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Example Data

### New User
```json
{
  "id": "abc-123",
  "kurdish_name": "ئازاد محەمەد",
  "recovery_count": 0,
  "last_recovery_at": null,
  "last_login_at": "2024-02-27 10:00:00"
}
```

### After First Recovery
```json
{
  "id": "abc-123",
  "kurdish_name": "ئازاد محەمەد",
  "recovery_count": 1,
  "last_recovery_at": "2024-02-28 15:30:00",
  "last_login_at": "2024-02-28 15:30:00"
}
```

### After Multiple Logins
```json
{
  "id": "abc-123",
  "kurdish_name": "ئازاد محەمەد",
  "recovery_count": 1,
  "last_recovery_at": "2024-02-28 15:30:00",
  "last_login_at": "2024-03-01 09:15:00"
}
```

## Admin Dashboard Queries

### Find Inactive Users
```sql
SELECT kurdish_name, last_login_at
FROM user_profiles
WHERE last_login_at < NOW() - INTERVAL '30 days'
ORDER BY last_login_at DESC;
```

### Find Frequently Recovered Accounts
```sql
SELECT kurdish_name, recovery_count, last_recovery_at
FROM user_profiles
WHERE recovery_count > 3
ORDER BY recovery_count DESC;
```

### User Activity Report
```sql
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN last_login_at > NOW() - INTERVAL '7 days' THEN 1 END) as active_7_days,
  COUNT(CASE WHEN last_login_at > NOW() - INTERVAL '30 days' THEN 1 END) as active_30_days,
  AVG(recovery_count) as avg_recovery_count
FROM user_profiles;
```

## Troubleshooting

### Issue: recovery_count not incrementing
- Check if `increment_recovery_count()` function exists
- Verify RLS policies allow update
- Check Supabase logs for errors

### Issue: last_login_at not updating
- Verify `updateLastLogin()` is being called
- Check if user is authenticated
- Verify RLS policies allow update

### Issue: Still seeing duplicate users
- Make sure you ran the updated migration
- Check if old recovery code is still in use
- Clean up duplicates using SQL above

## Success Criteria

- [ ] Recovery creates 0 duplicate users
- [ ] recovery_count increments on each recovery
- [ ] last_recovery_at updates on recovery
- [ ] last_login_at updates on app launch
- [ ] english_name field removed
- [ ] All existing functionality still works

