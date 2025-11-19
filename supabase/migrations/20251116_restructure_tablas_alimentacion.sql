-- Migration: Restructure tablas_alimentacion table with new feeding schedule columns
-- Date: 2025-11-16
-- Related: T010

-- Drop old columns
ALTER TABLE public.tablas_alimentacion
DROP COLUMN IF EXISTS nombre,
DROP COLUMN IF EXISTS peso_min,
DROP COLUMN IF EXISTS peso_max,
DROP COLUMN IF EXISTS porcentaje_alimentacion,
DROP COLUMN IF EXISTS frecuencia_diaria;

-- Add new columns
ALTER TABLE public.tablas_alimentacion
ADD COLUMN edad_semanas INTEGER NOT NULL CHECK (edad_semanas > 0),
ADD COLUMN peso_min_gramos NUMERIC NOT NULL CHECK (peso_min_gramos >= 0),
ADD COLUMN peso_max_gramos NUMERIC NOT NULL CHECK (peso_max_gramos >= 0),
ADD COLUMN porcentaje_biomasa NUMERIC NOT NULL CHECK (porcentaje_biomasa > 0 AND porcentaje_biomasa <= 100),
ADD COLUMN referencia_alimento TEXT NOT NULL,
ADD COLUMN raciones_diarias INTEGER NOT NULL CHECK (raciones_diarias > 0);

-- Add check constraint to ensure peso_max >= peso_min
ALTER TABLE public.tablas_alimentacion
ADD CONSTRAINT check_peso_range CHECK (peso_max_gramos >= peso_min_gramos);

-- Update table comment
COMMENT ON TABLE public.tablas_alimentacion IS 'Feeding schedule reference data by age and weight ranges';

-- Update column comments
COMMENT ON COLUMN public.tablas_alimentacion.edad_semanas IS 'Age in weeks for this feeding schedule';
COMMENT ON COLUMN public.tablas_alimentacion.peso_min_gramos IS 'Minimum fish weight in grams';
COMMENT ON COLUMN public.tablas_alimentacion.peso_max_gramos IS 'Maximum fish weight in grams';
COMMENT ON COLUMN public.tablas_alimentacion.porcentaje_biomasa IS 'Percentage of biomass to feed per day';
COMMENT ON COLUMN public.tablas_alimentacion.referencia_alimento IS 'Feed reference (Mojarra 45 Harina, Mojarra 45 Extruder, Mojarra 38, Mojarra 32 - 3.5 mm, Mojarra 32 - 4.5 mm, Mojarra 24)';
COMMENT ON COLUMN public.tablas_alimentacion.raciones_diarias IS 'Number of daily rations';
