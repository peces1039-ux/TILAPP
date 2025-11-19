-- Migration: Create profiles table for multi-tenancy user management
-- Date: 2025-11-16
-- Related: T005, FR-026 to FR-031

-- Create enum type for user roles
CREATE TYPE user_role AS ENUM ('admin', 'user');

-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'user',
  nombre TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL
);

-- Create index for soft-delete queries
CREATE INDEX idx_profiles_deleted_at ON public.profiles(deleted_at);

-- Add comment for documentation
COMMENT ON TABLE public.profiles IS 'User profiles with role and soft-delete support for multi-tenancy';
COMMENT ON COLUMN public.profiles.id IS 'Foreign key to auth.users(id)';
COMMENT ON COLUMN public.profiles.role IS 'User role: admin or user';
COMMENT ON COLUMN public.profiles.deleted_at IS 'Soft-delete timestamp (30 days retention before permanent deletion)';
