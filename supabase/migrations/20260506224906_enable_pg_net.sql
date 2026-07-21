-- Install pg_net extension for HTTP calls from SQL.
-- Useful for invoking Edge Functions from triggers (MI-107 rule engine
-- architecture relies on this) and ad-hoc Edge Function invocation from
-- migrations.
--
-- Applied via Buddy direct Supabase MCP 2026-05-06 ~22:48 EDT during MI-DEMO
-- seed run when seed-demo-users Edge Function admin SDK threw "Database error
-- finding users" — pg_net was used to attempt invocation, failed at SDK layer
-- not network layer, then SQL bypass replaced the function call entirely.
-- Extension stays installed as a forward capability.

CREATE EXTENSION IF NOT EXISTS pg_net;
