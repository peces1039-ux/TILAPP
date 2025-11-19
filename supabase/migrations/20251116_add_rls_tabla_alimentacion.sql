-- Migration: Add RLS policies to tabla_alimentacion
-- Purpose: Allow all authenticated users to read, only admins to write
-- Date: 2025-11-16

-- Enable RLS on tabla_alimentacion
ALTER TABLE tabla_alimentacion ENABLE ROW LEVEL SECURITY;

-- Policy 1: All authenticated users can SELECT (read access for calculations)
CREATE POLICY "tabla_alimentacion_select_policy"
ON tabla_alimentacion
FOR SELECT
TO authenticated
USING (true);

-- Policy 2: Only admin users can INSERT
CREATE POLICY "tabla_alimentacion_insert_policy"
ON tabla_alimentacion
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
    AND profiles.deleted_at IS NULL
  )
);

-- Policy 3: Only admin users can UPDATE
CREATE POLICY "tabla_alimentacion_update_policy"
ON tabla_alimentacion
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
    AND profiles.deleted_at IS NULL
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
    AND profiles.deleted_at IS NULL
  )
);

-- Policy 4: Only admin users can DELETE
CREATE POLICY "tabla_alimentacion_delete_policy"
ON tabla_alimentacion
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
    AND profiles.deleted_at IS NULL
  )
);

-- Add comment explaining the security model
COMMENT ON TABLE tabla_alimentacion IS 'Shared feeding schedule reference data. RLS enforced: SELECT = all authenticated users, INSERT/UPDATE/DELETE = admin only';
