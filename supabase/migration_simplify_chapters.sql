-- ============================================
-- MIGRATION: Simplify Chapters Table
-- Removes unnecessary columns from chapters table
-- ============================================

-- Drop columns that are no longer needed
ALTER TABLE public.chapters DROP COLUMN IF EXISTS description;
ALTER TABLE public.chapters DROP COLUMN IF EXISTS color;
ALTER TABLE public.chapters DROP COLUMN IF EXISTS icon_path;
ALTER TABLE public.chapters DROP COLUMN IF EXISTS is_default_locked;
ALTER TABLE public.chapters DROP COLUMN IF EXISTS video_thumbnail_url;
ALTER TABLE public.chapters DROP COLUMN IF EXISTS video_title;
ALTER TABLE public.chapters DROP COLUMN IF EXISTS is_active;

-- ============================================
-- FINAL CHAPTERS TABLE STRUCTURE:
-- ============================================
-- id (SERIAL PRIMARY KEY) - Auto-generated
-- title (TEXT NOT NULL) - Chapter title
-- "order" (INTEGER NOT NULL UNIQUE) - Display order
-- video_url (TEXT) - YouTube/Vimeo URL or Supabase storage URL
-- requires_subscription (BOOLEAN DEFAULT false) - Whether chapter requires subscription
-- created_at (TIMESTAMP WITH TIME ZONE DEFAULT NOW())
-- updated_at (TIMESTAMP WITH TIME ZONE DEFAULT NOW())
-- ============================================

-- Note: Run this migration in Supabase SQL Editor
-- Warning: This will permanently delete the specified columns and their data
-- Make sure to backup your data before running this migration
