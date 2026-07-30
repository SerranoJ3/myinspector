-- §3.2 (7/30): the two seeded water projects were vertical=NULL — a naive
-- pack filter still leaked them. Backfill, then close the hole structurally.
update projects set vertical = 'water' where vertical is null;
alter table projects alter column vertical set default 'water';
alter table projects alter column vertical set not null;
