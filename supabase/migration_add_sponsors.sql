-- Migration: Add sponsors table
-- Run this in the Supabase SQL editor

CREATE TABLE IF NOT EXISTS public.sponsors (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name  text NOT NULL,
  company_phone text NOT NULL,
  sponsor_number integer NOT NULL UNIQUE,
  "order"       integer NOT NULL DEFAULT 0,
  image_url     text NOT NULL,
  valid_from    timestamptz NOT NULL,
  valid_until   timestamptz NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT valid_date_range CHECK (valid_until > valid_from)
);

-- Index for fast active sponsor queries
CREATE INDEX IF NOT EXISTS idx_sponsors_order
  ON public.sponsors ("order" ASC);

CREATE INDEX IF NOT EXISTS idx_sponsors_validity
  ON public.sponsors (valid_from, valid_until);

-- Enable Row Level Security
ALTER TABLE public.sponsors ENABLE ROW LEVEL SECURITY;

-- Allow anyone (including unauthenticated) to read active sponsors
CREATE POLICY "sponsors_public_read"
  ON public.sponsors
  FOR SELECT
  USING (
    valid_from <= now() AND valid_until >= now()
  );

-- Only service role / admin can insert, update, delete
-- (managed via Supabase dashboard or service key)
