-- ============================================
-- SUPABASE SCHEMA FOR HOME SCREEN
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. CHAPTERS TABLE
-- Stores all chapter information
-- ============================================
CREATE TABLE IF NOT EXISTS public.chapters (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    color TEXT NOT NULL, -- Hex color like "#B7D63E"
    icon_path TEXT NOT NULL, -- Asset path or storage URL
    "order" INTEGER NOT NULL UNIQUE, -- Display order (1-12)
    is_default_locked BOOLEAN DEFAULT true, -- Default lock status for new users
    video_url TEXT, -- YouTube/Vimeo URL or Supabase storage URL
    video_thumbnail_url TEXT, -- Thumbnail image URL
    video_title TEXT, -- Kurdish video title
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster ordering
CREATE INDEX IF NOT EXISTS idx_chapters_order ON public.chapters("order");

-- ============================================
-- 2. USER SUBSCRIPTIONS TABLE
-- Tracks user subscription status
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_type TEXT NOT NULL, -- 'monthly', 'yearly', 'lifetime'
    is_active BOOLEAN DEFAULT true,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE, -- NULL for lifetime
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id) -- One active subscription per user
);

-- Create index for faster user lookups
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_active ON public.user_subscriptions(is_active);

-- ============================================
-- 3. USER CHAPTER PROGRESS TABLE
-- Tracks which chapters each user has unlocked
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_chapter_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    chapter_id INTEGER NOT NULL REFERENCES public.chapters(id) ON DELETE CASCADE,
    is_unlocked BOOLEAN DEFAULT false,
    unlocked_at TIMESTAMP WITH TIME ZONE,
    video_watched BOOLEAN DEFAULT false,
    video_watch_progress INTEGER DEFAULT 0, -- Percentage (0-100)
    last_watched_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, chapter_id) -- One progress record per user per chapter
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_user_chapter_progress_user_id ON public.user_chapter_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_chapter_progress_chapter_id ON public.user_chapter_progress(chapter_id);

-- ============================================
-- 4. NOTIFICATIONS TABLE
-- Stores user notifications
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL, -- 'info', 'success', 'warning', 'chapter_unlock', 'subscription'
    is_read BOOLEAN DEFAULT false,
    action_url TEXT, -- Optional deep link
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- ============================================
-- 5. USER PROFILES TABLE (OPTIONAL)
-- Extended user information
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
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

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_chapter_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- CHAPTERS POLICIES
-- Everyone can read chapters (public data)
-- ============================================
CREATE POLICY "Anyone can read chapters"
    ON public.chapters
    FOR SELECT
    USING (true);

-- Only admins can insert/update/delete chapters
CREATE POLICY "Only admins can manage chapters"
    ON public.chapters
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- ============================================
-- USER SUBSCRIPTIONS POLICIES
-- Users can only see their own subscription
-- ============================================
CREATE POLICY "Users can read own subscription"
    ON public.user_subscriptions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscription"
    ON public.user_subscriptions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscription"
    ON public.user_subscriptions
    FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================
-- USER CHAPTER PROGRESS POLICIES
-- Users can only see/modify their own progress
-- ============================================
CREATE POLICY "Users can read own progress"
    ON public.user_chapter_progress
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress"
    ON public.user_chapter_progress
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
    ON public.user_chapter_progress
    FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================
-- NOTIFICATIONS POLICIES
-- Users can only see their own notifications
-- ============================================
CREATE POLICY "Users can read own notifications"
    ON public.notifications
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
    ON public.notifications
    FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================
-- USER PROFILES POLICIES
-- Users can read all profiles but only update their own
-- ============================================
CREATE POLICY "Anyone can read profiles"
    ON public.user_profiles
    FOR SELECT
    USING (true);

CREATE POLICY "Users can insert own profile"
    ON public.user_profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.user_profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, phone_number)
    VALUES (
        NEW.id,
        NEW.phone
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Function to get chapters with user's lock status
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
        -- 1. User has no active subscription AND
        -- 2. Chapter is not unlocked in progress table
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM public.user_subscriptions us
                WHERE us.user_id = p_user_id 
                AND us.is_active = true
                AND (us.expires_at IS NULL OR us.expires_at > NOW())
            ) THEN false -- User has subscription, all unlocked
            WHEN EXISTS (
                SELECT 1 FROM public.user_chapter_progress ucp
                WHERE ucp.user_id = p_user_id 
                AND ucp.chapter_id = c.id
                AND ucp.is_unlocked = true
            ) THEN false -- Chapter specifically unlocked
            ELSE c.is_default_locked -- Use default lock status
        END as is_locked,
        c.video_url,
        c.video_thumbnail_url,
        c.video_title,
        COALESCE(ucp.video_watched, false) as video_watched,
        COALESCE(ucp.video_watch_progress, 0) as video_watch_progress
    FROM public.chapters c
    LEFT JOIN public.user_chapter_progress ucp 
        ON ucp.chapter_id = c.id AND ucp.user_id = p_user_id
    ORDER BY c."order";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has active subscription
CREATE OR REPLACE FUNCTION public.has_active_subscription(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_subscriptions
        WHERE user_id = p_user_id
        AND is_active = true
        AND (expires_at IS NULL OR expires_at > NOW())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION public.get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM public.notifications
        WHERE user_id = p_user_id
        AND is_read = false
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SAMPLE DATA (OPTIONAL - FOR TESTING)
-- ============================================

-- Insert 12 chapters with Kurdish data
INSERT INTO public.chapters (title, description, color, icon_path, "order", is_default_locked, video_title) VALUES
('پێناسەکان', 'ئەم بەشە باس لە پێناسەی بەکارھێنەران، جۆری ئۆتۆمبێلەکان، شوفێر و وشە سەرەکییەکانی هاتووچۆ دەکات', '#B7D63E', 'assets/icons/chapter-1-icon.png', 1, false, 'وانەی یەکەم | پێناسەکان'),
('بنەما گشتییەکان', 'ئەم بەشە باسی بنەما گشتییەکانی ڕێگا، ڕێزمانی هاتووچۆ و ماف و ئەرکی شوفێر دەکات', '#F15A3C', 'assets/icons/chapter-2-icon.png', 2, true, 'وانەی دووەم | بنەما گشتییەکان'),
('یاسای هاتووچۆ', 'ئەم بەشە باسی یاساکان، جۆری مۆڵەت، سزاکان و دەسەڵاتی پۆلیس لە هاتووچۆ دەکات', '#2FA7DF', 'assets/icons/chapter-3-icon.png', 3, true, 'وانەی سێیەم | یاسای هاتووچۆ'),
('هێما و کەرەستەکانی هاتووچۆ', 'ئەم بەشە باسی هێما، ترافیک لایت، نیشانەکانی ئاگاداری و مانای هێماکان دەکات', '#2F6EBB', 'assets/icons/chapter-4-icon.png', 4, true, 'وانەی چوارەم | هێما و کەرەستەکان'),
('بەشەکانی ئۆتۆمبێل', 'ئەم بەشە باسی بەشە سەرەکییەکانی ئۆتۆمبێل و سیستەمە گرنگەکان و کارکردنیان دەکات', '#F4A640', 'assets/icons/chapter-5-icon.png', 5, true, 'وانەی پێنجەم | بەشەکانی ئۆتۆمبێل'),
('خۆ ئامادەکردن بۆ لێخوڕین', 'ئەم بەشە باسی پشکنینی ئۆتۆمبێل، دانیشتنێکی دروست و ئامادەکاری پێش لێخوڕین دەکات', '#E91E63', 'assets/icons/chapter-6-icon.png', 6, true, 'وانەی شەشەم | خۆ ئامادەکردن'),
('مانۆرکردن', 'ئەم بەشە باسی چۆنیەتی گۆڕینی ئاراستە، پارککردن و لێخوڕینی پارێزراوە لە شاردا دەکات', '#FF2C92', 'assets/icons/chapter-7-icon.png', 7, true, 'وانەی حەوتەم | مانۆرکردن'),
('بارودۆخی سەر ڕێگاکان', 'ئەم بەشە باسی بارودۆخی جیاوازی ڕێگا و شێوازی لێخوڕین لە باران و بەفردا دەکات', '#F3C21F', 'assets/icons/chapter-8-icon.png', 8, true, 'وانەی هەشتەم | بارودۆخی ڕێگاکان'),
('هەلسەنگاندنی مەترسییەکان', 'ئەم بەشە باس دەکات لە ناسینەوەی مەترسی، چاودێری باش و بڕیاردانی خێرا', '#7B3FA0', 'assets/icons/chapter-9-icon.png', 9, true, 'وانەی نۆیەم | هەلسەنگاندنی مەترسی'),
('تەندروستی شوفێر', 'ئەم بەشە باسی تەندروستی شوفێر، کاریگەری ماندووبوون و مادە ھۆشبەر دەکات', '#20C6C2', 'assets/icons/chapter-10-icon.png', 10, true, 'وانەی دەیەم | تەندروستی شوفێر'),
('لێخوڕینی ژینگەپارێزان', 'ئەم بەشە باسی شێوازی لێخوڕینی ژینگەپارێز، کەمکردنەوەی سوتەمەنی و پاراستنی هەوا دەکات', '#3FB34F', 'assets/icons/chapter-11-icon.png', 11, true, 'وانەی یازدەیەم | لێخوڕینی ژینگەپارێز'),
('فریاگوزاری سەرەتایی', 'ئەم بەشە باسی فریاگوزاری سەرەتایی، یارمەتیدانی بریندار و چارەسەری کاتی ڕووداو دەکات', '#E53935', 'assets/icons/chapter-12-icon.png', 12, true, 'وانەی دوازدەیەم | فریاگوزاری سەرەتایی')
ON CONFLICT DO NOTHING;

-- ============================================
-- STORAGE BUCKETS (Run in Supabase Dashboard)
-- ============================================
-- Go to Storage > Create new bucket
-- 1. Create bucket: "chapter-icons" (public)
-- 2. Create bucket: "video-thumbnails" (public)
-- 3. Create bucket: "videos" (public or private based on your needs)

-- ============================================
-- NOTES FOR ADMIN
-- ============================================
-- 1. Upload chapter icons to "chapter-icons" bucket
-- 2. Upload video thumbnails to "video-thumbnails" bucket
-- 3. Update chapters table with storage URLs:
--    UPDATE chapters SET 
--      icon_path = 'https://[project-ref].supabase.co/storage/v1/object/public/chapter-icons/chapter-1.png',
--      video_thumbnail_url = 'https://[project-ref].supabase.co/storage/v1/object/public/video-thumbnails/chapter-1-thumb.jpg',
--      video_url = 'https://youtube.com/watch?v=...'
--    WHERE id = 1;

-- ============================================
-- MIGRATION FILES
-- ============================================
-- After running this schema, run these migration files in order:
-- 1. migration_add_requires_subscription.sql - Adds requires_subscription field (free vs premium chapters)
-- 2. migration_add_is_active.sql - Adds is_active field (enable/disable chapters)
