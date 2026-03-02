-- ============================================
-- MIGRATION: Device-Based Authentication with Recovery Code
-- This removes phone auth and adds recovery code system
-- ============================================

-- Drop the phone_number column from user_profiles
ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS phone_number;

-- Drop the english_name column from user_profiles
ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS english_name;

-- Add recovery code hash column (stores hashed 6-digit code)
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS recovery_code_hash TEXT;

-- Add device fingerprint column (optional, for future analytics)
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS device_fingerprint TEXT;

-- Add last_device_info column (stores device model, OS for display)
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS last_device_info JSONB;

-- Add recovery tracking columns
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS recovery_count INTEGER DEFAULT 0;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS last_recovery_at TIMESTAMP WITH TIME ZONE;

-- Add login tracking column
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Update the trigger function to not include phone_number
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id)
    VALUES (NEW.id)
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop OTP logs table if it exists
DROP TABLE IF EXISTS public.otp_logs CASCADE;

-- Drop existing function if it exists (needed to change return type)
DROP FUNCTION IF EXISTS public.find_user_by_recovery_code(TEXT);

-- Create function to find user by recovery code
-- Returns TEXT instead of UUID to work better with Dart
CREATE OR REPLACE FUNCTION public.find_user_by_recovery_code(p_code_hash TEXT)
RETURNS TEXT AS $$
DECLARE
    v_user_id TEXT;
BEGIN
    SELECT id::TEXT INTO v_user_id
    FROM public.user_profiles
    WHERE recovery_code_hash = p_code_hash
    LIMIT 1;
    
    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update user profile during recovery
-- This bypasses RLS since it uses SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.update_user_recovery(
    p_user_id UUID,
    p_device_fingerprint TEXT,
    p_device_info JSONB
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_count INTEGER;
BEGIN
    -- Get current recovery count
    SELECT COALESCE(recovery_count, 0) INTO v_current_count
    FROM public.user_profiles
    WHERE id = p_user_id;
    
    -- Update the profile with new device info and increment recovery count
    UPDATE public.user_profiles
    SET 
        device_fingerprint = p_device_fingerprint,
        last_device_info = p_device_info,
        recovery_count = v_current_count + 1,
        last_recovery_at = NOW(),
        last_login_at = NOW(),
        updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Return true if update was successful
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to increment recovery count
CREATE OR REPLACE FUNCTION public.increment_recovery_count(user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_new_count INTEGER;
BEGIN
    UPDATE public.user_profiles
    SET recovery_count = COALESCE(recovery_count, 0) + 1
    WHERE id = user_id
    RETURNING recovery_count INTO v_new_count;
    
    RETURN v_new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create index for faster recovery code lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_recovery_code 
ON public.user_profiles(recovery_code_hash);

-- Create index for faster login time queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_login 
ON public.user_profiles(last_login_at DESC);

-- Create index for faster recovery time queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_recovery 
ON public.user_profiles(last_recovery_at DESC);

-- ============================================
-- NOTES:
-- 1. Removes phone_number and english_name from user_profiles
-- 2. Adds recovery_code_hash for account recovery
-- 3. Adds device_fingerprint for device identification
-- 4. Adds last_device_info for displaying device details
-- 5. Adds recovery_count to track how many times account was recovered
-- 6. Adds last_recovery_at to track when account was last recovered
-- 7. Adds last_login_at to track when user last opened the app
-- 8. Creates function to lookup users by recovery code (returns TEXT)
-- 9. Run this migration before deploying new app version
-- ============================================
