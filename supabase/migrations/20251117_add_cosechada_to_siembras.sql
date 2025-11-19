-- Add cosechada field to siembras table
-- This field indicates if a siembra has been harvested
-- When true, the siembra is inactive and the estanque is available for new siembras

ALTER TABLE siembras
ADD COLUMN IF NOT EXISTS cosechada BOOLEAN NOT NULL DEFAULT FALSE;

-- Create index for filtering active/harvested siembras
CREATE INDEX IF NOT EXISTS idx_siembras_cosechada ON siembras(cosechada);

-- Add comment
COMMENT ON COLUMN siembras.cosechada IS 'Indicates if the siembra has been harvested and is no longer active';
