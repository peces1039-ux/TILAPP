-- Add performance indexes on user_id columns
-- Related: T109, Phase 12
-- Purpose: Optimize query performance for multi-tenant filtering

-- Estanques table index
CREATE INDEX IF NOT EXISTS idx_estanques_user_id
ON estanques(user_id);

-- Siembras table index
CREATE INDEX IF NOT EXISTS idx_siembras_user_id
ON siembras(user_id);

-- Biometria table index
CREATE INDEX IF NOT EXISTS idx_biometria_user_id
ON biometria(user_id);

-- Muertes table index
CREATE INDEX IF NOT EXISTS idx_muertes_user_id
ON muertes(user_id);

-- Tablas alimentacion index
CREATE INDEX IF NOT EXISTS idx_tablas_alimentacion_user_id
ON tablas_alimentacion(user_id);

-- Profiles table index (for admin queries)
CREATE INDEX IF NOT EXISTS idx_profiles_role
ON profiles(role);

-- Composite index for siembras filtering (user_id + id_estanque)
CREATE INDEX IF NOT EXISTS idx_siembras_user_estanque
ON siembras(user_id, id_estanque);

-- Composite index for biometria filtering (user_id + id_siembra)
CREATE INDEX IF NOT EXISTS idx_biometria_user_siembra
ON biometria(user_id, id_siembra);

-- Composite index for muertes filtering (user_id + siembra_id)
CREATE INDEX IF NOT EXISTS idx_muertes_user_siembra
ON muertes(user_id, siembra_id);

COMMENT ON INDEX idx_estanques_user_id IS 'Performance optimization for user-specific estanques queries';
COMMENT ON INDEX idx_siembras_user_id IS 'Performance optimization for user-specific siembras queries';
COMMENT ON INDEX idx_biometria_user_id IS 'Performance optimization for user-specific biometria queries';
COMMENT ON INDEX idx_muertes_user_id IS 'Performance optimization for user-specific muertes queries';
COMMENT ON INDEX idx_tablas_alimentacion_user_id IS 'Performance optimization for user-specific tablas queries';
COMMENT ON INDEX idx_profiles_role IS 'Performance optimization for admin role checks';
