-- Migration: Rename sponsors table to sponsers

ALTER TABLE public.sponsors RENAME TO sponsers;

-- Rename indexes to match new table name
ALTER INDEX idx_sponsors_order RENAME TO idx_sponsers_order;
ALTER INDEX idx_sponsors_validity RENAME TO idx_sponsers_validity;

-- Rename policy
ALTER POLICY "sponsors_public_read" ON public.sponsers
  RENAME TO "sponsers_public_read";
