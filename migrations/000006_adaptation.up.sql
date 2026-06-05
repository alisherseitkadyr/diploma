begin;

create table user_reinforcement_predictions (
    id               bigserial primary key,
    user_id          bigint       not null,
    quiz_id          bigint       not null,
    attempt_id       bigint       not null unique,
    quiz_type        varchar(30)  not null,
    topic_code       varchar(100) not null,
    subtopic_code    varchar(100),
    score_percent    numeric(5,2) not null,
    avg_last_3_scores numeric(5,2) not null,
    needs_reinforcement boolean   not null,
    prediction       int          not null,
    probability      numeric(6,4) not null default 0,
    confidence       numeric(6,4) not null default 0,
    decision_source  varchar(50)  not null,
    model_name       varchar(100),
    model_version    varchar(50),
    created_at       timestamptz  not null default now(),

    constraint user_reinforcement_predictions_quiz_type_check
        check (quiz_type in ('subtopic_quiz', 'topic_final_quiz')),
    constraint user_reinforcement_predictions_score_check
        check (score_percent >= 0 and score_percent <= 100),
    constraint user_reinforcement_predictions_avg_score_check
        check (avg_last_3_scores >= 0 and avg_last_3_scores <= 100),
    constraint user_reinforcement_predictions_prediction_check
        check (prediction in (0, 1)),
    constraint user_reinforcement_predictions_probability_check
        check (probability >= 0 and probability <= 1),
    constraint user_reinforcement_predictions_confidence_check
        check (confidence >= 0 and confidence <= 1)
);

create index idx_user_reinforcement_predictions_user_id
    on user_reinforcement_predictions(user_id);
create index idx_user_reinforcement_predictions_attempt_id
    on user_reinforcement_predictions(attempt_id);
create index idx_user_reinforcement_predictions_topic_code
    on user_reinforcement_predictions(topic_code);
create index idx_user_reinforcement_predictions_subtopic_code
    on user_reinforcement_predictions(subtopic_code);
create index idx_user_reinforcement_predictions_needs
    on user_reinforcement_predictions(needs_reinforcement);

commit;
