-- Migration: Add indexes on user_id columns for performance optimization
-- Related: T109, Phase 12
-- Purpose: Improve query performance for multi-tenant data filtering
-- Date: 2025-11-16

-- Add index on profiles.id (which is user_id FK to auth.users)
CREATE INDEX IF NOT EXISTS idx_profiles_id ON public.profiles(id);

-- Add index on estanques.user_id
CREATE INDEX IF NOT EXISTS idx_estanques_user_id ON public.estanques(user_id);

-- Add index on siembras.user_id
CREATE INDEX IF NOT EXISTS idx_siembras_user_id ON public.siembras(user_id);

-- Add index on biometria.user_id
CREATE INDEX IF NOT EXISTS idx_biometria_user_id ON public.biometria(user_id);

-- Add index on muertes.user_id
CREATE INDEX IF NOT EXISTS idx_muertes_user_id ON public.muertes(user_id);

-- Add index on tablas_alimentacion.user_id
CREATE INDEX IF NOT EXISTS idx_tablas_alimentacion_user_id ON public.tablas_alimentacion(user_id);

-- Composite indexes for common query patterns

-- Estanques: filter by user_id and order by numero
CREATE INDEX IF NOT EXISTS idx_estanques_user_numero ON public.estanques(user_id, numero);

-- Siembras: filter by user_id and order by fecha descending
CREATE INDEX IF NOT EXISTS idx_siembras_user_fecha ON public.siembras(user_id, fecha DESC);

-- Siembras: filter by user_id and estanque_id (for estanque details screen)
CREATE INDEX IF NOT EXISTS idx_siembras_user_estanque ON public.siembras(user_id, estanque_id);

-- Biometria: filter by user_id and siembra_id, order by fecha descending
CREATE INDEX IF NOT EXISTS idx_biometria_user_siembra_fecha ON public.biometria(user_id, siembra_id, fecha DESC);

-- Muertes: filter by user_id and siembra_id, order by fecha descending
CREATE INDEX IF NOT EXISTS idx_muertes_user_siembra_fecha ON public.muertes(user_id, siembra_id, fecha DESC);

-- Tablas Alimentacion: filter by user_id and order by nombre
CREATE INDEX IF NOT EXISTS idx_tablas_user_nombre ON public.tablas_alimentacion(user_id, nombre);

-- Notes:
-- - All indexes use IF NOT EXISTS to be idempotent
-- - Composite indexes cover the most common query patterns in the application
-- - user_id is the first column in all composite indexes for efficient multi-tenant filtering
-- - DESC ordering on fecha columns matches the application's display order (newest first)
-- - These indexes significantly improve performance for:
--   * User-specific data retrieval (all screens)
--   * Estanque detail queries showing associated siembras
--   * Siembra detail queries showing biometrias and muertes
--   * List screens with sorting
