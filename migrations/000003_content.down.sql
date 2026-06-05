begin;

drop trigger if exists trg_lesson_steps_updated_at on lesson_steps;
drop trigger if exists trg_lessons_updated_at on lessons;
drop trigger if exists trg_subtopics_updated_at on subtopics;
drop trigger if exists trg_topics_updated_at on topics;

drop table if exists lesson_step_translations;
drop table if exists lesson_steps;
drop table if exists lessons;
drop table if exists subtopic_translations;
drop table if exists subtopics;
drop table if exists topic_translations;
drop table if exists topics;

commit;
