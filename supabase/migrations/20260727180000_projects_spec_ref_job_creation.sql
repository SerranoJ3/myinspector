-- P0-1 (CC_ORDER 7/27): job creation from the UI needs a standard/spec reference
-- field on the job record. Additive; header blocks read it via the project row.
alter table projects add column if not exists spec_ref text;
