-- ============================================
-- MIGRATION: Add video_thumbnail_url Column
-- Adds video thumbnail URL back to chapters table
-- ============================================

-- Add video_thumbnail_url column next to video_url
ALTER TABLE public.chapters ADD COLUMN IF NOT EXISTS video_thumbnail_url TEXT;

-- Update the get_chapters_with_progress function to include video_thumbnail_url
DROP FUNCTION IF EXISTS public.get_chapters_with_progress(UUID);

CREATE OR REPLACE FUNCTION public.get_chapters_with_progress(p_user_id UUID)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    "order" INTEGER,
    is_locked BOOLEAN,
    requires_subscription BOOLEAN,
    video_url TEXT,
    video_thumbnail_url TEXT,
    video_watched BOOLEAN,
    video_watch_progress INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.title,
        c."order",
        -- Chapter is locked if:
        -- 1. User has no active subscription AND
        -- 2. Chapter requires subscription
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM public.user_subscriptions us
                WHERE us.user_id = p_user_id 
                AND us.is_active = true
                AND (us.expires_at IS NULL OR us.expires_at > NOW())
            ) THEN false -- User has subscription, all unlocked
            WHEN c.requires_subscription = true THEN true -- Chapter requires subscription and user doesn't have one
            ELSE false -- Chapter is free
        END as is_locked,
        c.requires_subscription,
        c.video_url,
        c.video_thumbnail_url,
        COALESCE(ucp.video_watched, false) as video_watched,
        COALESCE(ucp.video_watch_progress, 0) as video_watch_progress
    FROM public.chapters c
    LEFT JOIN public.user_chapter_progress ucp 
        ON ucp.chapter_id = c.id AND ucp.user_id = p_user_id
    ORDER BY c."order";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FINAL CHAPTERS TABLE STRUCTURE:
-- ============================================
-- id (SERIAL PRIMARY KEY)
-- title (TEXT NOT NULL) - From database
-- "order" (INTEGER NOT NULL UNIQUE) - From database
-- video_url (TEXT) - From database
-- video_thumbnail_url (TEXT) - From database (NEW)
-- requires_subscription (BOOLEAN DEFAULT false) - From database
-- created_at (TIMESTAMP WITH TIME ZONE DEFAULT NOW())
-- updated_at (TIMESTAMP WITH TIME ZONE DEFAULT NOW())
-- ============================================
-- Hardcoded in app (chapters_config.dart):
-- - iconPath (assets/icons/1.png to 12.png)
-- - color (hex colors)
-- - description (Kurdish text)
-- - videoTitle (Kurdish video title)
-- ============================================

-- Note: Run this migration in Supabase SQL Editor
