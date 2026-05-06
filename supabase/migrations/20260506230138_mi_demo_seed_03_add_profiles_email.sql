-- mi_demo_seed_03_add_profiles_email
--
-- Adds email column to public.profiles + backfills from auth.users.
-- Required by spec §7 and migrations 05-13 which lookup profiles by email.
-- CC's draft (MI-DEMO_seed_spec_2026-05-06.md §7) assumed this column existed;
-- it did not. Buddy added it as a separate step before the seed user creation.
--
-- Schema impact: 1 new nullable text column. No constraint added (auth.users.email
-- is the unique source of truth; profiles.email is a denormalized convenience for
-- the seed migrations' email-based lookups). Future ticket can add a sync trigger
-- if desired.

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email text;

UPDATE public.profiles p
   SET email = au.email
  FROM auth.users au
 WHERE au.id = p.id AND p.email IS NULL;
