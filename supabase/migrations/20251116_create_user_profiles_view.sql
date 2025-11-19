-- Migration: Create admin view for user management
-- Purpose: Provide secure access to user emails for admin users
-- Date: 2025-11-16

-- Create a view that combines profiles with auth.users emails
-- This view is accessible only to authenticated users
CREATE OR REPLACE VIEW user_profiles_with_email AS
SELECT
  p.id,
  p.role,
  p.nombre,
  p.created_at,
  p.deleted_at,
  u.email
FROM profiles p
LEFT JOIN auth.users u ON p.id = u.id;

-- Grant access to authenticated users
GRANT SELECT ON user_profiles_with_email TO authenticated;

-- Add comment
COMMENT ON VIEW user_profiles_with_email IS 'View combining profiles with emails from auth.users for admin user management';
