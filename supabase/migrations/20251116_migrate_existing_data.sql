-- Migration: Migrate existing data to first user
-- Date: 2025-11-16
-- Related: T012, FR-031
-- NOTE: This assumes there is at least one user in auth.users

DO $$
DECLARE
  first_user_id UUID;
BEGIN
  -- Get the first user from auth.users (ordered by created_at)
  SELECT id INTO first_user_id
  FROM auth.users
  ORDER BY created_at ASC
  LIMIT 1;

  -- Check if we found a user
  IF first_user_id IS NULL THEN
    RAISE EXCEPTION 'No users found in auth.users. Please create at least one user before running this migration.';
  END IF;

  -- Log the user being used
  RAISE NOTICE 'Migrating existing data to user_id: %', first_user_id;

  -- Update estanques table
  UPDATE public.estanques
  SET user_id = first_user_id
  WHERE user_id IS NULL;

  RAISE NOTICE 'Updated % estanques records', (SELECT COUNT(*) FROM public.estanques WHERE user_id = first_user_id);

  -- Update siembras table
  UPDATE public.siembras
  SET user_id = first_user_id
  WHERE user_id IS NULL;

  RAISE NOTICE 'Updated % siembras records', (SELECT COUNT(*) FROM public.siembras WHERE user_id = first_user_id);

  -- Update biometria table
  UPDATE public.biometria
  SET user_id = first_user_id
  WHERE user_id IS NULL;

  RAISE NOTICE 'Updated % biometria records', (SELECT COUNT(*) FROM public.biometria WHERE user_id = first_user_id);

  -- Create profile for first user if it doesn't exist
  INSERT INTO public.profiles (id, role, nombre, created_at)
  VALUES (first_user_id, 'user', 'Usuario Principal', NOW())
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Migration complete. All existing data assigned to user: %', first_user_id;

END $$;

-- Make user_id columns NOT NULL after migration
ALTER TABLE public.estanques ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.siembras ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.biometria ALTER COLUMN user_id SET NOT NULL;
