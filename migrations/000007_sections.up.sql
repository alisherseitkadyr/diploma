begin;

create table sections (
    id          bigserial primary key,
    code        text        not null unique,
    order_index int         not null,
    icon        text,
    color_hex   text,
    is_active   boolean     not null default true,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),
    constraint sections_order_unique unique (order_index)
);

create table section_translations (
    section_id    bigint not null references sections(id) on delete cascade,
    language_code text   not null,
    title         text   not null,
    description   text,
    primary key (section_id, language_code)
);

-- nullable so existing topic rows are not broken before the seed backfill runs
alter table topics add column section_id bigint references sections(id);

create index idx_topics_section_id on topics(section_id);

commit;
