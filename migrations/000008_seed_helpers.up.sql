begin;

-- ── seed_subtopic_quiz ────────────────────────────────────────
-- Upserts a subtopic quiz and its translations.
-- Returns the quiz id (used by seed_quiz_question).
--
-- p_titles JSON shape: [{"lang":"en","title":"Quiz: ..."},...]
create or replace function seed_subtopic_quiz(
    p_subtopic_code text,
    p_passing_score int,
    p_titles        jsonb
) returns bigint
language plpgsql as $$
declare
    v_quiz_id bigint;
    v_item    jsonb;
begin
    insert into quizzes (subtopic_code, passing_score, quiz_type, is_active)
    values (p_subtopic_code, p_passing_score, 'subtopic_quiz', true)
    on conflict (subtopic_code) where quiz_type = 'subtopic_quiz'
    do update set
        passing_score = excluded.passing_score,
        updated_at    = now()
    returning id into v_quiz_id;

    for v_item in select * from jsonb_array_elements(p_titles) loop
        insert into quiz_translations (quiz_id, language_code, title)
        values (v_quiz_id, v_item->>'lang', v_item->>'title')
        on conflict (quiz_id, language_code)
        do update set title = excluded.title;
    end loop;

    return v_quiz_id;
end;
$$;

-- ── seed_quiz_question ────────────────────────────────────────
-- Upserts one question (with translations and options) into a quiz.
--
-- p_texts JSON shape:
--   [{"lang":"en","text":"Question text"},...]
--
-- p_options JSON shape:
--   [{"order_index":1,"is_correct":false,
--     "translations":[{"lang":"en","text":"Option text"},...]}
--    ,...]
create or replace function seed_quiz_question(
    p_quiz_id       bigint,
    p_order_index   int,
    p_question_type text,
    p_texts         jsonb,
    p_options       jsonb
) returns void
language plpgsql as $$
declare
    v_question_id bigint;
    v_option_id   bigint;
    v_text        jsonb;
    v_option      jsonb;
    v_tr          jsonb;
begin
    -- Upsert question row
    insert into quiz_questions (quiz_id, question_type, order_index, points)
    values (p_quiz_id, p_question_type, p_order_index, 1)
    on conflict (quiz_id, order_index)
    do update set
        question_type = excluded.question_type,
        updated_at    = now()
    returning id into v_question_id;

    -- Question translations
    for v_text in select * from jsonb_array_elements(p_texts) loop
        insert into quiz_question_translations (question_id, language_code, question_text)
        values (v_question_id, v_text->>'lang', v_text->>'text')
        on conflict (question_id, language_code)
        do update set question_text = excluded.question_text;
    end loop;

    -- Options
    for v_option in select * from jsonb_array_elements(p_options) loop
        insert into quiz_question_options (question_id, is_correct, order_index)
        values (
            v_question_id,
            (v_option->>'is_correct')::boolean,
            (v_option->>'order_index')::int
        )
        on conflict (question_id, order_index)
        do update set
            is_correct = excluded.is_correct,
            updated_at = now()
        returning id into v_option_id;

        -- Option translations
        for v_tr in select * from jsonb_array_elements(v_option->'translations') loop
            insert into quiz_question_option_translations (option_id, language_code, option_text)
            values (v_option_id, v_tr->>'lang', v_tr->>'text')
            on conflict (option_id, language_code)
            do update set option_text = excluded.option_text;
        end loop;
    end loop;
end;
$$;

commit;
