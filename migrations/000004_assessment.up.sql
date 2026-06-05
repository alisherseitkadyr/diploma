begin;

-- quiz_type = 'subtopic_quiz': subtopic_code set, topic_code null
-- quiz_type = 'topic_final_quiz': topic_code set, subtopic_code null
--   topic_final_quiz has NO quiz_questions; questions are sampled from subtopic pools at runtime
create table quizzes (
    id                bigserial primary key,
    subtopic_code     varchar(100),
    topic_code        varchar(100) references topics(code) on delete cascade,
    passing_score     int         not null default 70,
    time_limit_seconds int,
    is_active         boolean     not null default true,
    quiz_type         varchar(30) not null default 'subtopic_quiz',
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now(),

    constraint quizzes_passing_score_check
        check (passing_score between 0 and 100),
    constraint quizzes_time_limit_seconds_check
        check (time_limit_seconds is null or time_limit_seconds > 0),
    constraint quizzes_quiz_type_check
        check (quiz_type in ('subtopic_quiz', 'topic_final_quiz')),
    constraint quizzes_quiz_target_check
        check (
            (quiz_type = 'subtopic_quiz'     and subtopic_code is not null and topic_code is null) or
            (quiz_type = 'topic_final_quiz'  and topic_code    is not null and subtopic_code is null)
        )
);

create unique index quizzes_unique_subtopic_quiz
    on quizzes(subtopic_code) where quiz_type = 'subtopic_quiz';

create unique index quizzes_unique_topic_final_quiz
    on quizzes(topic_code) where quiz_type = 'topic_final_quiz';

create trigger trg_quizzes_updated_at
    before update on quizzes
    for each row execute function set_updated_at();

create table quiz_translations (
    id            bigserial primary key,
    quiz_id       bigint       not null references quizzes(id) on delete cascade,
    language_code varchar(10)  not null,
    title         varchar(255) not null,

    constraint quiz_translations_unique unique (quiz_id, language_code)
);

create table quiz_questions (
    id            bigserial primary key,
    quiz_id       bigint      not null references quizzes(id) on delete cascade,
    question_type varchar(30) not null,
    order_index   int         not null,
    points        int         not null default 1,
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now(),

    constraint quiz_questions_type_check
        check (question_type in ('single_choice', 'multiple_choice', 'true_false')),
    constraint quiz_questions_order_index_check
        check (order_index > 0),
    constraint quiz_questions_points_check
        check (points > 0),
    constraint quiz_questions_quiz_order_unique
        unique (quiz_id, order_index)
);

create trigger trg_quiz_questions_updated_at
    before update on quiz_questions
    for each row execute function set_updated_at();

create table quiz_question_translations (
    id            bigserial primary key,
    question_id   bigint not null references quiz_questions(id) on delete cascade,
    language_code varchar(10) not null,
    question_text text not null,

    constraint quiz_question_translations_unique unique (question_id, language_code)
);

create table quiz_question_options (
    id          bigserial primary key,
    question_id bigint  not null references quiz_questions(id) on delete cascade,
    is_correct  boolean not null default false,
    order_index int     not null,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),

    constraint quiz_question_options_order_index_check
        check (order_index > 0),
    constraint quiz_question_options_question_order_unique
        unique (question_id, order_index)
);

create trigger trg_quiz_question_options_updated_at
    before update on quiz_question_options
    for each row execute function set_updated_at();

create table quiz_question_option_translations (
    id            bigserial primary key,
    option_id     bigint not null references quiz_question_options(id) on delete cascade,
    language_code varchar(10) not null,
    option_text   text not null,

    constraint quiz_question_option_translations_unique unique (option_id, language_code)
);

-- status: in_progress → completed | expired | abandoned
create table quiz_attempts (
    id               bigserial primary key,
    user_id          bigint not null references users(id) on delete cascade,
    quiz_id          bigint not null references quizzes(id),
    total_questions  int    not null,
    correct_answers  int    not null,
    wrong_answers    int    not null,
    score_percent    int    not null,
    passed           boolean not null,
    started_at       timestamptz,
    completed_at     timestamptz,
    submitted_at     timestamptz not null default now(),
    duration_seconds int     not null default 0,
    xp_for_score     int     not null default 0,
    status           varchar(30) not null default 'completed',
    created_at       timestamptz not null default now(),

    constraint quiz_attempts_status_check
        check (status in ('in_progress', 'completed', 'expired', 'abandoned')),
    constraint quiz_attempts_total_questions_check
        check (total_questions > 0),
    constraint quiz_attempts_correct_answers_check
        check (correct_answers >= 0),
    constraint quiz_attempts_wrong_answers_check
        check (wrong_answers >= 0),
    constraint quiz_attempts_answers_sum_check
        check (status <> 'completed' or correct_answers + wrong_answers = total_questions),
    constraint quiz_attempts_score_percent_check
        check (score_percent between 0 and 100),
    constraint quiz_attempts_duration_seconds_check
        check (duration_seconds >= 0)
);

create index idx_quiz_attempts_user_id       on quiz_attempts(user_id);
create index idx_quiz_attempts_user_quiz_id  on quiz_attempts(user_id, quiz_id);

create table quiz_attempt_questions (
    id          bigserial primary key,
    attempt_id  bigint not null references quiz_attempts(id) on delete cascade,
    question_id bigint not null references quiz_questions(id) on delete cascade,
    order_index int    not null,
    created_at  timestamptz not null default now(),

    constraint quiz_attempt_questions_unique       unique (attempt_id, question_id),
    constraint quiz_attempt_questions_order_unique unique (attempt_id, order_index)
);

create index idx_quiz_attempt_questions_attempt_id  on quiz_attempt_questions(attempt_id);
create index idx_quiz_attempt_questions_question_id on quiz_attempt_questions(question_id);

create table quiz_attempt_answers (
    id                       bigserial primary key,
    attempt_id               bigint  not null references quiz_attempts(id) on delete cascade,
    question_id              bigint  not null references quiz_questions(id),
    selected_option_id       bigint  references quiz_question_options(id),
    is_correct               boolean not null,
    is_selected_option_correct boolean not null,
    is_question_correct      boolean not null,
    created_at               timestamptz not null default now(),

    constraint quiz_attempt_answers_attempt_question_option_unique
        unique (attempt_id, question_id, selected_option_id)
);

create index idx_quiz_attempt_answers_attempt_id        on quiz_attempt_answers(attempt_id);
create index idx_quiz_attempt_answers_question_id       on quiz_attempt_answers(question_id);
create index idx_quiz_attempt_answers_selected_option_id on quiz_attempt_answers(selected_option_id);
create index idx_quiz_questions_quiz_id                 on quiz_questions(quiz_id);
create index idx_quiz_question_options_question_id      on quiz_question_options(question_id);

commit;
