-- Migration: Make tabla_alimentacion a shared table (no multi-tenancy)
-- Date: 2025-11-16
-- Related: T010

-- Rename table to singular form
ALTER TABLE IF EXISTS public.tablas_alimentacion
RENAME TO tabla_alimentacion;

-- Drop RLS policies (try different possible names)
DROP POLICY IF EXISTS "Users can view their own tablas_alimentacion" ON public.tabla_alimentacion;
DROP POLICY IF EXISTS "Users can insert their own tablas_alimentacion" ON public.tabla_alimentacion;
DROP POLICY IF EXISTS "Users can update their own tablas_alimentacion" ON public.tabla_alimentacion;
DROP POLICY IF EXISTS "Users can delete their own tablas_alimentacion" ON public.tabla_alimentacion;
DROP POLICY IF EXISTS "Users can read own tablas_alimentacion" ON public.tabla_alimentacion;
DROP POLICY IF EXISTS "Users can create own tablas_alimentacion" ON public.tabla_alimentacion;
DROP POLICY IF EXISTS "Users can update own tablas_alimentacion" ON public.tabla_alimentacion;
DROP POLICY IF EXISTS "Users can delete own tablas_alimentacion" ON public.tabla_alimentacion;

-- Disable RLS (this table is shared across all users)
ALTER TABLE public.tabla_alimentacion DISABLE ROW LEVEL SECURITY;

-- Drop user_id column and its foreign key constraint (CASCADE to drop policies)
ALTER TABLE public.tabla_alimentacion
DROP CONSTRAINT IF EXISTS tablas_alimentacion_user_id_fkey CASCADE;

ALTER TABLE public.tabla_alimentacion
DROP COLUMN IF EXISTS user_id CASCADE;

-- Update table comment
COMMENT ON TABLE public.tabla_alimentacion IS 'Shared feeding schedule reference data accessible by all users (no multi-tenancy)';

-- Drop user_id index if it exists
DROP INDEX IF EXISTS idx_tablas_alimentacion_user_id;
