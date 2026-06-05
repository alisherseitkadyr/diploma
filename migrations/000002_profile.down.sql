begin;

drop function if exists preferred_topic_code(varchar);

drop trigger if exists trg_user_learning_profiles_updated_at on user_learning_profiles;
drop trigger if exists trg_user_settings_updated_at on user_settings;

drop table if exists user_preferred_topics;
drop table if exists user_learning_profiles;
drop table if exists user_settings;

commit;
