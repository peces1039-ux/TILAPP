-- Migration: Create muertes table for tracking fish deaths
-- Date: 2025-11-16
-- Related: T009, FR-020 to FR-022

CREATE TABLE IF NOT EXISTS public.muertes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  siembra_id UUID NOT NULL REFERENCES public.siembras(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  cantidad INTEGER NOT NULL CHECK (cantidad > 0),
  observaciones TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_muertes_user_id ON public.muertes(user_id);
CREATE INDEX IF NOT EXISTS idx_muertes_siembra_id ON public.muertes(siembra_id);
CREATE INDEX IF NOT EXISTS idx_muertes_fecha ON public.muertes(fecha DESC);

-- Add comments for documentation
COMMENT ON TABLE public.muertes IS 'Fish death records per siembra for mortality tracking';
COMMENT ON COLUMN public.muertes.user_id IS 'Foreign key to auth.users for multi-tenant isolation';
COMMENT ON COLUMN public.muertes.siembra_id IS 'Foreign key to siembras - which siembra the deaths belong to';
COMMENT ON COLUMN public.muertes.cantidad IS 'Number of fish that died (must be > 0)';
COMMENT ON COLUMN public.muertes.observaciones IS 'Optional notes about cause or circumstances of deaths';
