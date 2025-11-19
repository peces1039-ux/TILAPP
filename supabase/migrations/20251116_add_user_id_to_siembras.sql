-- Migration: Add user_id column to siembras table for multi-tenancy
-- Date: 2025-11-16
-- Related: T007, FR-031

-- Add user_id column
ALTER TABLE public.siembras
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create index for performance on user_id queries
CREATE INDEX IF NOT EXISTS idx_siembras_user_id ON public.siembras(user_id);

-- Add comment for documentation
COMMENT ON COLUMN public.siembras.user_id IS 'Foreign key to auth.users for multi-tenant isolation';
