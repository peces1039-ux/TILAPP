-- Migration: Fix infinite recursion in profiles RLS policies
-- Date: 2025-11-17
-- Issue: Policies on profiles table query profiles table causing recursion

-- Drop problematic policies that cause recursion
DROP POLICY IF EXISTS "Admins can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can soft-delete users" ON public.profiles;

-- Create helper function to check if current user is admin
-- This function uses SECURITY DEFINER to bypass RLS when checking role
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'admin'
    AND deleted_at IS NULL
  );
END;
$$;

-- Recreate admin policies using the helper function
CREATE POLICY "Admins can read all profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (public.is_admin());

CREATE POLICY "Admins can soft-delete users"
ON public.profiles FOR UPDATE
TO authenticated
USING (
  public.is_admin()
  AND id != auth.uid()
  AND role != 'admin'
)
WITH CHECK (
  public.is_admin()
  AND id != auth.uid()
  AND role != 'admin'
);
