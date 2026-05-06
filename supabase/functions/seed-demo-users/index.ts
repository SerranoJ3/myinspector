// MI-DEMO §18 — seed-demo-users Edge Function
//
// Creates 5 deterministic demo auth.users + matching profiles under the demo firm.
// Idempotent: if email already exists, return its id; UPSERT profile.
// verify_jwt=false; gated by shared-secret header `x-demo-seed-secret` matching
// env var DEMO_SEED_SECRET. Refuses any firm_id other than the demo firm UUID.
//
// Self-attribution per §16a option (a): profile INSERT passes the new user's own
// id as actor_id (the audit_log_chain_trigger picks it up via session var).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const DEMO_FIRM_ID = "99999999-9999-9999-9999-999999999999";

interface SeedUser {
  email: string;
  password: string;
  role: "super_admin" | "supervisor" | "inspector" | "owner" | "office_staff";
  full_name: string;
}

interface SeedRequest {
  firm_id: string;
  users: SeedUser[];
  wipe_existing?: boolean;
}

interface UserResult {
  email: string;
  id?: string;
  status: "created" | "exists" | "error";
  error?: string;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "POST required" }), {
      status: 405,
      headers: { "content-type": "application/json" },
    });
  }

  // 1. Shared-secret gate (§18 + §24 item 3)
  const expectedSecret = Deno.env.get("DEMO_SEED_SECRET");
  if (!expectedSecret) {
    return new Response(
      JSON.stringify({ error: "DEMO_SEED_SECRET not configured" }),
      { status: 500, headers: { "content-type": "application/json" } },
    );
  }
  const providedSecret = req.headers.get("x-demo-seed-secret");
  if (providedSecret !== expectedSecret) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "content-type": "application/json" },
    });
  }

  let payload: SeedRequest;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "invalid json" }), {
      status: 400,
      headers: { "content-type": "application/json" },
    });
  }

  // 2. Refuse any firm_id other than the demo firm
  if (payload.firm_id !== DEMO_FIRM_ID) {
    return new Response(
      JSON.stringify({
        error: "firm_id must match demo firm",
        expected: DEMO_FIRM_ID,
        got: payload.firm_id,
      }),
      { status: 403, headers: { "content-type": "application/json" } },
    );
  }

  if (!Array.isArray(payload.users) || payload.users.length === 0) {
    return new Response(
      JSON.stringify({ error: "users array required and non-empty" }),
      { status: 400, headers: { "content-type": "application/json" } },
    );
  }

  // 3. Admin client (service role)
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const results: UserResult[] = [];

  for (const user of payload.users) {
    try {
      // 4a. Try to find existing auth user by email
      const { data: existingList, error: listErr } = await admin.auth.admin
        .listUsers({ page: 1, perPage: 200 });
      if (listErr) {
        results.push({ email: user.email, status: "error", error: listErr.message });
        continue;
      }
      const existing = existingList?.users?.find((u) => u.email === user.email);

      let userId: string;
      let createdNew = false;

      if (existing) {
        userId = existing.id;
      } else {
        // 4b. Create new auth user (idempotent: if race, fall back to find)
        const { data: created, error: createErr } = await admin.auth.admin
          .createUser({
            email: user.email,
            password: user.password,
            email_confirm: true,
            user_metadata: {
              full_name: user.full_name,
              firm_id: DEMO_FIRM_ID,
              role: user.role,
            },
          });
        if (createErr || !created?.user) {
          results.push({
            email: user.email,
            status: "error",
            error: createErr?.message ?? "createUser returned no user",
          });
          continue;
        }
        userId = created.user.id;
        createdNew = true;
      }

      // 5. UPSERT profile (self-attribution: actor_id = user's own id via service role)
      const { error: profileErr } = await admin
        .from("profiles")
        .upsert(
          {
            id: userId,
            firm_id: DEMO_FIRM_ID,
            email: user.email,
            full_name: user.full_name,
            role: user.role,
          },
          { onConflict: "id" },
        );

      if (profileErr) {
        results.push({
          email: user.email,
          id: userId,
          status: "error",
          error: `profile upsert: ${profileErr.message}`,
        });
        continue;
      }

      results.push({
        email: user.email,
        id: userId,
        status: createdNew ? "created" : "exists",
      });
    } catch (err) {
      results.push({
        email: user.email,
        status: "error",
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }

  // 6. Aggregate response
  const created = results.filter((r) => r.status === "created");
  const skipped = results.filter((r) => r.status === "exists");
  const errors = results.filter((r) => r.status === "error");

  return new Response(
    JSON.stringify({
      firm_id: DEMO_FIRM_ID,
      created: created.map((r) => ({ email: r.email, id: r.id })),
      skipped: skipped.map((r) => ({ email: r.email, id: r.id })),
      errors: errors.map((r) => ({ email: r.email, error: r.error })),
      summary: `${created.length} created, ${skipped.length} skipped, ${errors.length} errors`,
    }),
    {
      status: errors.length > 0 ? 207 : 200,
      headers: { "content-type": "application/json" },
    },
  );
});
