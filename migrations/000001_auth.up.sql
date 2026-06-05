begin;

create extension if not exists citext;

-- shared trigger function (created once here, used by all subsequent migrations)
create or replace function set_updated_at()
    returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create table users (
    id            bigserial primary key,
    email         citext    not null unique,
    username      varchar(100) not null,
    -- nullable: google-only users have no password
    password_hash text,
    is_active     boolean   not null default true,
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now()
);

create trigger trg_users_updated_at
    before update on users
    for each row execute function set_updated_at();

create table refresh_tokens (
    id         bigserial primary key,
    user_id    bigint not null references users(id) on delete cascade,
    token_hash text   not null unique,
    expires_at timestamptz not null,
    revoked_at timestamptz,
    created_at timestamptz not null default now()
);

create index idx_refresh_tokens_user_id  on refresh_tokens(user_id);
create index idx_refresh_tokens_expires_at on refresh_tokens(expires_at);

create table oauth_accounts (
    id               bigserial primary key,
    user_id          bigint not null references users(id) on delete cascade,
    provider         varchar(32) not null,
    provider_user_id varchar(255) not null,
    created_at       timestamptz not null default now(),

    constraint oauth_accounts_provider_check
        check (provider in ('google')),
    constraint oauth_accounts_provider_user_unique
        unique (provider, provider_user_id),
    constraint oauth_accounts_user_provider_unique
        unique (user_id, provider)
);

create index idx_oauth_accounts_user_id on oauth_accounts(user_id);
create index idx_oauth_accounts_provider on oauth_accounts(provider, provider_user_id);

create table user_login_security (
    user_id         bigint primary key references users(id) on delete cascade,
    failed_attempts int  not null default 0,
    locked_until    timestamptz,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),

    constraint user_login_security_failed_attempts_check
        check (failed_attempts >= 0)
);

create trigger trg_user_login_security_updated_at
    before update on user_login_security
    for each row execute function set_updated_at();

commit;
