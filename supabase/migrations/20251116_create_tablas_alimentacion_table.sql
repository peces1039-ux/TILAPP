-- Migration: Create tablas_alimentacion table for feeding reference data
-- Date: 2025-11-16
-- Related: T010, FR-023 to FR-025
-- NOTE: This is independent reference data with NO foreign keys to other entities

CREATE TABLE IF NOT EXISTS public.tablas_alimentacion (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  peso_min DECIMAL(10,2) NOT NULL CHECK (peso_min >= 0),
  peso_max DECIMAL(10,2) NOT NULL CHECK (peso_max > peso_min),
  porcentaje_alimentacion DECIMAL(5,2) NOT NULL CHECK (porcentaje_alimentacion > 0 AND porcentaje_alimentacion <= 100),
  frecuencia_diaria INTEGER NOT NULL CHECK (frecuencia_diaria > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for performance on user_id queries
CREATE INDEX IF NOT EXISTS idx_tablas_alimentacion_user_id ON public.tablas_alimentacion(user_id);

-- Create index for weight range queries
CREATE INDEX IF NOT EXISTS idx_tablas_alimentacion_peso_range ON public.tablas_alimentacion(peso_min, peso_max);

-- Add comments for documentation
COMMENT ON TABLE public.tablas_alimentacion IS 'Reference data for feeding calculations. Independent reference data with NO foreign keys to other entities (used for calculations only)';
COMMENT ON COLUMN public.tablas_alimentacion.user_id IS 'Foreign key to auth.users for multi-tenant isolation';
COMMENT ON COLUMN public.tablas_alimentacion.nombre IS 'Name/label for this feeding table';
COMMENT ON COLUMN public.tablas_alimentacion.peso_min IS 'Minimum fish weight (kg) for this feeding rate';
COMMENT ON COLUMN public.tablas_alimentacion.peso_max IS 'Maximum fish weight (kg) for this feeding rate';
COMMENT ON COLUMN public.tablas_alimentacion.porcentaje_alimentacion IS 'Percentage of body weight to feed per day';
COMMENT ON COLUMN public.tablas_alimentacion.frecuencia_diaria IS 'Number of feedings per day';
