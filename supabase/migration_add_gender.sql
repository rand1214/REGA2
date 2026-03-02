-- Migration: Add gender field to user_profiles table
-- Description: Adds a gender column to store user's gender selection (male/female)

-- Add gender column to user_profiles table
ALTER TABLE user_profiles
ADD COLUMN gender TEXT CHECK (gender IN ('male', 'female'));

-- Add comment to the column
COMMENT ON COLUMN user_profiles.gender IS 'User gender: male or female';

-- Create index for faster queries (optional)
CREATE INDEX idx_user_profiles_gender ON user_profiles(gender);
