begin;

drop index if exists idx_topics_section_id;
alter table topics drop column if exists section_id;
drop table if exists section_translations;
drop table if exists sections;

commit;
