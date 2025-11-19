-- Migration: Drop legacy perfil_usuario table
-- Date: 2025-11-16
-- Purpose: Remove obsolete perfil_usuario table from pre-refactor system
-- The project now uses 'profiles' table with role enum and soft-delete support

-- Drop RLS policies first
DROP POLICY IF EXISTS "Users can view own profile" ON public.perfil_usuario;
DROP POLICY IF EXISTS "Users can update own profile" ON public.perfil_usuario;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.perfil_usuario;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.perfil_usuario;
DROP POLICY IF EXISTS "Enable update for users based on email" ON public.perfil_usuario;

-- Drop triggers if any
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_perfil_usuario_updated_at ON public.perfil_usuario;

-- Drop functions associated with perfil_usuario
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.create_profile_for_new_user() CASCADE;

-- Drop the table
DROP TABLE IF EXISTS public.perfil_usuario CASCADE;

-- Verify profiles table exists and is being used
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'profiles'
  ) THEN
    RAISE EXCEPTION 'profiles table does not exist. Cannot drop perfil_usuario safely.';
  END IF;
END $$;

COMMENT ON TABLE public.profiles IS 'Active user profiles table with role enum and soft-delete support (replaces legacy perfil_usuario)';
