-- Migration: Add plain text recovery_code to user_profiles
-- This allows manual comparison of recovery codes in the database
-- Keeps recovery_code_hash for backward compatibility

-- Add plain text recovery_code column
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS recovery_code TEXT;

-- Create index for faster recovery code lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_recovery_code_plain 
ON public.user_profiles(recovery_code);

-- Add comment
COMMENT ON COLUMN public.user_profiles.recovery_code IS 'Plain text recovery code (6 digits with dash, e.g., 123-456) for manual verification';
COMMENT ON COLUMN public.user_profiles.recovery_code_hash IS 'Hashed recovery code for backward compatibility';

-- Note: When creating new users, both recovery_code and recovery_code_hash should be set
-- Example: recovery_code = '123-456', recovery_code_hash = hash('123-456')
