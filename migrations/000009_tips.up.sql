begin;

create table tips (
    id          bigserial   primary key,
    section_id  bigint      not null references sections(id) on delete cascade,
    weight      int         not null default 1,
    status      varchar(20) not null default 'draft',
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),

    constraint tips_status_check check (status in ('draft', 'published', 'archived'))
);

create trigger trg_tips_updated_at
    before update on tips
    for each row execute function set_updated_at();

create table tip_translations (
    id            bigserial    primary key,
    tip_id        bigint       not null references tips(id) on delete cascade,
    language_code varchar(5)   not null,
    title         varchar(255) not null,
    body          text         not null,
    icon_key      varchar(50)  not null,
    theme_key     varchar(20)  not null,

    constraint tip_translations_unique unique (tip_id, language_code)
);

create index idx_tips_section_id_status    on tips(section_id, status);
create index idx_tip_translations_tip_lang on tip_translations(tip_id, language_code);

commit;
