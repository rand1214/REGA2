-- Migration: Add province field to user_profiles table
-- Description: Adds a province column to store user's province selection

-- Add province column to user_profiles table
ALTER TABLE user_profiles
ADD COLUMN province TEXT CHECK (province IN ('sulaymaniyah', 'erbil', 'halabja', 'duhok'));

-- Add comment to the column
COMMENT ON COLUMN user_profiles.province IS 'User province: sulaymaniyah, erbil, halabja, or duhok';

-- Create index for faster queries (optional)
CREATE INDEX idx_user_profiles_province ON user_profiles(province);
