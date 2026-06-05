begin;

create table user_settings (
    id                    bigserial primary key,
    user_id               bigint not null unique references users(id) on delete cascade,
    language_code         varchar(10) not null default 'ru',
    theme                 varchar(20) not null default 'system',
    notifications_enabled boolean     not null default true,
    reminder_time         time,
    created_at            timestamptz not null default now(),
    updated_at            timestamptz not null default now(),

    constraint user_settings_language_code_check
        check (language_code in ('ru', 'kk', 'en')),
    constraint user_settings_theme_check
        check (theme in ('light', 'dark', 'system'))
);

create trigger trg_user_settings_updated_at
    before update on user_settings
    for each row execute function set_updated_at();

create table user_learning_profiles (
    id                         bigserial primary key,
    user_id                    bigint not null unique references users(id) on delete cascade,
    financial_literacy_level   varchar(30)  not null default 'beginner',
    practical_experience       varchar(50)  not null default 'no_experience',
    learning_goal              varchar(100) not null default 'general_improvement',
    preferred_language         varchar(10)  not null default 'ru',
    time_commitment            varchar(50)  not null default '10_min',
    onboarding_completed       boolean      not null default false,
    questionnaire_completed    boolean      not null default false,
    questionnaire_completed_at timestamptz,
    created_at                 timestamptz not null default now(),
    updated_at                 timestamptz not null default now(),

    constraint user_learning_profiles_level_check
        check (financial_literacy_level in ('beginner', 'basic', 'intermediate', 'advanced')),
    constraint user_learning_profiles_practical_experience_check
        check (practical_experience in ('no_experience', 'tracks_expenses', 'plans_budget', 'manages_finances')),
    constraint user_learning_profiles_learning_goal_check
        check (learning_goal in (
            'general_improvement', 'saving_money', 'debt_management', 'financial_planning',
            'increase_income', 'control_spending', 'understand_banking', 'start_investing', 'other'
        )),
    constraint user_learning_profiles_preferred_language_check
        check (preferred_language in ('ru', 'kk', 'en')),
    constraint user_learning_profiles_time_commitment_check
        check (time_commitment in ('5_min', '10_min', '15_min', '20_plus_min'))
);

create trigger trg_user_learning_profiles_updated_at
    before update on user_learning_profiles
    for each row execute function set_updated_at();

-- renamed from user_difficult_topics; codes map to the profile dimension not content codes
create table user_preferred_topics (
    id         bigserial primary key,
    user_id    bigint not null references users(id) on delete cascade,
    topic_code varchar(50) not null,
    created_at timestamptz not null default now(),

    constraint user_preferred_topics_user_topic_unique
        unique (user_id, topic_code),
    constraint user_preferred_topics_topic_code_check
        check (topic_code in ('budgeting', 'savings', 'credits_and_debts', 'financial_planning', 'investing'))
);

create index idx_user_preferred_topics_user_id on user_preferred_topics(user_id);

-- maps content topic codes to the profile topic_code vocabulary above
create or replace function preferred_topic_code(content_topic_code varchar)
    returns varchar as $$
begin
    return case content_topic_code
        when 'credit_and_debt' then 'credits_and_debts'
        when 'investments'     then 'investing'
        else content_topic_code
    end;
end;
$$ language plpgsql immutable;

commit;
