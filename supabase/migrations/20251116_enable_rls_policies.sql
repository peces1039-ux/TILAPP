-- Migration: Enable Row Level Security (RLS) policies for multi-tenancy
-- Date: 2025-11-16
-- Related: T011, FR-034, FR-035, SC-004

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estanques ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.siembras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.biometria ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.muertes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tablas_alimentacion ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- PROFILES TABLE POLICIES
-- =============================================================================

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
ON public.profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Users can update their own profile (nombre only)
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Users can soft-delete their own account (set deleted_at)
CREATE POLICY "Users can soft-delete own account"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id AND deleted_at IS NULL)
WITH CHECK (auth.uid() = id);

-- Admins can read all profiles
CREATE POLICY "Admins can read all profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Admins can soft-delete other users (not themselves, not other admins)
CREATE POLICY "Admins can soft-delete users"
ON public.profiles FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
  AND id != auth.uid()
  AND role != 'admin'
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- =============================================================================
-- ESTANQUES TABLE POLICIES
-- =============================================================================

-- Users can read their own estanques
CREATE POLICY "Users can read own estanques"
ON public.estanques FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can create their own estanques
CREATE POLICY "Users can create own estanques"
ON public.estanques FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own estanques
CREATE POLICY "Users can update own estanques"
ON public.estanques FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own estanques
CREATE POLICY "Users can delete own estanques"
ON public.estanques FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- =============================================================================
-- SIEMBRAS TABLE POLICIES
-- =============================================================================

-- Users can read their own siembras
CREATE POLICY "Users can read own siembras"
ON public.siembras FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can create their own siembras
CREATE POLICY "Users can create own siembras"
ON public.siembras FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own siembras
CREATE POLICY "Users can update own siembras"
ON public.siembras FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own siembras
CREATE POLICY "Users can delete own siembras"
ON public.siembras FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- =============================================================================
-- BIOMETRIA TABLE POLICIES
-- =============================================================================

-- Users can read their own biometria records
CREATE POLICY "Users can read own biometria"
ON public.biometria FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can create their own biometria records
CREATE POLICY "Users can create own biometria"
ON public.biometria FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own biometria records
CREATE POLICY "Users can update own biometria"
ON public.biometria FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own biometria records
CREATE POLICY "Users can delete own biometria"
ON public.biometria FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- =============================================================================
-- MUERTES TABLE POLICIES
-- =============================================================================

-- Users can read their own muertes records
CREATE POLICY "Users can read own muertes"
ON public.muertes FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can create their own muertes records
CREATE POLICY "Users can create own muertes"
ON public.muertes FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own muertes records
CREATE POLICY "Users can update own muertes"
ON public.muertes FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own muertes records
CREATE POLICY "Users can delete own muertes"
ON public.muertes FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- =============================================================================
-- TABLAS_ALIMENTACION TABLE POLICIES
-- =============================================================================

-- Users can read their own tablas_alimentacion
CREATE POLICY "Users can read own tablas_alimentacion"
ON public.tablas_alimentacion FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can create their own tablas_alimentacion
CREATE POLICY "Users can create own tablas_alimentacion"
ON public.tablas_alimentacion FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own tablas_alimentacion
CREATE POLICY "Users can update own tablas_alimentacion"
ON public.tablas_alimentacion FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own tablas_alimentacion
CREATE POLICY "Users can delete own tablas_alimentacion"
ON public.tablas_alimentacion FOR DELETE
TO authenticated
USING (user_id = auth.uid());
