-- ============================================
-- MIGRATION: Add is_active field
-- This migration adds a field to enable/disable chapters
-- Run this AFTER running the main schema.sql
-- ============================================

-- Add the new column
ALTER TABLE public.chapters 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Add comment to explain the field
COMMENT ON COLUMN public.chapters.is_active IS 
'Indicates if chapter is active/visible. true = active (visible to users), false = inactive (hidden from users)';

-- Update existing data - make all chapters active by default
UPDATE public.chapters 
SET is_active = true;

-- ============================================
-- Update the get_chapters_with_progress function
-- to filter out inactive chapters
-- ============================================

CREATE OR REPLACE FUNCTION public.get_chapters_with_progress(p_user_id UUID)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    description TEXT,
    color TEXT,
    icon_path TEXT,
    "order" INTEGER,
    is_locked BOOLEAN,
    video_url TEXT,
    video_thumbnail_url TEXT,
    video_title TEXT,
    video_watched BOOLEAN,
    video_watch_progress INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.title,
        c.description,
        c.color,
        c.icon_path,
        c."order",
        -- Chapter is locked if:
        -- 1. Chapter requires subscription AND
        -- 2. User has no active subscription
        CASE 
            -- If chapter doesn't require subscription, it's always unlocked (free)
            WHEN c.requires_subscription = false THEN false
            -- If chapter requires subscription, check if user has active subscription
            WHEN EXISTS (
                SELECT 1 FROM public.user_subscriptions us
                WHERE us.user_id = p_user_id 
                AND us.is_active = true
                AND (us.expires_at IS NULL OR us.expires_at > NOW())
            ) THEN false -- User has subscription, chapter unlocked
            -- No subscription, chapter is locked
            ELSE true
        END as is_locked,
        c.video_url,
        c.video_thumbnail_url,
        c.video_title,
        COALESCE(ucp.video_watched, false) as video_watched,
        COALESCE(ucp.video_watch_progress, 0) as video_watch_progress
    FROM public.chapters c
    LEFT JOIN public.user_chapter_progress ucp 
        ON ucp.chapter_id = c.id AND ucp.user_id = p_user_id
    WHERE c.is_active = true -- Only return active chapters
    ORDER BY c."order";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- VERIFICATION QUERY
-- Run this to check the migration worked
-- ============================================
-- SELECT id, title, "order", is_active, requires_subscription 
-- FROM public.chapters 
-- ORDER BY "order";

-- ============================================
-- USAGE EXAMPLES
-- ============================================
-- Deactivate a chapter (hide from users):
-- UPDATE public.chapters SET is_active = false WHERE id = 5;

-- Activate a chapter (show to users):
-- UPDATE public.chapters SET is_active = true WHERE id = 5;

-- View all inactive chapters:
-- SELECT id, title, "order" FROM public.chapters WHERE is_active = false;
