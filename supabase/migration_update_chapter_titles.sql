-- ============================================
-- MIGRATION: Update Chapter Titles with Line Breaks
-- Adds line breaks to specific chapter titles for 2-line display
-- ============================================

-- Update chapter 4 title to be on 2 lines
UPDATE public.chapters 
SET title = E'هێما و کەرەستەکانی\nهاتووچۆ'
WHERE "order" = 4;

-- Update chapter 6 title to be on 2 lines
UPDATE public.chapters 
SET title = E'خۆ ئامادەکردن\nبۆ لێخوڕین'
WHERE "order" = 6;

-- Update chapter 9 title to be on 2 lines
UPDATE public.chapters 
SET title = E'هەلسەنگاندنی\nمەترسییەکان'
WHERE "order" = 9;

-- Update chapter 11 title to be on 2 lines
UPDATE public.chapters 
SET title = E'لێخوڕینی\nژینگەپارێزان'
WHERE "order" = 11;

-- ============================================
-- NOTES:
-- E'...\n...' syntax adds a newline character
-- This will make the titles display on 2 lines in the UI
-- Run this migration in Supabase SQL Editor
-- ============================================
