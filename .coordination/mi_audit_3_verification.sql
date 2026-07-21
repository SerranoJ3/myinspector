-- MI-AUDIT-3 verification — run as a single batch in Supabase SQL Editor.
-- Test row: 1b37d77c-1ab1-43d0-a006-0a1cbe0510bf (phase_submissions)
--   firm_id: d9b189a8-4ca4-41fb-aebd-2da1b9272f71
-- Pre-test chain head (captured 2026-05-05): id=1393, row_hash d9e39e64...
--
-- Expected NOTICEs on completion:
--   heartbeat=0  (heartbeat-only UPDATE produced no audit row)
--   notes_set=1  (real-state UPDATE produced exactly one audit row)
--   notes_revert=1  (revert UPDATE also produced one audit row)
-- Net change to test row after script: zero (notes back to NULL, last_client_sync_at moved forward).

DO $$
DECLARE
  v_test_row UUID := '1b37d77c-1ab1-43d0-a006-0a1cbe0510bf';
  v_baseline_max_id BIGINT;
  v_after_heartbeat_max_id BIGINT;
  v_after_notes_set_max_id BIGINT;
  v_after_notes_revert_max_id BIGINT;
  v_heartbeat_delta INT;
  v_notes_set_delta INT;
  v_notes_revert_delta INT;
BEGIN
  SELECT COALESCE(MAX(id), 0) INTO v_baseline_max_id FROM public.audit_log;
  RAISE NOTICE 'Baseline audit_log max id: %', v_baseline_max_id;

  -- Test 1: heartbeat-only UPDATE → expect 0 new audit rows.
  UPDATE public.phase_submissions
     SET last_client_sync_at = NOW()
   WHERE id = v_test_row;

  SELECT COALESCE(MAX(id), 0) INTO v_after_heartbeat_max_id FROM public.audit_log;
  v_heartbeat_delta := v_after_heartbeat_max_id - v_baseline_max_id;
  RAISE NOTICE 'After heartbeat UPDATE: max id = %, delta = % (expect 0)',
    v_after_heartbeat_max_id, v_heartbeat_delta;

  -- Test 2a: real-state UPDATE (notes SET) → expect 1 new audit row.
  UPDATE public.phase_submissions
     SET notes = 'MI-AUDIT-3 verification sentinel — REVERT'
   WHERE id = v_test_row;

  SELECT COALESCE(MAX(id), 0) INTO v_after_notes_set_max_id FROM public.audit_log;
  v_notes_set_delta := v_after_notes_set_max_id - v_after_heartbeat_max_id;
  RAISE NOTICE 'After notes SET: max id = %, delta = % (expect 1)',
    v_after_notes_set_max_id, v_notes_set_delta;

  -- Test 2b: revert notes → expect 1 new audit row.
  UPDATE public.phase_submissions
     SET notes = NULL
   WHERE id = v_test_row;

  SELECT COALESCE(MAX(id), 0) INTO v_after_notes_revert_max_id FROM public.audit_log;
  v_notes_revert_delta := v_after_notes_revert_max_id - v_after_notes_set_max_id;
  RAISE NOTICE 'After notes REVERT: max id = %, delta = % (expect 1)',
    v_after_notes_revert_max_id, v_notes_revert_delta;

  RAISE NOTICE 'SUMMARY: heartbeat=% (expect 0), notes_set=% (expect 1), notes_revert=% (expect 1)',
    v_heartbeat_delta, v_notes_set_delta, v_notes_revert_delta;
END $$;

-- Sanity check #1: confirm test row reverted to notes=NULL.
SELECT id, notes, last_client_sync_at
  FROM public.phase_submissions
 WHERE id = '1b37d77c-1ab1-43d0-a006-0a1cbe0510bf';

-- Sanity check #2: latest 5 audit rows with computed changed-key sets.
SELECT id, occurred_at, table_name, action, record_id,
       CASE WHEN old_data IS NOT NULL AND new_data IS NOT NULL
            THEN (SELECT array_agg(o.key)
                    FROM jsonb_each(old_data) o
                   WHERE o.value IS DISTINCT FROM (new_data -> o.key))
            ELSE NULL
       END AS changed_keys,
       row_hash, prev_hash
  FROM public.audit_log
 ORDER BY id DESC
 LIMIT 5;

-- Sanity check #3: compliance_events row from the migration marker.
SELECT id, occurred_at, event_type, severity, source, correlation_id, message
  FROM public.compliance_events
 WHERE correlation_id = 'MI-AUDIT-3'
 ORDER BY occurred_at DESC
 LIMIT 1;
