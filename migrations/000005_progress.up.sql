begin;

create table user_progress (
    user_id        bigint primary key,
    total_xp       int         not null default 0,
    progress_level varchar(50) not null default 'beginner',
    last_activity_at timestamptz,
    created_at     timestamptz not null default now(),
    updated_at     timestamptz not null default now(),

    constraint user_progress_total_xp_check
        check (total_xp >= 0),
    constraint user_progress_level_check
        check (progress_level in ('beginner', 'amateur', 'practitioner', 'advanced_learner'))
);

create trigger trg_user_progress_updated_at
    before update on user_progress
    for each row execute function set_updated_at();

create table user_quiz_progress (
    id                bigserial primary key,
    user_id           bigint       not null,
    quiz_code         varchar(150) not null,
    quiz_type         varchar(30)  not null,
    topic_code        varchar(100),
    subtopic_code     varchar(100),
    best_score_points int          not null,
    max_score_points  int          not null,
    best_score_percent numeric(5,2) not null,
    earned_xp         int          not null default 0,
    attempts_count    int          not null default 1,
    first_attempt_at  timestamptz  not null default now(),
    best_attempt_at   timestamptz  not null default now(),
    last_attempt_at   timestamptz  not null default now(),
    created_at        timestamptz  not null default now(),
    updated_at        timestamptz  not null default now(),

    constraint user_quiz_progress_unique
        unique (user_id, quiz_code),
    constraint user_quiz_progress_type_check
        check (quiz_type in ('subtopic_quiz', 'topic_final_quiz')),
    constraint user_quiz_progress_score_percent_check
        check (best_score_percent >= 0 and best_score_percent <= 100),
    constraint user_quiz_progress_points_check
        check (best_score_points >= 0 and max_score_points > 0 and best_score_points <= max_score_points),
    constraint user_quiz_progress_earned_xp_check
        check (earned_xp >= 0),
    constraint user_quiz_progress_attempts_check
        check (attempts_count >= 1)
);

create trigger trg_user_quiz_progress_updated_at
    before update on user_quiz_progress
    for each row execute function set_updated_at();

create index idx_user_quiz_progress_user_id       on user_quiz_progress(user_id);
create index idx_user_quiz_progress_quiz_code      on user_quiz_progress(quiz_code);
create index idx_user_quiz_progress_topic_code     on user_quiz_progress(topic_code);
create index idx_user_quiz_progress_subtopic_code  on user_quiz_progress(subtopic_code);
create index idx_user_quiz_progress_quiz_type      on user_quiz_progress(quiz_type);

create table user_learning_stats (
    user_id                              bigint primary key,
    total_quiz_attempts                  int          not null default 0,
    completed_quizzes_count              int          not null default 0,
    completed_subtopic_quizzes_count     int          not null default 0,
    completed_topic_final_quizzes_count  int          not null default 0,
    completed_subtopics_count            int          not null default 0,
    completed_topics_count               int          not null default 0,
    average_best_score_percent           numeric(5,2) not null default 0,
    average_all_attempts_score_percent   numeric(5,2) not null default 0,
    max_score_quizzes_count              int          not null default 0,
    best_topic_code                      varchar(100),
    weakest_topic_code                   varchar(100),
    last_quiz_completed_at               timestamptz,
    created_at                           timestamptz  not null default now(),
    updated_at                           timestamptz  not null default now(),

    constraint user_learning_stats_counts_check
        check (
            total_quiz_attempts >= 0 and completed_quizzes_count >= 0 and
            completed_subtopic_quizzes_count >= 0 and completed_topic_final_quizzes_count >= 0 and
            completed_subtopics_count >= 0 and completed_topics_count >= 0 and
            max_score_quizzes_count >= 0
        ),
    constraint user_learning_stats_average_best_score_check
        check (average_best_score_percent >= 0 and average_best_score_percent <= 100),
    constraint user_learning_stats_average_all_score_check
        check (average_all_attempts_score_percent >= 0 and average_all_attempts_score_percent <= 100)
);

create trigger trg_user_learning_stats_updated_at
    before update on user_learning_stats
    for each row execute function set_updated_at();

-- reading completion gate: topic is complete only when all subtopics read AND quiz passed
create table user_subtopic_readings (
    id            bigserial primary key,
    user_id       bigint not null references users(id) on delete cascade,
    subtopic_id   bigint not null references subtopics(id) on delete cascade,
    completed_at  timestamptz not null default now(),

    constraint user_subtopic_readings_unique unique (user_id, subtopic_id)
);

create index idx_user_subtopic_readings_user_id     on user_subtopic_readings(user_id);
create index idx_user_subtopic_readings_subtopic_id on user_subtopic_readings(subtopic_id);

commit;
