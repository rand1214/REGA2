-- Migration: Add dialect field to user_profiles table
-- Description: Adds a dialect column to store user's Kurdish dialect preference

-- Add dialect column to user_profiles table
ALTER TABLE user_profiles
ADD COLUMN dialect TEXT CHECK (dialect IN ('sorani', 'badini'));

-- Add comment to the column
COMMENT ON COLUMN user_profiles.dialect IS 'User Kurdish dialect: sorani or badini';

-- Create index for faster queries (optional)
CREATE INDEX idx_user_profiles_dialect ON user_profiles(dialect);
