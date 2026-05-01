// MI-109: CS Replacement Authorization Gate (CDM-Smith rule c, NO EXCEPTION)
//
// Endpoint: POST /functions/v1/cs-auth-submit
//
// Body:
//   {
//     submission_id: string (uuid, required),
//     result: 'authorize' | 'cancel' (required),
//     supervisor_name?: string,    // required when result='authorize'
//     authorized_date?: string,    // YYYY-MM-DD, required when result='authorize'
//     authorized_time?: string,    // HH:MM or HH:MM:SS, required when result='authorize'
//     reason?: string              // >=20 chars trimmed, required when result='authorize'
//   }
//
// Behavior:
//   - 'cancel'    -> writes audit_log row event_type='cs_auth_rejected',
//                    reason_code='inspector_cancelled'. Returns 200 {logged:true}.
//   - 'authorize' validation fail -> writes audit_log row event_type='cs_auth_rejected',
//                                    reason_code='validation_failure'. Returns 400.
//   - 'authorize' validation pass -> inserts into cs_replacement_authorizations.
//                                    AFTER INSERT trigger writes 'cs_auth_accepted'
//                                    audit row + extends SHA-256 hash chain.
//                                    Returns 200 { authorization_id }.

// deno-lint-ignore-file no-explicit-any
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

interface RejectionPayload {
  submission_id: string | null;
  user_id: string | null;
  failed_field?: string;
  detail?: string;
}

async function logRejection(
  serviceClient: ReturnType<typeof createClient>,
  reasonCode: 'inspector_cancelled' | 'validation_failure',
  firmId: string | null,
  actorId: string | null,
  submissionId: string | null,
  extra: RejectionPayload,
): Promise<void> {
  // Direct audit_log write (no insert into cs_replacement_authorizations,
  // so the AFTER INSERT trigger does NOT fire — we hand-write the chain row).
  // We rely on a server-side helper if MI-202 shipped one; otherwise we
  // pass minimal columns and let DB defaults fill the hash chain. If the
  // live audit_log schema requires prev_hash / current_hash to be supplied
  // by the caller, an RPC like audit_log_append(reason_code, payload, ...)
  // should be used instead — see ASSUMES note at top of migration.
  const payload = {
    submission_id: submissionId,
    user_id: actorId,
    reason_code: reasonCode,
    ...extra,
  };

  // Preferred path: an RPC that handles hash-chain bookkeeping atomically.
  // If this RPC does not exist on the live DB, fall back to direct insert
  // and let MI-202's BEFORE INSERT trigger (if any) compute the hash.
  const { error: rpcError } = await serviceClient.rpc('audit_log_append', {
    p_event_type: 'cs_auth_rejected',
    p_table_name: 'cs_replacement_authorizations',
    p_row_id: null,
    p_firm_id: firmId,
    p_actor_id: actorId,
    p_payload: payload,
  });

  if (!rpcError) return;

  // Fallback: direct insert. MI-202 may have a BEFORE INSERT trigger on
  // audit_log that fills prev_hash/current_hash; if not, this insert will
  // fail and surface in logs so Jorge can wire the helper up.
  const { error: insertError } = await serviceClient.from('audit_log').insert({
    event_type: 'cs_auth_rejected',
    table_name: 'cs_replacement_authorizations',
    row_id: null,
    firm_id: firmId,
    actor_id: actorId,
    payload,
  });

  if (insertError) {
    console.error('[cs-auth-submit] audit_log rejection write failed:', insertError);
    throw insertError;
  }
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  // ---- Auth: validate JWT ----
  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.toLowerCase().startsWith('bearer ')) {
    return jsonResponse({ error: 'missing_authorization' }, 401);
  }
  const jwt = authHeader.slice(7).trim();
  if (!jwt) {
    return jsonResponse({ error: 'missing_authorization' }, 401);
  }

  // User-scoped client (RLS-aware) — used to confirm identity + firm.
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userErr } = await userClient.auth.getUser(jwt);
  if (userErr || !userData?.user) {
    return jsonResponse({ error: 'invalid_token' }, 401);
  }
  const userId = userData.user.id;

  // Service-role client — used for audit_log writes (rejection path) since
  // anon/authenticated may not have direct INSERT on audit_log per MI-202.
  const serviceClient = createClient(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  // Pull firm_id from profiles.
  const { data: profile, error: profileErr } = await userClient
    .from('profiles')
    .select('firm_id')
    .eq('id', userId)
    .maybeSingle();

  if (profileErr || !profile?.firm_id) {
    return jsonResponse({ error: 'profile_or_firm_missing' }, 403);
  }
  const firmId = profile.firm_id as string;

  // ---- Parse body ----
  let body: any;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400);
  }

  const submissionId: string | null = body?.submission_id ?? null;
  const result: string | null = body?.result ?? null;

  if (!submissionId || typeof submissionId !== 'string') {
    return jsonResponse({ error: 'submission_id_required' }, 400);
  }
  if (result !== 'authorize' && result !== 'cancel') {
    return jsonResponse(
      { error: "result_must_be_authorize_or_cancel" },
      400,
    );
  }

  // ---- CANCEL path ----
  if (result === 'cancel') {
    try {
      await logRejection(
        serviceClient,
        'inspector_cancelled',
        firmId,
        userId,
        submissionId,
        { submission_id: submissionId, user_id: userId },
      );
      return jsonResponse({ logged: true });
    } catch (e) {
      console.error('[cs-auth-submit] cancel logging failed:', e);
      return jsonResponse({ error: 'audit_log_failed' }, 500);
    }
  }

  // ---- AUTHORIZE path: validate ----
  const supervisorName: string =
    typeof body?.supervisor_name === 'string'
      ? body.supervisor_name.trim()
      : '';
  const authorizedDate: string =
    typeof body?.authorized_date === 'string' ? body.authorized_date.trim() : '';
  const authorizedTime: string =
    typeof body?.authorized_time === 'string' ? body.authorized_time.trim() : '';
  const reason: string =
    typeof body?.reason === 'string' ? body.reason : '';

  const failures: { field: string; detail: string }[] = [];

  if (!supervisorName) {
    failures.push({ field: 'supervisor_name', detail: 'supervisor_name is required' });
  }
  if (!authorizedDate) {
    failures.push({ field: 'authorized_date', detail: 'authorized_date is required' });
  } else if (!/^\d{4}-\d{2}-\d{2}$/.test(authorizedDate)) {
    failures.push({ field: 'authorized_date', detail: 'authorized_date must be YYYY-MM-DD' });
  }
  if (!authorizedTime) {
    failures.push({ field: 'authorized_time', detail: 'authorized_time is required' });
  } else if (!/^\d{2}:\d{2}(:\d{2})?$/.test(authorizedTime)) {
    failures.push({ field: 'authorized_time', detail: 'authorized_time must be HH:MM or HH:MM:SS' });
  }
  if (!reason || reason.trim().length < 20) {
    failures.push({
      field: 'reason',
      detail: 'reason must be at least 20 characters (trimmed)',
    });
  }

  if (failures.length > 0) {
    try {
      await logRejection(
        serviceClient,
        'validation_failure',
        firmId,
        userId,
        submissionId,
        {
          submission_id: submissionId,
          user_id: userId,
          failed_field: failures[0].field,
          detail: failures.map((f) => `${f.field}: ${f.detail}`).join('; '),
        },
      );
    } catch (e) {
      console.error('[cs-auth-submit] validation rejection logging failed:', e);
      // Still return 400 to caller — validation failure is the primary signal.
    }
    return jsonResponse(
      {
        error: 'validation_failed',
        failures,
      },
      400,
    );
  }

  // ---- AUTHORIZE path: insert ----
  // Use the user-scoped client so RLS WITH CHECK runs as the caller —
  // this enforces created_by = auth.uid() AND firm_id = caller's firm.
  const { data: insertData, error: insertError } = await userClient
    .from('cs_replacement_authorizations')
    .insert({
      submission_id: submissionId,
      firm_id: firmId,
      supervisor_name: supervisorName,
      authorized_date: authorizedDate,
      authorized_time: authorizedTime,
      reason,
      // created_by defaults to auth.uid() server-side; pass explicitly to be safe.
      created_by: userId,
    })
    .select('id')
    .single();

  if (insertError) {
    console.error('[cs-auth-submit] insert failed:', insertError);
    // No rejection audit row here — the insert failure path is a 500, not a
    // policy rejection. MI-202 may already log DB errors separately.
    return jsonResponse(
      { error: 'insert_failed', detail: insertError.message },
      500,
    );
  }

  // Trigger fn_mi109_audit_cs_auth_accepted has now written the
  // 'cs_auth_accepted' audit_log row + extended the hash chain.
  return jsonResponse({
    authorization_id: insertData.id,
    logged: true,
  });
});
