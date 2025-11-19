-- Migration: Add user_id column to biometrias table for multi-tenancy
-- Date: 2025-11-16
-- Related: T008, FR-031
-- NOTE: Table was later renamed from biometria to biometrias in migration 20251116_rename_biometria_to_biometrias.sql

-- Add user_id column
ALTER TABLE public.biometria
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create index for performance on user_id queries
CREATE INDEX IF NOT EXISTS idx_biometria_user_id ON public.biometria(user_id);

-- Add comment for documentation
COMMENT ON COLUMN public.biometria.user_id IS 'Foreign key to auth.users for multi-tenant isolation';
