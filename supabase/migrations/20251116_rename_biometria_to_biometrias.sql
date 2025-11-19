-- Migration: Rename biometria table to biometrias for naming consistency
-- Date: 2025-11-16
-- Related: T008

-- Rename the table
ALTER TABLE IF EXISTS public.biometria RENAME TO biometrias;

-- Update index name for consistency
DROP INDEX IF EXISTS public.idx_biometria_user_id;
CREATE INDEX IF NOT EXISTS idx_biometrias_user_id ON public.biometrias(user_id);

-- Update index on id_siembra if exists
DROP INDEX IF EXISTS public.idx_biometria_id_siembra;
CREATE INDEX IF NOT EXISTS idx_biometrias_id_siembra ON public.biometrias(id_siembra);

-- Update comment
COMMENT ON TABLE public.biometrias IS 'Biometric measurements for siembras with multi-tenant isolation';
COMMENT ON COLUMN public.biometrias.user_id IS 'Foreign key to auth.users for multi-tenant isolation';
