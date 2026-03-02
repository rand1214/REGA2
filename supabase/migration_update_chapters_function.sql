-- ============================================
-- MIGRATION: Update get_chapters_with_progress Function
-- Updates function to work with simplified chapters table
-- ============================================

-- Drop the existing function first
DROP FUNCTION IF EXISTS public.get_chapters_with_progress(UUID);

-- Recreate the function with simplified columns
CREATE OR REPLACE FUNCTION public.get_chapters_with_progress(p_user_id UUID)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    "order" INTEGER,
    is_locked BOOLEAN,
    requires_subscription BOOLEAN,
    video_url TEXT,
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
        COALESCE(ucp.video_watched, false) as video_watched,
        COALESCE(ucp.video_watch_progress, 0) as video_watch_progress
    FROM public.chapters c
    LEFT JOIN public.user_chapter_progress ucp 
        ON ucp.chapter_id = c.id AND ucp.user_id = p_user_id
    ORDER BY c."order";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- NOTES:
-- 1. This function now only returns simplified chapter data
-- 2. UI elements (icon, color, description, thumbnail) are hardcoded in the app
-- 3. Only title comes from database
-- 4. Run this AFTER running migration_simplify_chapters.sql
-- ============================================
