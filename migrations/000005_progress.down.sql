begin;

drop trigger if exists trg_user_learning_stats_updated_at on user_learning_stats;
drop trigger if exists trg_user_quiz_progress_updated_at on user_quiz_progress;
drop trigger if exists trg_user_progress_updated_at on user_progress;

drop table if exists user_subtopic_readings;
drop table if exists user_learning_stats;
drop table if exists user_quiz_progress;
drop table if exists user_progress;

commit;
