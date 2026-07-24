-- Pre-authorized (merge #3 order item 3, 2026-07-23): profiles was the ONE
-- Owner Data table without the MI-202 audit set — role changes went unlogged,
-- including tonight's hotfix promotion. Standard pattern, additive.
-- Applied to prod via MCP; mirrored here.
create trigger audit_profiles_insert after insert on profiles for each row execute function write_audit_log();
create trigger audit_profiles_update after update on profiles for each row execute function write_audit_log();
create trigger audit_profiles_delete after delete on profiles for each row execute function write_audit_log();
