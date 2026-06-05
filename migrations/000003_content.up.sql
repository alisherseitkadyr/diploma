begin;

create table topics (
    id          bigserial primary key,
    code        varchar(100) not null unique,
    level       varchar(20)  not null,
    order_index int          not null,
    is_active   boolean      not null default true,
    created_at  timestamptz  not null default now(),
    updated_at  timestamptz  not null default now(),

    constraint topics_level_check
        check (level in ('beginner', 'intermediate', 'advanced')),
    constraint topics_level_order_unique
        unique (level, order_index)
);

create trigger trg_topics_updated_at
    before update on topics
    for each row execute function set_updated_at();

create table topic_translations (
    id            bigserial primary key,
    topic_id      bigint       not null references topics(id) on delete cascade,
    language_code varchar(5)   not null,
    title         varchar(255) not null,
    description   text,

    constraint topic_translations_unique unique (topic_id, language_code)
);

create table subtopics (
    id                bigserial primary key,
    topic_id          bigint not null references topics(id) on delete cascade,
    code              varchar(100) not null unique,
    order_index       int not null,
    estimated_minutes int,
    is_active         boolean not null default true,
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now(),

    constraint subtopics_topic_order_unique unique (topic_id, order_index)
);

create trigger trg_subtopics_updated_at
    before update on subtopics
    for each row execute function set_updated_at();

create table subtopic_translations (
    id            bigserial primary key,
    subtopic_id   bigint       not null references subtopics(id) on delete cascade,
    language_code varchar(5)   not null,
    title         varchar(255) not null,
    description   text,

    constraint subtopic_translations_unique unique (subtopic_id, language_code)
);

create table lessons (
    id           bigserial primary key,
    subtopic_id  bigint  not null unique references subtopics(id) on delete cascade,
    is_published boolean not null default true,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);

create trigger trg_lessons_updated_at
    before update on lessons
    for each row execute function set_updated_at();

create table lesson_steps (
    id               bigserial primary key,
    lesson_id        bigint       not null references lessons(id) on delete cascade,
    step_type        varchar(50)  not null,
    order_index      int          not null,
    interactive_type varchar(50),
    created_at       timestamptz  not null default now(),
    updated_at       timestamptz  not null default now(),

    constraint lesson_steps_order_unique unique (lesson_id, order_index)
);

create trigger trg_lesson_steps_updated_at
    before update on lesson_steps
    for each row execute function set_updated_at();

-- content and interactive_content are jsonb (interactive_content moved from lesson_steps)
create table lesson_step_translations (
    id                  bigserial primary key,
    lesson_step_id      bigint     not null references lesson_steps(id) on delete cascade,
    language_code       varchar(5) not null,
    title               varchar(255),
    content             jsonb,
    interactive_content jsonb,

    constraint lesson_step_translations_unique unique (lesson_step_id, language_code)
);

create index idx_subtopics_topic_id_order_index
    on subtopics(topic_id, order_index);
create index idx_topic_translations_topic_id_lang
    on topic_translations(topic_id, language_code);
create index idx_subtopic_translations_subtopic_id_lang
    on subtopic_translations(subtopic_id, language_code);
create index idx_lesson_steps_lesson_id_order_index
    on lesson_steps(lesson_id, order_index);
create index idx_lesson_step_translations_step_id_lang
    on lesson_step_translations(lesson_step_id, language_code);

commit;
