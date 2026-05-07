-- mi_demo_seed_14_swap_towns_to_non_njaw
--
-- Swap demo property towns from NJAW-served (Maplewood/Millburn/Short Hills)
-- to clearly non-NJAW NJ municipalities so the demo doesn't read as Jorge's
-- actual NJ6 contract footprint. Pick set:
--   - Hoboken (Veolia/Suez North Hudson)
--   - Jersey City (Suez)
--   - Bayonne (Suez Bayonne)
--   - Trenton (Trenton Water Works)
--
-- Sector enum NJAW_SHORT_HILLS retained on bb...0011 + bb...0012 because it's
-- a product role-inversion type, not a municipality. Sector enum cleanup is a
-- separate ticket. Towns are what prospects clock; sector is internal taxonomy.
--
-- Distribution after swap: 3/3/3/3 across the four target towns.

DO $$
DECLARE
  v_actor uuid; v_actor_email text;
BEGIN
  SELECT id, email INTO v_actor, v_actor_email
  FROM public.profiles WHERE email='demo-jorge@myinspector.io';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor::text, 'email', v_actor_email)::text, true);

  UPDATE public.properties SET city='Hoboken',     zip='07030' WHERE id='bbbbbbbb-0000-0000-0000-000000000001';
  UPDATE public.properties SET city='Jersey City', zip='07302' WHERE id='bbbbbbbb-0000-0000-0000-000000000002';
  UPDATE public.properties SET city='Hoboken',     zip='07030' WHERE id='bbbbbbbb-0000-0000-0000-000000000003';
  UPDATE public.properties SET city='Bayonne',     zip='07002' WHERE id='bbbbbbbb-0000-0000-0000-000000000004';
  UPDATE public.properties SET city='Trenton',     zip='08608' WHERE id='bbbbbbbb-0000-0000-0000-000000000005';
  UPDATE public.properties SET city='Jersey City', zip='07310' WHERE id='bbbbbbbb-0000-0000-0000-000000000006';
  UPDATE public.properties SET city='Bayonne',     zip='07002' WHERE id='bbbbbbbb-0000-0000-0000-000000000007';
  UPDATE public.properties SET city='Trenton',     zip='08611' WHERE id='bbbbbbbb-0000-0000-0000-000000000008';
  UPDATE public.properties SET city='Hoboken',     zip='07030' WHERE id='bbbbbbbb-0000-0000-0000-000000000009';
  UPDATE public.properties SET city='Jersey City', zip='07302' WHERE id='bbbbbbbb-0000-0000-0000-000000000010';
  UPDATE public.properties SET city='Trenton',     zip='08608' WHERE id='bbbbbbbb-0000-0000-0000-000000000011';
  UPDATE public.properties SET city='Bayonne',     zip='07002' WHERE id='bbbbbbbb-0000-0000-0000-000000000012';
END $$;
