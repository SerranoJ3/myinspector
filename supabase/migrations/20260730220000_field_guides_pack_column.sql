-- CORE-REGROUP (7/30): field_guides is a global platform table (no firm_id) —
-- authorship stays global (the content is Jorge's, served to every tenant),
-- but each guide now declares which vertical it belongs to.
-- pack = 'water' | 'cmt' | NULL (null = shown to all packs).
alter table field_guides add column if not exists pack text check (pack in ('water','cmt'));
update field_guides set pack = 'water' where slug = 'service-line-fittings' and pack is null;
