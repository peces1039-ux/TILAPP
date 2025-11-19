-- Seed Script: Create first admin user in profiles table
-- Date: 2025-11-16
-- Related: T013, FR-056
-- NOTE: This script should be run manually by DevOps/Development team
--       The admin role must be assigned to an existing auth.users record

-- INSTRUCTIONS:
-- 1. Replace 'REPLACE_WITH_AUTH_USER_ID' with the actual UUID from auth.users
-- 2. Replace 'Admin User' with the desired admin name
-- 3. Run this script after the user has been created in Supabase Auth

-- Example usage:
-- First, create a user via Supabase Auth UI or API
-- Then, get their user ID and run this script

INSERT INTO public.profiles (id, role, nombre, created_at)
VALUES (
  'REPLACE_WITH_AUTH_USER_ID'::UUID,  -- Replace with actual auth.users.id
  'admin',
  'Admin User',                        -- Replace with actual admin name
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET role = 'admin',
    nombre = EXCLUDED.nombre;

-- Verify the admin was created
SELECT id, role, nombre, created_at
FROM public.profiles
WHERE role = 'admin';

-- Example with actual UUID (commented out):
-- INSERT INTO public.profiles (id, role, nombre, created_at)
-- VALUES (
--   '12345678-1234-5678-1234-567812345678'::UUID,
--   'admin',
--   'John Doe',
--   NOW()
-- )
-- ON CONFLICT (id) DO UPDATE
-- SET role = 'admin',
--     nombre = EXCLUDED.nombre;
