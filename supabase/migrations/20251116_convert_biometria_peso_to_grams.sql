-- Migration: Convert biometria peso from kg to grams
-- Purpose: Standardize all weight measurements to grams for consistency
-- Date: 2025-11-16

-- Add new column for peso in grams
ALTER TABLE biometrias ADD COLUMN peso_promedio_gramos NUMERIC;

-- Convert existing data from kg to grams (multiply by 1000)
UPDATE biometrias SET peso_promedio_gramos = peso * 1000 WHERE peso IS NOT NULL;

-- Drop old peso column (was in kg)
ALTER TABLE biometrias DROP COLUMN peso;

-- Rename new column to peso_promedio
ALTER TABLE biometrias RENAME COLUMN peso_promedio_gramos TO peso_promedio;

-- Add constraint to ensure peso_promedio is positive
ALTER TABLE biometrias ADD CONSTRAINT check_peso_promedio_positive CHECK (peso_promedio >= 0);

-- Update column comment
COMMENT ON COLUMN biometrias.peso_promedio IS 'Average fish weight in grams (converted from kg)';
