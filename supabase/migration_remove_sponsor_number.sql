-- Migration: Remove sponsor_number column from sponsors table

ALTER TABLE public.sponsors
  DROP COLUMN IF EXISTS sponsor_number;
