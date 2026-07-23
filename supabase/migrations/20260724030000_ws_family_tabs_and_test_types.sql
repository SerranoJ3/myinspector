-- WS FAMILY (Part 2, 2026-07-23 order): tab check extended (asphalt, general) +
-- three FIRM-NEUTRAL registry rows. The field structure is industry-standard
-- ASTM practice; ALL identity renders from firms.report_config at print time.
-- Registry content (ASTM revision years etc.) correctable by the firm.
-- Applied to prod via MCP 2026-07-23; mirrored here. Additive only.

alter table test_types drop constraint test_types_tab_check;
alter table test_types add constraint test_types_tab_check
  check (tab = any (array['concrete'::text,'soils'::text,'asphalt'::text,'rebar'::text,'masonry'::text,'welding'::text,'steel'::text,'fireproofing'::text,'general'::text]));

insert into test_types (id, tab, name, astm_ref, astm_year, field_schema, photo_reqs, pass_logic, makes_samples, sort, enabled, accretive)
values
('asphalt_compaction', 'asphalt', 'Asphalt Compaction (Nuclear)', 'ASTM D2950/D2950M', 'D2950-22',
 '{"fields":[
   {"key":"weather","label":"Weather","type":"text"},
   {"key":"required_compaction_pct","label":"Required Compaction","type":"number","unit":"%","from_spec":"required_compaction_pct","hint":"from the governing spec; rows judge against this"},
   {"key":"material_lab","label":"Lab: Material","type":"text"},
   {"key":"marshall_pcf","label":"Lab: Marshall Value","type":"number","unit":"pcf","required":true},
   {"key":"rice_pcf","label":"Lab: Rice Value","type":"number","unit":"pcf"},
   {"key":"tests","label":"Field Tests — one row per test","type":"rowgrid","rows":12,"cols":[
     {"k":"no","label":"#","kind":"auto"},
     {"k":"location","label":"Location (See Attached Sketch)","kind":"text","w":170},
     {"k":"lift_in","label":"Lift Thk (in)","kind":"num","w":60},
     {"k":"material","label":"Material","kind":"text","w":100},
     {"k":"density_pcf","label":"Density (pcf)","kind":"num","w":70},
     {"k":"pct_compaction","label":"% Compaction","kind":"computed","w":70,"calc":"row.density_pcf!=null && v.marshall_pcf ? row.density_pcf/v.marshall_pcf*100 : null"},
     {"k":"air_voids","label":"Air Voids (%)","kind":"computed","w":64,"calc":"row.density_pcf!=null && v.rice_pcf ? (1-row.density_pcf/v.rice_pcf)*100 : null"},
     {"k":"retest","label":"R","kind":"text","w":26}
   ]}
 ]}'::jsonb,
 '[]'::jsonb,
 '{"kind":"rowgrid_min_pct","grid":"tests","col":"pct_compaction","min_key":"required_compaction_pct"}'::jsonb,
 false, 300, true, false),

('soil_compaction_depth', 'soils', 'Soil Compaction — In-Place Density (Depth)', 'ASTM D6938', 'D6938-23',
 '{"fields":[
   {"key":"weather","label":"Weather","type":"text"},
   {"key":"required_compaction_pct","label":"Required Compaction","type":"number","unit":"%","from_spec":"required_compaction_pct"},
   {"key":"proctors","label":"Laboratory Data — proctor baselines (one row per sample)","type":"rowgrid","rows":3,"cols":[
     {"k":"sample_id","label":"Sample ID","kind":"text","w":120},
     {"k":"max_dry_pcf","label":"Max Dry Density (pcf)","kind":"num","w":90},
     {"k":"opt_moisture_pct","label":"Optimum Moisture (%)","kind":"num","w":90}
   ]},
   {"key":"tests","label":"Field Tests — one row per test","type":"rowgrid","rows":14,"cols":[
     {"k":"no","label":"#","kind":"auto"},
     {"k":"location","label":"Location (See Attached Location)","kind":"text","w":160},
     {"k":"depth_bsg","label":"Depth BSG (ft)","kind":"num","w":60},
     {"k":"sample_id","label":"Sample ID","kind":"text","w":110},
     {"k":"moisture_pct","label":"Moisture (%)","kind":"num","w":64},
     {"k":"wet_pcf","label":"Wet Density (pcf)","kind":"num","w":70},
     {"k":"dry_pcf","label":"Dry Density (pcf)","kind":"computed","w":70,"calc":"row.wet_pcf!=null && row.moisture_pct!=null ? row.wet_pcf/(1+row.moisture_pct/100) : null"},
     {"k":"pct_compaction","label":"% Compaction","kind":"computed","w":70,"calc":"(function(){var d=row.wet_pcf!=null&&row.moisture_pct!=null?row.wet_pcf/(1+row.moisture_pct/100):null;var p=((v.proctors||[]).find(function(x){return x.sample_id===row.sample_id;})||{}).max_dry_pcf;return d!=null&&p?d/p*100:null;})()"}
   ],"hint":"*BSG: Below Subgrade. Dry density + % compaction compute from the matching proctor row."}
 ]}'::jsonb,
 '[]'::jsonb,
 '{"kind":"rowgrid_min_pct","grid":"tests","col":"pct_compaction","min_key":"required_compaction_pct"}'::jsonb,
 false, 210, true, false),

('site_inspection', 'general', 'Site Inspection (Narrative)', 'General Services', '—',
 '{"fields":[
   {"key":"weather","label":"Weather","type":"text"},
   {"key":"temp_range","label":"Temp. Range","type":"text","hint":"e.g. 50° – 70° F"},
   {"key":"present_at_site","label":"Present at Site","type":"text"},
   {"key":"narrative","label":"Testing and inspection services performed","type":"textarea","required":true}
 ]}'::jsonb,
 '[]'::jsonb,
 '{"kind":"none"}'::jsonb,
 false, 900, true, false)
on conflict (id) do nothing;
