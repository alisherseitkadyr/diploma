begin;

drop trigger if exists trg_user_login_security_updated_at on user_login_security;
drop trigger if exists trg_users_updated_at on users;

drop table if exists user_login_security;
drop table if exists oauth_accounts;
drop table if exists refresh_tokens;
drop table if exists users;

drop function if exists set_updated_at();
drop extension if exists citext;

commit;
