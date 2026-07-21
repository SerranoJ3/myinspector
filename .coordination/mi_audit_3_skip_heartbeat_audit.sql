-- MI-AUDIT-3: Skip audit_log INSERT for heartbeat-only UPDATEs.
--
-- Applied via Supabase MCP apply_migration: 2026-05-05 ~22:00 EDT
-- Migration name: mi_audit_3_skip_heartbeat_audit
-- Project: wryitfoletwskkdqqwcw (myinspector prod)
-- Applied by: Buddy (direct write-mode access; CC was blocked on read-only)
--
-- Background: 916 of 1101 audit_log rows over the last 30 days (83%) are
-- UPDATEs whose only delta is last_client_sync_at — a client-side heartbeat
-- field, not a deliberate state change. This pollutes audit_log and makes
-- compliance review interpretability worse.
--
-- Approach A (per Q-AUDIT-3-a locked 2026-05-05 evening): trigger filter.
-- Compare OLD vs NEW jsonb, find changed keys; if changed-keys set is
-- non-empty AND a subset of the heartbeat whitelist, RETURN NEW without
-- INSERTing into audit_log.
--
-- Whitelist (locked from schema introspection 2026-05-05 21:55 EDT — only
-- last_client_sync_at exists across schema; suggested candidates
-- last_seen_at, client_session_id, device_metadata, last_active_at do not
-- exist on any table):
--   {last_client_sync_at}
--
-- Hash chain trigger and INSERT/DELETE branches are untouched. Function
-- remains SECURITY DEFINER with same search_path. firm_id resolution
-- logic preserved verbatim.
--
-- Verification (2026-05-05 ~22:05 EDT, Buddy direct):
-- - Function body verified: contains v_heartbeat_whitelist, RETURN NEW skip,
--   MI-AUDIT-3 marker.
-- - Pre-test baseline: 1101 audit rows, max id 1393, chain head
--   d9e39e64845db56920415367337c62626a76c74e83e2143bc41a7477b64bedf8.
-- - TEST 1 (heartbeat-only UPDATE on phase_submissions row
--   72183028-7d4f-4ad5-a35f-7a7a222d2dee, last_client_sync_at = NOW()):
--   PASS — audit_log delta = 0. Heartbeat skip filter works.
-- - TEST 2 (real-state UPDATE on same row, notes field set):
--   PASS — audit_log delta = 1. New chain head:
--   fd537e792c6a279dc187b02b68250e5c8d3bad149b655c6d024dcf83ac5e280c.
--   prev_hash on new row links correctly to pre-test chain head
--   d9e39e64...; hash chain integrity intact.

CREATE OR REPLACE FUNCTION public.write_audit_log()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $func$
DECLARE
  v_actor_id UUID;
  v_actor_email TEXT;
  v_firm_id UUID;
  v_record_id TEXT;
  v_old_data JSONB;
  v_new_data JSONB;
  v_changed_keys TEXT[];
  v_heartbeat_whitelist TEXT[] := ARRAY['last_client_sync_at'];
BEGIN
  -- Capture actor identity from auth context
  v_actor_id := auth.uid();
  BEGIN
    v_actor_email := (auth.jwt() ->> 'email')::TEXT;
  EXCEPTION WHEN OTHERS THEN
    v_actor_email := NULL;
  END;

  -- Determine record_id and firm_id based on operation type
  IF TG_OP = 'DELETE' THEN
    v_record_id := OLD.id::TEXT;
    v_old_data := to_jsonb(OLD);
    v_new_data := NULL;
    BEGIN
      v_firm_id := (to_jsonb(OLD) ->> 'firm_id')::UUID;
    EXCEPTION WHEN OTHERS THEN
      v_firm_id := NULL;
    END;

  ELSIF TG_OP = 'UPDATE' THEN
    v_record_id := NEW.id::TEXT;
    v_old_data := to_jsonb(OLD);
    v_new_data := to_jsonb(NEW);
    BEGIN
      v_firm_id := (to_jsonb(NEW) ->> 'firm_id')::UUID;
    EXCEPTION WHEN OTHERS THEN
      v_firm_id := NULL;
    END;

    -- MI-AUDIT-3: compute changed keys (union of OLD and NEW key sets,
    -- filtered to those whose values differ)
    SELECT array_agg(DISTINCT key) INTO v_changed_keys
    FROM (
      SELECT key FROM jsonb_each(v_old_data) AS o(key, value)
      WHERE v_old_data->key IS DISTINCT FROM v_new_data->key
      UNION
      SELECT key FROM jsonb_each(v_new_data) AS n(key, value)
      WHERE v_new_data->key IS DISTINCT FROM v_old_data->key
    ) AS combined;

    -- Skip audit if changed keys are a non-empty subset of the heartbeat
    -- whitelist. Defensive: if v_changed_keys is NULL or empty (degenerate
    -- UPDATE with no delta), fall through to normal audit behavior.
    IF v_changed_keys IS NOT NULL
       AND array_length(v_changed_keys, 1) > 0
       AND v_changed_keys <@ v_heartbeat_whitelist
    THEN
      RETURN NEW;
    END IF;

  ELSIF TG_OP = 'INSERT' THEN
    v_record_id := NEW.id::TEXT;
    v_old_data := NULL;
    v_new_data := to_jsonb(NEW);
    BEGIN
      v_firm_id := (to_jsonb(NEW) ->> 'firm_id')::UUID;
    EXCEPTION WHEN OTHERS THEN
      v_firm_id := NULL;
    END;
  END IF;

  -- Fallback: if firm_id wasn't on the row, look it up from the actor's profile
  IF v_firm_id IS NULL AND v_actor_id IS NOT NULL THEN
    SELECT firm_id INTO v_firm_id
    FROM public.profiles
    WHERE id = v_actor_id;
  END IF;

  -- Insert the audit row (hash chain trigger fires automatically)
  INSERT INTO public.audit_log (
    actor_id,
    actor_email,
    firm_id,
    table_name,
    record_id,
    action,
    old_data,
    new_data,
    row_hash,
    prev_hash
  )
  VALUES (
    v_actor_id,
    v_actor_email,
    v_firm_id,
    TG_TABLE_NAME,
    v_record_id,
    TG_OP,
    v_old_data,
    v_new_data,
    'PENDING',
    'PENDING'
  );

  -- Return appropriate row for trigger continuation
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$func$;

COMMENT ON FUNCTION public.write_audit_log() IS
  'MI-AUDIT-3 (2026-05-05): UPDATE branch now skips audit_log INSERT when the only delta is in heartbeat whitelist {last_client_sync_at}. Eliminates 83% baseline audit noise. INSERT/DELETE branches untouched. Hash chain trigger untouched. SECURITY DEFINER + search_path preserved.';
