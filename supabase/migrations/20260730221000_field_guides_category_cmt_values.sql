-- CMT guide seeds need craft categories; widen the check additively.
alter table field_guides drop constraint field_guides_category_check;
alter table field_guides add constraint field_guides_category_check
  check (category = any (array['fittings','standards','compliance','recognition','other','site_craft','testing','evidence']));
