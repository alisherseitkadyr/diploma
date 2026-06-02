
-- =====================================================
-- Topic 06: insurance_basics
-- =====================================================

-- =====================================================
-- 1. TOPIC
-- =====================================================

insert into topics (code, level, order_index, is_active)
values ('insurance_basics', 'intermediate', 4, true)
on conflict (code) do update set
    level = excluded.level,
    order_index = excluded.order_index,
    is_active = excluded.is_active,
    updated_at = now();

insert into topic_translations (topic_id, language_code, title, description)
values
(
    (select id from topics where code = 'insurance_basics'),
    'ru',
    'Основы страхования',
    'Как работает страхование, какие виды действительно важны и как защитить себя от крупных финансовых потерь.'
),
(
    (select id from topics where code = 'insurance_basics'),
    'en',
    'Insurance Basics',
    'Learn how insurance works, which policies matter most, and how to protect yourself from major financial risks.'
),
(
    (select id from topics where code = 'insurance_basics'),
    'kk',
    'Сақтандыру негіздері',
    'Сақтандыру қалай жұмыс істейтінін, қандай полистер маңызды екенін және ірі қаржылық тәуекелдерден қалай қорғануға болатынын үйреніңіз.'
)
on conflict (topic_id, language_code) do update set
    title = excluded.title,
    description = excluded.description;

-- =====================================================
-- 2. SUBTOPICS
-- =====================================================

insert into subtopics (topic_id, code, order_index, estimated_minutes, is_active)
values
((select id from topics where code = 'insurance_basics'), 'ins_core_idea', 1, 3, true),
((select id from topics where code = 'insurance_basics'), 'ins_health', 2, 5, true),
((select id from topics where code = 'insurance_basics'), 'ins_life', 3, 5, true),
((select id from topics where code = 'insurance_basics'), 'ins_property_auto', 4, 4, true),
((select id from topics where code = 'insurance_basics'), 'ins_pick_and_claim', 5, 4, true)
on conflict (code) do update set
    order_index = excluded.order_index,
    estimated_minutes = excluded.estimated_minutes,
    is_active = excluded.is_active,
    updated_at = now();

insert into subtopic_translations (subtopic_id, language_code, title)
values
((select id from subtopics where code = 'ins_core_idea'), 'ru', 'Как работает страхование: общий риск'),
((select id from subtopics where code = 'ins_core_idea'), 'en', 'How Insurance Works: Pooled Risk'),
((select id from subtopics where code = 'ins_core_idea'), 'kk', 'Сақтандыру қалай жұмыс істейді: ортақ тәуекел'),

((select id from subtopics where code = 'ins_health'), 'ru', 'Медицинское страхование: на что смотреть'),
((select id from subtopics where code = 'ins_health'), 'en', 'Health Insurance: What to Look For'),
((select id from subtopics where code = 'ins_health'), 'kk', 'Медициналық сақтандыру: неге назар аудару керек'),

((select id from subtopics where code = 'ins_life'), 'ru', 'Страхование жизни: кому и зачем'),
((select id from subtopics where code = 'ins_life'), 'en', 'Life Insurance: Who Needs It and Why'),
((select id from subtopics where code = 'ins_life'), 'kk', 'Өмірді сақтандыру: кімге және не үшін қажет'),

((select id from subtopics where code = 'ins_property_auto'), 'ru', 'Страхование имущества и автомобиля'),
((select id from subtopics where code = 'ins_property_auto'), 'en', 'Property & Auto Insurance'),
((select id from subtopics where code = 'ins_property_auto'), 'kk', 'Мүлік пен автокөлік сақтандыруы'),

((select id from subtopics where code = 'ins_pick_and_claim'), 'ru', 'Как выбрать полис и подать страховой случай'),
((select id from subtopics where code = 'ins_pick_and_claim'), 'en', 'How to Pick a Policy & File a Claim'),
((select id from subtopics where code = 'ins_pick_and_claim'), 'kk', 'Полисті қалай таңдау және өтемақы рәсімдеу')

on conflict (subtopic_id, language_code) do update set
    title = excluded.title;

-- =====================================================
-- 3. LESSON SHELLS
-- =====================================================

insert into lessons (subtopic_id, is_published)
select id, true
from subtopics
where code in (
    'ins_core_idea',
    'ins_health',
    'ins_life',
    'ins_property_auto',
    'ins_pick_and_claim'
)
on conflict (subtopic_id) do update set
    is_published = excluded.is_published;

-- =====================================================
-- 4. TOPIC FINAL QUIZ
-- =====================================================

insert into quizzes (subtopic_code, topic_code, quiz_type, passing_score, is_active)
values
    (null, 'insurance_basics', 'topic_final_quiz', 75, true)
on conflict (topic_code) where quiz_type = 'topic_final_quiz' do update set
    passing_score = excluded.passing_score,
    is_active = excluded.is_active,
    updated_at = now();

insert into quiz_translations (quiz_id, language_code, title)
values
((select id from quizzes where topic_code='insurance_basics' and quiz_type='topic_final_quiz'), 'ru', 'Финальный тест: основы страхования'),
((select id from quizzes where topic_code='insurance_basics' and quiz_type='topic_final_quiz'), 'en', 'Final Quiz: Insurance Basics'),
((select id from quizzes where topic_code='insurance_basics' and quiz_type='topic_final_quiz'), 'kk', 'Қорытынды тест: сақтандыру негіздері')
on conflict (quiz_id, language_code) do update set
    title = excluded.title;

-- =====================================================
-- 5. SAMPLE SUBTOPIC QUIZ
-- =====================================================

DO $$
DECLARE v bigint;
BEGIN
    v := seed_subtopic_quiz('ins_core_idea', 70, '[
        {"lang":"ru","title":"Квиз: как работает страхование"},
        {"lang":"en","title":"Quiz: How Insurance Works"},
        {"lang":"kk","title":"Тест: сақтандыру қалай жұмыс істейді"}
    ]'::jsonb);

    perform seed_quiz_question(
        v,
        1,
        'single_choice',
        '[
            {"lang":"ru","text":"Почему страховые компании могут выплачивать компенсации большинству клиентов?"},
            {"lang":"en","text":"Why can insurance companies pay claims to many customers?"},
            {"lang":"kk","text":"Неліктен сақтандыру компаниялары көптеген клиенттерге өтемақы төлей алады?"}
        ]'::jsonb,
        '[
            {
                "order_index":1,
                "is_correct":false,
                "translations":[
                    {"lang":"ru","text":"Потому что государство покрывает все убытки"},
                    {"lang":"en","text":"Because the government covers all losses"},
                    {"lang":"kk","text":"Өйткені барлық шығынды мемлекет өтейді"}
                ]
            },
            {
                "order_index":2,
                "is_correct":true,
                "translations":[
                    {"lang":"ru","text":"Потому что риск распределяется между многими людьми"},
                    {"lang":"en","text":"Because risk is shared across many people"},
                    {"lang":"kk","text":"Өйткені тәуекел көптеген адамдар арасында бөлінеді"}
                ]
            },
            {
                "order_index":3,
                "is_correct":false,
                "translations":[
                    {"lang":"ru","text":"Потому что страховые случаи почти не происходят"},
                    {"lang":"en","text":"Because insurance events almost never happen"},
                    {"lang":"kk","text":"Өйткені сақтандыру жағдайлары өте сирек болады"}
                ]
            },
            {
                "order_index":4,
                "is_correct":false,
                "translations":[
                    {"lang":"ru","text":"Потому что банки всегда помогают страховщикам"},
                    {"lang":"en","text":"Because banks always support insurers"},
                    {"lang":"kk","text":"Өйткені банктер әрқашан сақтандырушыларға көмектеседі"}
                ]
            }
        ]'::jsonb
    );
END $$;

-- =====================================================
-- 6. LESSON STEPS
-- =====================================================

begin;

-- =====================================================
-- ins_core_idea
-- =====================================================

insert into lesson_steps (lesson_id, step_type, order_index)
values (
    (
        select l.id
        from lessons l
        join subtopics s on s.id = l.subtopic_id
        where s.code = 'ins_core_idea'
    ),
    'introduction',
    1
)
on conflict (lesson_id, order_index) do update set
    step_type = excluded.step_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
(
    (
        select ls.id from lesson_steps ls
        join lessons l on l.id = ls.lesson_id
        join subtopics s on s.id = l.subtopic_id
        where s.code = 'ins_core_idea' and ls.order_index = 1
    ),
    'ru',
    'Почему вообще существует страхование',
    '{
        "blocks": [
            {
                "type": "paragraph",
                "text": "Страхование защищает вас от редких, но очень дорогих проблем. Большинство людей не могут легко оплатить крупную аварию, пожар или серьезную операцию из собственного кармана."
            },
            {
                "type": "paragraph",
                "text": "Идея проста: много людей платят небольшие суммы, а страховая компания помогает тем, у кого действительно произошла проблема."
            }
        ]
    }'::jsonb
),
(
    (
        select ls.id from lesson_steps ls
        join lessons l on l.id = ls.lesson_id
        join subtopics s on s.id = l.subtopic_id
        where s.code = 'ins_core_idea' and ls.order_index = 1
    ),
    'en',
    'Why Insurance Exists',
    '{
        "blocks": [
            {
                "type": "paragraph",
                "text": "Insurance protects you from rare but expensive problems. Most people cannot easily pay for a major accident, fire, or surgery out of pocket."
            },
            {
                "type": "paragraph",
                "text": "The idea is simple: many people pay small amounts, and the insurance company helps the people who actually experience a loss."
            }
        ]
    }'::jsonb
),
(
    (
        select ls.id from lesson_steps ls
        join lessons l on l.id = ls.lesson_id
        join subtopics s on s.id = l.subtopic_id
        where s.code = 'ins_core_idea' and ls.order_index = 1
    ),
    'kk',
    'Сақтандыру не үшін қажет',
    '{
        "blocks": [
            {
                "type": "paragraph",
                "text": "Сақтандыру сирек болатын, бірақ өте қымбат мәселелерден қорғайды. Көп адам ірі апатты, өртті немесе операцияны өз ақшасымен оңай төлей алмайды."
            },
            {
                "type": "paragraph",
                "text": "Негізгі идея қарапайым: көптеген адам аз мөлшерде ақша төлейді, ал шынымен қиын жағдайға тап болғандарға сақтандыру компаниясы көмектеседі."
            }
        ]
    }'::jsonb
)
on conflict (lesson_step_id, language_code) do update set
    title = excluded.title,
    content = excluded.content;

-- STEP 2

insert into lesson_steps (lesson_id, step_type, order_index)
values (
    (
        select l.id
        from lessons l
        join subtopics s on s.id = l.subtopic_id
        where s.code = 'ins_core_idea'
    ),
    'explanation',
    2
)
on conflict (lesson_id, order_index) do update set
    step_type = excluded.step_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
(
    (
        select ls.id from lesson_steps ls
        join lessons l on l.id = ls.lesson_id
        join subtopics s on s.id = l.subtopic_id
        where s.code = 'ins_core_idea' and ls.order_index = 2
    ),
    'ru',
    'Что важно понимать',
    '{
        "blocks": [
            {
                "type": "bullet_list",
                "items": [
                    "Страховка нужна для крупных рисков, а не мелких расходов",
                    "Чем выше риск — тем выше стоимость полиса",
                    "Есть франшиза, лимиты и исключения",
                    "Не все события покрываются автоматически"
                ]
            },
            {
                "type": "table",
                "headers": ["Ситуация", "Страхование подходит?"],
                "rows": [
                    ["Операция за 3 000 000 ₸", "Да"],
                    ["Потеря телефона за 60 000 ₸", "Не всегда"],
                    ["ДТП с дорогим ремонтом", "Да"],
                    ["Ежедневные расходы", "Нет"]
                ]
            }
        ]
    }'::jsonb
)
on conflict (lesson_step_id, language_code) do update set
    title = excluded.title,
    content = excluded.content;

-- STEP 3

insert into lesson_steps (lesson_id, step_type, order_index)
values (
    (
        select l.id
        from lessons l
        join subtopics s on s.id = l.subtopic_id
        where s.code = 'ins_core_idea'
    ),
    'example',
    3
)
on conflict (lesson_id, order_index) do update set
    step_type = excluded.step_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
(
    (
        select ls.id from lesson_steps ls
        join lessons l on l.id = ls.lesson_id
        join subtopics s on s.id = l.subtopic_id
        where s.code = 'ins_core_idea' and ls.order_index = 3
    ),
    'ru',
    'Пример из жизни',
    '{
        "blocks": [
            {
                "type": "paragraph",
                "text": "Арман платил 8 000 ₸ в месяц за медицинскую страховку. Через год ему понадобилась операция стоимостью 1 800 000 ₸."
            },
            {
                "type": "table",
                "headers": ["Без страховки", "Со страховкой"],
                "rows": [
                    ["1 800 000 ₸ из своих денег", "120 000 ₸ взносов за год"],
                    ["Большой финансовый удар", "Основную сумму покрыла страховая" ]
                ]
            }
        ]
    }'::jsonb
)
on conflict (lesson_step_id, language_code) do update set
    title = excluded.title,
    content = excluded.content;

-- STEP 4

insert into lesson_steps (lesson_id, step_type, order_index)
values (
    (
        select l.id
        from lessons l
        join subtopics s on s.id = l.subtopic_id
        where s.code = 'ins_core_idea'
    ),
    'conclusion',
    4
)
on conflict (lesson_id, order_index) do update set
    step_type = excluded.step_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
(
    (
        select ls.id from lesson_steps ls
        join lessons l on l.id = ls.lesson_id
        join subtopics s on s.id = l.subtopic_id
        where s.code = 'ins_core_idea' and ls.order_index = 4
    ),
    'ru',
    'Главная мысль',
    '{
        "blocks": [
            {
                "type": "paragraph",
                "text": "Страхование не делает вас богаче — оно защищает вас от финансовой катастрофы."
            }
        ]
    }'::jsonb
)
on conflict (lesson_step_id, language_code) do update set
    title = excluded.title,
    content = excluded.content;

commit;
