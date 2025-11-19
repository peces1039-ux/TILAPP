-- Migration: Add calculation fields to biometrias table
-- Related: Biometrics calculations feature
-- Date: 2025-11-16

-- Add biomasa_total column (total biomass in kg)
-- Calculated as: peso_promedio (in grams) * cantidad_actual_peces / 1000
ALTER TABLE biometrias ADD COLUMN biomasa_total NUMERIC;

-- Add cantidad_alimento_diario column (daily food amount in kg)
-- Calculated as: cantidad_actual_peces * porcentaje_biomasa * peso_promedio / 1000
ALTER TABLE biometrias ADD COLUMN cantidad_alimento_diario NUMERIC;

-- Add fca column (Feed Conversion Ratio - Factor de Conversión Alimenticia)
-- Nullable because first biometry won't have FCA
-- Calculated as: alimento_suministrado / aumento_biomasa (comparing with previous biometry)
ALTER TABLE biometrias ADD COLUMN fca NUMERIC;

-- Add alimento_acumulado column (accumulated food supplied in kg)
-- Used for FCA calculation
ALTER TABLE biometrias ADD COLUMN alimento_acumulado NUMERIC DEFAULT 0;

-- Add comments for documentation
COMMENT ON COLUMN biometrias.biomasa_total IS 'Total biomass in kg (peso_promedio * cantidad_actual / 1000)';
COMMENT ON COLUMN biometrias.cantidad_alimento_diario IS 'Daily food amount in kg';
COMMENT ON COLUMN biometrias.fca IS 'Feed Conversion Ratio (FCR) - null for first biometry';
COMMENT ON COLUMN biometrias.alimento_acumulado IS 'Accumulated food supplied in kg since previous biometry';

-- Add constraints
ALTER TABLE biometrias ADD CONSTRAINT check_biomasa_total_positive CHECK (biomasa_total >= 0);
ALTER TABLE biometrias ADD CONSTRAINT check_cantidad_alimento_positive CHECK (cantidad_alimento_diario >= 0);
ALTER TABLE biometrias ADD CONSTRAINT check_fca_positive CHECK (fca IS NULL OR fca >= 0);
ALTER TABLE biometrias ADD CONSTRAINT check_alimento_acumulado_positive CHECK (alimento_acumulado >= 0);
