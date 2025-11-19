-- Migration: Add user_id column to estanques table for multi-tenancy
-- Date: 2025-11-16
-- Related: T006, FR-017, FR-031

-- Add user_id column
ALTER TABLE public.estanques
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create unique constraint for numero within user_id scope (FR-017)
ALTER TABLE public.estanques
ADD CONSTRAINT unique_estanque_numero_per_user UNIQUE (user_id, numero);

-- Create index for performance on user_id queries
CREATE INDEX IF NOT EXISTS idx_estanques_user_id ON public.estanques(user_id);

-- Add comment for documentation
COMMENT ON COLUMN public.estanques.user_id IS 'Foreign key to auth.users for multi-tenant isolation. Numero must be unique within user_id scope (FR-017)';
