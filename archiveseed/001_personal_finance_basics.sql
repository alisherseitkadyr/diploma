-- ══════════════════════════════════════════════════════════════
-- 001 — TOPIC: personal_finance_basics
-- Part 1 | Track A | Level: beginner
-- ══════════════════════════════════════════════════════════════

-- ── TOPIC ──────────────────────────────────────────────────────
-- When reseeding an existing local database, legacy beginner topics may still
-- occupy the first ordering slots. Move them aside before inserting the new
-- first topic; the next seed file assigns their final order.
update topics
set order_index = 100000 + id::int,
    updated_at  = now()
where level = 'beginner'
  and code in ('budgeting', 'savings', 'credit_and_debt');

insert into topics (code, level, order_index, is_active) values
    ('personal_finance_basics', 'beginner', 1, true)
on conflict (code) do update set
    level       = excluded.level,
    order_index = excluded.order_index,
    is_active   = excluded.is_active,
    updated_at  = now();

insert into topic_translations (topic_id, language_code, title, description) values
    ((select id from topics where code = 'personal_finance_basics'), 'ru',
        'Основы личных финансов',
        'Как работают деньги в вашей жизни — доход, расходы, сбережения, инвестиции и защита'),
    ((select id from topics where code = 'personal_finance_basics'), 'en',
        'Personal Finance Basics',
        'How money works in your life — earn, spend, save, invest, and protect'),
    ((select id from topics where code = 'personal_finance_basics'), 'kk',
        'Жеке қаржының негіздері',
        'Өміріңіздегі ақша қалай жұмыс істейді — табыс, шығын, жинақ, инвестиция және қорғаныс')
on conflict (topic_id, language_code) do update set
    title       = excluded.title,
    description = excluded.description;

-- ── SUBTOPICS ──────────────────────────────────────────────────
insert into subtopics (topic_id, code, order_index, estimated_minutes, is_active) values
    ((select id from topics where code = 'personal_finance_basics'), 'pf_five_areas',   1, 3, true),
    ((select id from topics where code = 'personal_finance_basics'), 'pf_income_types', 2, 4, true),
    ((select id from topics where code = 'personal_finance_basics'), 'pf_net_worth',    3, 4, true),
    ((select id from topics where code = 'personal_finance_basics'), 'pf_smart_goals',  4, 5, true)
on conflict (code) do update set
    order_index       = excluded.order_index,
    estimated_minutes = excluded.estimated_minutes,
    is_active         = excluded.is_active,
    updated_at        = now();

insert into subtopic_translations (subtopic_id, language_code, title) values
    -- ru
    ((select id from subtopics where code = 'pf_five_areas'),   'ru', 'Пять областей личных финансов'),
    ((select id from subtopics where code = 'pf_income_types'), 'ru', 'Виды дохода'),
    ((select id from subtopics where code = 'pf_net_worth'),    'ru', 'Чистый капитал'),
    ((select id from subtopics where code = 'pf_smart_goals'),  'ru', 'Финансовые цели'),
    -- en
    ((select id from subtopics where code = 'pf_five_areas'),   'en', 'The Five Areas of Personal Finance'),
    ((select id from subtopics where code = 'pf_income_types'), 'en', 'Income Types'),
    ((select id from subtopics where code = 'pf_net_worth'),    'en', 'Net Worth'),
    ((select id from subtopics where code = 'pf_smart_goals'),  'en', 'Financial Goals'),
    -- kk
    ((select id from subtopics where code = 'pf_five_areas'),   'kk', 'Жеке қаржының бес саласы'),
    ((select id from subtopics where code = 'pf_income_types'), 'kk', 'Табыс түрлері'),
    ((select id from subtopics where code = 'pf_net_worth'),    'kk', 'Таза капитал'),
    ((select id from subtopics where code = 'pf_smart_goals'),  'kk', 'Қаржылық мақсаттар')
on conflict (subtopic_id, language_code) do update set title = excluded.title;

-- ── LESSONS (shells — content added in 003) ────────────────────
insert into lessons (subtopic_id, is_published)
select id, true from subtopics where code in (
    'pf_five_areas', 'pf_income_types', 'pf_net_worth', 'pf_smart_goals'
)
on conflict (subtopic_id) do update set is_published = excluded.is_published;

insert into quizzes (subtopic_code, topic_code, quiz_type, passing_score, is_active) values
    (null, 'personal_finance_basics', 'topic_final_quiz', 75, true)
on conflict (topic_code) where quiz_type = 'topic_final_quiz' do update set
    passing_score = excluded.passing_score,
    is_active     = excluded.is_active,
    updated_at    = now();

insert into quiz_translations (quiz_id, language_code, title) values
    ((select id from quizzes where topic_code = 'personal_finance_basics' and quiz_type = 'topic_final_quiz'),
        'ru', 'Итоговый квиз: Основы личных финансов'),
    ((select id from quizzes where topic_code = 'personal_finance_basics' and quiz_type = 'topic_final_quiz'),
        'en', 'Final Quiz: Personal Finance Basics'),
    ((select id from quizzes where topic_code = 'personal_finance_basics' and quiz_type = 'topic_final_quiz'),
        'kk', 'Қорытынды тест: Жеке қаржының негіздері')
on conflict (quiz_id, language_code) do update set title = excluded.title;


-- ══════════════════════════════════════════════════════════════
-- 002 — QUIZ QUESTIONS: personal_finance_basics
-- 4 subtopics × 3 questions each = 12 questions total
-- ══════════════════════════════════════════════════════════════


-- ── SUBTOPIC: pf_five_areas ────────────────────────────────────

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('pf_five_areas', 70, '[
        {"lang":"ru","title":"Квиз: Пять областей личных финансов"},
        {"lang":"en","title":"Quiz: The Five Areas of Personal Finance"},
        {"lang":"kk","title":"Тест: Жеке қаржының бес саласы"}
    ]'::jsonb);

    -- Q1: single_choice
    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Айгерим получает зарплату и тратит почти всё. Какую из пяти областей личных финансов она игнорирует?"},
          {"lang":"en","text":"Aigеrim earns a salary and spends almost everything. Which of the five areas of personal finance is she ignoring?"},
          {"lang":"kk","text":"Айгерім жалақы алып, барлығын дерлік жұмсайды. Ол жеке қаржының бес саласының қайсысын елемейді?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Заработок"},
              {"lang":"en","text":"Earning"},
              {"lang":"kk","text":"Табыс"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Расходы"},
              {"lang":"en","text":"Spending"},
              {"lang":"kk","text":"Шығын"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"Сбережения, инвестиции и защита"},
              {"lang":"en","text":"Saving, investing, and protecting"},
              {"lang":"kk","text":"Жинақтау, инвестиция және қорғаныс"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только защита"},
              {"lang":"en","text":"Protection only"},
              {"lang":"kk","text":"Тек қорғаныс"}]}]'::jsonb);

    -- Q2: true_false
    perform seed_quiz_question(v, 2, 'true_false',
        '[{"lang":"ru","text":"Страхование и экстренный фонд относятся к области «Защита» в личных финансах."},
          {"lang":"en","text":"Insurance and an emergency fund belong to the ''Protect'' area of personal finance."},
          {"lang":"kk","text":"Сақтандыру мен төтенше қор жеке қаржының «Қорғаныс» саласына жатады."}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Верно"},
              {"lang":"en","text":"True"},
              {"lang":"kk","text":"Дұрыс"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Неверно"},
              {"lang":"en","text":"False"},
              {"lang":"kk","text":"Дұрыс емес"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только страхование"},
              {"lang":"en","text":"Insurance only"},
              {"lang":"kk","text":"Тек сақтандыру"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только экстренный фонд"},
              {"lang":"en","text":"Emergency fund only"},
              {"lang":"kk","text":"Тек төтенше қор"}]}]'::jsonb);

    -- Q3: single_choice
    perform seed_quiz_question(v, 3, 'single_choice',
        '[{"lang":"ru","text":"Большинство людей управляют только одной из пяти областей личных финансов. Какой?"},
          {"lang":"en","text":"Most people actively manage only one of the five areas of personal finance. Which one?"},
          {"lang":"kk","text":"Адамдардың көпшілігі жеке қаржының тек бір саласын басқарады. Қайсысын?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Инвестиции"},
              {"lang":"en","text":"Investing"},
              {"lang":"kk","text":"Инвестиция"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Расходы"},
              {"lang":"en","text":"Spending"},
              {"lang":"kk","text":"Шығын"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Сбережения"},
              {"lang":"en","text":"Saving"},
              {"lang":"kk","text":"Жинақтау"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Защита"},
              {"lang":"en","text":"Protecting"},
              {"lang":"kk","text":"Қорғаныс"}]}]'::jsonb);
end $$;


-- ── SUBTOPIC: pf_income_types ──────────────────────────────────

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('pf_income_types', 70, '[
        {"lang":"ru","title":"Квиз: Виды дохода"},
        {"lang":"en","title":"Quiz: Income Types"},
        {"lang":"kk","title":"Тест: Табыс түрлері"}
    ]'::jsonb);

    -- Q1: single_choice
    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Арман получает 400 000 тенге в месяц по трудовому договору. После удержания ИПН и ОПВ на счёт приходит 328 000 тенге. Какую сумму он должен использовать при составлении бюджета?"},
          {"lang":"en","text":"Arman''s contract says 400,000 KZT/month. After income tax and pension deductions, 328,000 KZT arrives in his account. Which figure should he budget from?"},
          {"lang":"kk","text":"Арманның шартында 400 000 теңге/ай деп жазылған. Салық пен ЗЖЖ шегерімінен кейін шотына 328 000 теңге келеді. Ол бюджет жасау үшін қай соманы пайдалануы керек?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"400 000 тенге — это его официальная зарплата"},
              {"lang":"en","text":"400,000 KZT — that is his official salary"},
              {"lang":"kk","text":"400 000 теңге — бұл оның ресми жалақысы"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"328 000 тенге — это реальные деньги на руках"},
              {"lang":"en","text":"328,000 KZT — that is the money he actually has"},
              {"lang":"kk","text":"328 000 теңге — бұл оның қолындағы нақты ақша"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Среднее из двух сумм"},
              {"lang":"en","text":"The average of both figures"},
              {"lang":"kk","text":"Екі соманың орташасы"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"400 000 минус только аренда жилья"},
              {"lang":"en","text":"400,000 minus rent only"},
              {"lang":"kk","text":"400 000 минус тек жалдау ақысы"}]}]'::jsonb);

    -- Q2: single_choice
    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Айда сдаёт две квартиры и каждый месяц получает 120 000 тенге без какой-либо дополнительной работы. Как называется этот вид дохода?"},
          {"lang":"en","text":"Aida owns two apartments and receives 120,000 KZT every month without doing extra work. What type of income is this?"},
          {"lang":"kk","text":"Айда екі пәтер жалға береді және қосымша жұмыссыз ай сайын 120 000 теңге алады. Бұл табыстың қандай түрі?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Активный доход — она владелец квартир"},
              {"lang":"en","text":"Active income — she owns the apartments"},
              {"lang":"kk","text":"Белсенді табыс — ол пәтерлердің иесі"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Пассивный доход — поступает без постоянных усилий"},
              {"lang":"en","text":"Passive income — arrives without ongoing effort"},
              {"lang":"kk","text":"Пассивті табыс — үнемі күш жұмсамай-ақ түседі"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Валовый доход"},
              {"lang":"en","text":"Gross income"},
              {"lang":"kk","text":"Жалпы табыс"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Бонусный доход"},
              {"lang":"en","text":"Bonus income"},
              {"lang":"kk","text":"Бонустық табыс"}]}]'::jsonb);

    -- Q3: true_false
    perform seed_quiz_question(v, 3, 'true_false',
        '[{"lang":"ru","text":"Пассивный доход требует либо стартового капитала, либо времени на создание — это долгосрочная стратегия, а не быстрый способ разбогатеть."},
          {"lang":"en","text":"Passive income requires either upfront capital or time to build — it is a long-term strategy, not a quick fix."},
          {"lang":"kk","text":"Пассивті табыс бастапқы капиталды немесе уақытты талап етеді — бұл ұзақмерзімді стратегия, жылдам байып кету жолы емес."}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Верно"},
              {"lang":"en","text":"True"},
              {"lang":"kk","text":"Дұрыс"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Неверно"},
              {"lang":"en","text":"False"},
              {"lang":"kk","text":"Дұрыс емес"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только если у вас есть недвижимость"},
              {"lang":"en","text":"Only if you own property"},
              {"lang":"kk","text":"Тек жылжымайтын мүлік болса ғана"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Пассивный доход возможен без вложений"},
              {"lang":"en","text":"Passive income is possible without any investment"},
              {"lang":"kk","text":"Пассивті табысқа салымсыз қол жеткізуге болады"}]}]'::jsonb);
end $$;


-- ── SUBTOPIC: pf_net_worth ─────────────────────────────────────

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('pf_net_worth', 70, '[
        {"lang":"ru","title":"Квиз: Чистый капитал"},
        {"lang":"en","title":"Quiz: Net Worth"},
        {"lang":"kk","title":"Тест: Таза капитал"}
    ]'::jsonb);

    -- Q1: single_choice
    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Как рассчитывается чистый капитал?"},
          {"lang":"en","text":"How is net worth calculated?"},
          {"lang":"kk","text":"Таза капитал қалай есептеледі?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Доходы минус расходы"},
              {"lang":"en","text":"Income minus expenses"},
              {"lang":"kk","text":"Табыс минус шығын"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Сбережения плюс инвестиции"},
              {"lang":"en","text":"Savings plus investments"},
              {"lang":"kk","text":"Жинақ плюс инвестиция"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"Активы минус обязательства"},
              {"lang":"en","text":"Assets minus liabilities"},
              {"lang":"kk","text":"Активтер минус міндеттемелер"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Зарплата минус налоги"},
              {"lang":"en","text":"Salary minus taxes"},
              {"lang":"kk","text":"Жалақы минус салықтар"}]}]'::jsonb);

    -- Q2: single_choice
    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Два человека зарабатывают по 400 000 тенге в месяц. У первого накоплений на 500 000 и нет долгов. У второго накоплений на 50 000, но автокредит на 2 000 000. Чей чистый капитал выше?"},
          {"lang":"en","text":"Two people earn 400,000 KZT/month. Person A has 500,000 in savings and no debt. Person B has 50,000 in savings but a 2,000,000 car loan. Whose net worth is higher?"},
          {"lang":"kk","text":"Екі адам айына 400 000 теңге табады. Біріншісінде 500 000 жинақ бар, қарызы жоқ. Екіншісінде 50 000 жинақ, бірақ 2 000 000 автокредит бар. Кімнің таза капиталы жоғары?"}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Первый — у него нет долгов"},
              {"lang":"en","text":"Person A — they have no debt"},
              {"lang":"kk","text":"Біріншісі — оның қарызы жоқ"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Второй — у него дорогая машина"},
              {"lang":"en","text":"Person B — they have an expensive car"},
              {"lang":"kk","text":"Екіншісі — оның қымбат көлігі бар"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Они равны — у обоих одинаковая зарплата"},
              {"lang":"en","text":"They are equal — both earn the same"},
              {"lang":"kk","text":"Тең — екеуінің де жалақысы бірдей"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Невозможно определить по этим данным"},
              {"lang":"en","text":"Impossible to tell from this information"},
              {"lang":"kk","text":"Бұл деректер бойынша анықтау мүмкін емес"}]}]'::jsonb);

    -- Q3: multiple_choice
    perform seed_quiz_question(v, 3, 'multiple_choice',
        '[{"lang":"ru","text":"Что из перечисленного относится к активам при расчёте чистого капитала? (выберите все верные ответы)"},
          {"lang":"en","text":"Which of the following count as assets when calculating net worth? (select all that apply)"},
          {"lang":"kk","text":"Таза капиталды есептеу кезінде төмендегілердің қайсысы активтерге жатады? (барлық дұрыс жауапты белгілеңіз)"}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Накопления на банковском счёте"},
              {"lang":"en","text":"Savings in a bank account"},
              {"lang":"kk","text":"Банк шотындағы жинақ"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Остаток по потребительскому кредиту"},
              {"lang":"en","text":"Outstanding consumer loan balance"},
              {"lang":"kk","text":"Тұтынушылық несиенің қалдығы"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"Рыночная стоимость автомобиля"},
              {"lang":"en","text":"Current market value of a car"},
              {"lang":"kk","text":"Автомобильдің нарықтық құны"}]},
          {"order_index":4,"is_correct":true,"translations":[
              {"lang":"ru","text":"Инвестиции в акции и фонды"},
              {"lang":"en","text":"Investments in stocks and funds"},
              {"lang":"kk","text":"Акциялар мен қорларға салынған инвестиция"}]}]'::jsonb);
end $$;


-- ── SUBTOPIC: pf_smart_goals ───────────────────────────────────

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('pf_smart_goals', 70, '[
        {"lang":"ru","title":"Квиз: Финансовые цели"},
        {"lang":"en","title":"Quiz: Financial Goals"},
        {"lang":"kk","title":"Тест: Қаржылық мақсаттар"}
    ]'::jsonb);

    -- Q1: single_choice
    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Айша написала: «Хочу откладывать больше денег». Почему это не финансовая цель?"},
          {"lang":"en","text":"Aisha wrote: ''I want to save more money.'' Why is this not a financial goal?"},
          {"lang":"kk","text":"Айша: «Көбірек ақша жинағым келеді» деп жазды. Бұл неліктен қаржылық мақсат емес?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Сбережения — плохая идея"},
              {"lang":"en","text":"Saving money is a bad idea"},
              {"lang":"kk","text":"Ақша жинау жаман идея"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Нет конкретной суммы и срока — невозможно отследить прогресс"},
              {"lang":"en","text":"No specific amount or deadline — progress cannot be tracked"},
              {"lang":"kk","text":"Нақты сома мен мерзім жоқ — прогресті бақылау мүмкін емес"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Нужно сначала погасить все долги"},
              {"lang":"en","text":"She needs to pay off all debts first"},
              {"lang":"kk","text":"Алдымен барлық қарыздарды өтеу керек"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Сбережения — это долгосрочная цель, а не краткосрочная"},
              {"lang":"en","text":"Saving is a long-term goal, not a short-term one"},
              {"lang":"kk","text":"Жинақтау қысқамерзімді емес, ұзақмерзімді мақсат"}]}]'::jsonb);

    -- Q2: single_choice
    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"У Айши нет экстренного фонда и есть долг по кредитной карте под 28% годовых. Неожиданно она получает 80 000 тенге. Что финансово грамотнее всего?"},
          {"lang":"en","text":"Aisha has no emergency fund and carries credit card debt at 28% APR. She receives an unexpected 80,000 KZT. What is the most financially sound choice?"},
          {"lang":"kk","text":"Айшаның төтенше қоры жоқ және 28% жылдық кредиттік карта қарызы бар. Ол кенеттен 80 000 теңге алды. Қаржылық тұрғыдан ең дұрыс шешім қандай?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Положить всё в накопительный счёт для машины"},
              {"lang":"en","text":"Put it all into the car savings fund"},
              {"lang":"kk","text":"Барлығын көлікке арналған жинақ шотына салу"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Потратить на давно запланированный отпуск"},
              {"lang":"en","text":"Spend it on a long-overdue holiday"},
              {"lang":"kk","text":"Ұзақ күтілген демалыста жұмсау"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"Сначала погасить часть долга под 28%, затем пополнить экстренный фонд"},
              {"lang":"en","text":"First pay down the 28% debt, then top up the emergency fund"},
              {"lang":"kk","text":"Алдымен 28% қарызды өтеп, содан кейін төтенше қорды толықтыру"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Инвестировать в акции — доходность выше 28%"},
              {"lang":"en","text":"Invest in stocks — returns beat 28%"},
              {"lang":"kk","text":"Акцияларға инвестиция салу — кіріс 28%-дан жоғары"}]}]'::jsonb);

    -- Q3: single_choice
    perform seed_quiz_question(v, 3, 'single_choice',
        '[{"lang":"ru","text":"Что из перечисленного является примером долгосрочной финансовой цели?"},
          {"lang":"en","text":"Which of the following is an example of a long-term financial goal?"},
          {"lang":"kk","text":"Төмендегілердің қайсысы ұзақмерзімді қаржылық мақсаттың мысалы болып табылады?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Накопить 50 000 тенге на подарок другу за 2 месяца"},
              {"lang":"en","text":"Save 50,000 KZT for a friend''s gift in 2 months"},
              {"lang":"kk","text":"2 айда досқа сыйлыққа 50 000 теңге жинау"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Закрыть долг по кредитной карте за 8 месяцев"},
              {"lang":"en","text":"Pay off a credit card in 8 months"},
              {"lang":"kk","text":"Кредиттік картаның қарызын 8 айда жабу"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Накопить на первоначальный взнос за квартиру за 3 года"},
              {"lang":"en","text":"Save for an apartment down payment in 3 years"},
              {"lang":"kk","text":"3 жылда пәтерге бастапқы жарна жинау"}]},
          {"order_index":4,"is_correct":true,"translations":[
              {"lang":"ru","text":"Создать капитал, достаточный для выхода на пенсию в 60 лет"},
              {"lang":"en","text":"Build enough capital to retire at 60"},
              {"lang":"kk","text":"60 жасында зейнетке шығуға жеткілікті капитал жасақтау"}]}]'::jsonb);
end $$;


-- ══════════════════════════════════════════════════════════════
-- 003 — LESSON STEPS: personal_finance_basics
-- 4 subtopics × 4 steps each × 3 languages = 48 translation rows
-- ══════════════════════════════════════════════════════════════

begin;

-- ══════════════════════════════════════════════════════════════
-- SUBTOPIC: pf_five_areas
-- "The Five Areas of Personal Finance"
-- 📖 Read | 3 min
-- Steps: introduction → explanation → example → conclusion
-- ══════════════════════════════════════════════════════════════

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 1),
     'ru', 'Введение',
     '{"blocks": [
         {"type": "paragraph", "text": "Личные финансы — это не про богатство. Это про осознанные решения с теми деньгами, которые у вас есть — сколько бы их ни было."},
         {"type": "paragraph", "text": "Большинство людей управляют деньгами случайно. Эти четыре урока дадут вам систему."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 1),
     'en', 'Introduction',
     '{"blocks": [
         {"type": "paragraph", "text": "Personal finance is not about being rich. It is about making deliberate decisions with the money you have — however much or little that is."},
         {"type": "paragraph", "text": "Most people manage money by accident. These four lessons give you a system."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 1),
     'kk', 'Кіріспе',
     '{"blocks": [
         {"type": "paragraph", "text": "Жеке қаржы бай болу туралы емес. Бұл қолыңыздағы ақшамен саналы шешім қабылдау туралы — қанша болса да."},
         {"type": "paragraph", "text": "Адамдардың көпшілігі ақшаны кездейсоқ басқарады. Осы төрт сабақ сізге жүйе береді."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 2: explanation ────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 2),
     'ru', 'Пять областей',
     '{"blocks": [
         {"type": "paragraph", "text": "Всё, что касается денег в вашей жизни, попадает в одну из пяти областей:"},
         {"type": "bullet_list", "items": [
             "Заработок — откуда приходят деньги: работа, подработки, инвестиции",
             "Расходы — куда уходят деньги: жильё, еда, развлечения",
             "Сбережения — что вы оставляете себе до того, как потратить",
             "Инвестиции — как сбережения работают и растут со временем",
             "Защита — страховки, экстренный фонд, завещание"
         ]},
         {"type": "paragraph", "text": "Большинство людей думают только о расходах. Финансово здоровый человек выстраивает систему по всем пяти."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 2),
     'en', 'The Five Areas',
     '{"blocks": [
         {"type": "paragraph", "text": "Everything money-related in your life falls into one of five areas:"},
         {"type": "bullet_list", "items": [
             "Earn — where money comes from: job, side work, investments",
             "Spend — where money goes: housing, food, entertainment",
             "Save — what you keep before spending anything",
             "Invest — making saved money grow over time",
             "Protect — insurance, emergency fund, estate plan"
         ]},
         {"type": "paragraph", "text": "Most people only think about spending. A financially healthy person builds a system across all five."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 2),
     'kk', 'Бес сала',
     '{"blocks": [
         {"type": "paragraph", "text": "Өміріңіздегі ақшаға қатысты барлық нәрсе бес салалардың біріне жатады:"},
         {"type": "bullet_list", "items": [
             "Табыс — ақша қайдан келеді: жұмыс, қосымша жұмыс, инвестиция",
             "Шығын — ақша қайда кетеді: тұрғын үй, тамақ, ойын-сауық",
             "Жинақ — жұмсамас бұрын өзіңізге қалдыратын бөлік",
             "Инвестиция — жинақтың уақыт өте өсуі",
             "Қорғаныс — сақтандыру, төтенше қор, мұрагерлік"
         ]},
         {"type": "paragraph", "text": "Адамдардың көпшілігі тек шығын туралы ойлайды. Қаржылық жағынан сау адам барлық бес бойынша жүйе құрады."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 3: example ───────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 3),
     'ru', 'Пример',
     '{"blocks": [
         {"type": "paragraph", "text": "Арман и Дания зарабатывают одинаково — 350 000 тенге в месяц."},
         {"type": "table", "headers": ["Область", "Арман", "Дания"], "rows": [
             ["Заработок", "350 000 ₸", "350 000 ₸"],
             ["Расходы", "340 000 ₸ (почти всё)", "240 000 ₸ (68%)"],
             ["Сбережения", "10 000 ₸ (случайно)", "60 000 ₸ (автоматически)"],
             ["Инвестиции", "Нет", "40 000 ₸/мес в фонды"],
             ["Защита", "Нет", "Страховка + экстренный фонд"]
         ]},
         {"type": "paragraph", "text": "Через 5 лет Дания будет в совершенно другом финансовом положении — при той же зарплате."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 3),
     'en', 'Example',
     '{"blocks": [
         {"type": "paragraph", "text": "Arman and Daniya both earn 350,000 KZT per month."},
         {"type": "table", "headers": ["Area", "Arman", "Daniya"], "rows": [
             ["Earn", "350,000 ₸", "350,000 ₸"],
             ["Spend", "340,000 ₸ (almost all)", "240,000 ₸ (68%)"],
             ["Save", "10,000 ₸ (by accident)", "60,000 ₸ (automated)"],
             ["Invest", "Nothing", "40,000 ₸/mo into index funds"],
             ["Protect", "Nothing", "Insurance + emergency fund"]
         ]},
         {"type": "paragraph", "text": "In five years, Daniya will be in a completely different financial position — on the exact same salary."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 3),
     'kk', 'Мысал',
     '{"blocks": [
         {"type": "paragraph", "text": "Арман мен Дания екеуі де айына 350 000 теңге табады."},
         {"type": "table", "headers": ["Сала", "Арман", "Дания"], "rows": [
             ["Табыс", "350 000 ₸", "350 000 ₸"],
             ["Шығын", "340 000 ₸ (барлығы дерлік)", "240 000 ₸ (68%)"],
             ["Жинақ", "10 000 ₸ (кездейсоқ)", "60 000 ₸ (автоматты)"],
             ["Инвестиция", "Жоқ", "Айына 40 000 ₸ индекс қорларына"],
             ["Қорғаныс", "Жоқ", "Сақтандыру + төтенше қор"]
         ]},
         {"type": "paragraph", "text": "Бес жылдан кейін Дания дәл сол жалақымен мүлдем басқа қаржылық жағдайда болады."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 4: conclusion ────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 4),
     'ru', 'Главное',
     '{"blocks": [
         {"type": "paragraph", "text": "Личные финансы = что вы зарабатываете, что тратите, что сберегаете, во что инвестируете и как защищаете. Упустите хотя бы одну область — система даёт течь."},
         {"type": "paragraph", "text": "В следующем уроке разберёмся с доходом: какая цифра реально имеет значение."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 4),
     'en', 'Key Takeaway',
     '{"blocks": [
         {"type": "paragraph", "text": "Personal finance = what you earn, spend, save, invest, and protect. Miss any one of these, and the whole system leaks."},
         {"type": "paragraph", "text": "Next lesson: income — which number actually matters."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_five_areas' and ls.order_index = 4),
     'kk', 'Негізгі қорытынды',
     '{"blocks": [
         {"type": "paragraph", "text": "Жеке қаржы = табыс, шығын, жинақ, инвестиция және қорғаныс. Осылардың кез келгенін жіберіп алсаңыз — жүйеде тесік пайда болады."},
         {"type": "paragraph", "text": "Келесі сабақта табыс туралы сөйлесеміз: қандай сан шынымен маңызды."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;


-- ══════════════════════════════════════════════════════════════
-- SUBTOPIC: pf_income_types
-- "Income Types"
-- 📖 Read + ❓ Quiz | 4 min
-- Steps: introduction → explanation → example → conclusion
-- ══════════════════════════════════════════════════════════════

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 1),
     'ru', 'Введение',
     '{"blocks": [
         {"type": "paragraph", "text": "Прежде чем управлять деньгами, нужно понять, как они к вам попадают — и что реально остаётся в вашем распоряжении."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 1),
     'en', 'Introduction',
     '{"blocks": [
         {"type": "paragraph", "text": "Before you can manage money, you need to understand how it arrives — and what you actually have to work with."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 1),
     'kk', 'Кіріспе',
     '{"blocks": [
         {"type": "paragraph", "text": "Ақшаны басқармас бұрын, ол қалай келетінін — және сіздің қолыңызда не қалатынын — түсіну керек."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 2 ────────────────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 2),
     'ru', 'Виды дохода',
     '{"blocks": [
         {"type": "paragraph", "text": "Активный доход — деньги, которые вы получаете за работу. Зарплата, фриланс, подработки. Перестали работать — доход остановился. Большинство людей живут только на активный доход."},
         {"type": "paragraph", "text": "Пассивный доход поступает без постоянных усилий. Аренда квартиры, дивиденды по акциям, проценты по вкладам. Требует времени или стартового капитала — зато работает, пока вы спите."},
         {"type": "paragraph", "text": "Валовый доход — сумма в трудовом договоре. Звучит красиво. Чистый доход (take-home) — то, что реально приходит на карту после налогов и пенсионных отчислений. Разница может составлять 20–40%."},
         {"type": "paragraph", "text": "Бюджет строится только на чистом доходе. Всегда."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 2),
     'en', 'Income Types',
     '{"blocks": [
         {"type": "paragraph", "text": "Active income is money you earn by doing work. Salary, freelance, gig work. Stop working — income stops. Most people live entirely on active income."},
         {"type": "paragraph", "text": "Passive income arrives without ongoing effort. Rental income, stock dividends, savings interest. Requires upfront time or capital — but earns while you sleep."},
         {"type": "paragraph", "text": "Gross income is the number in your contract. It sounds impressive. Net income (take-home) is what actually lands in your account after taxes and deductions. The gap can be 20–40%."},
         {"type": "paragraph", "text": "Every budget must be built on net income. Always."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 2),
     'kk', 'Табыс түрлері',
     '{"blocks": [
         {"type": "paragraph", "text": "Белсенді табыс — жұмыс жасап табатын ақша. Жалақы, фриланс, қосымша жұмыс. Жұмысты тоқтатсаңыз — табыс та тоқтайды. Адамдардың көпшілігі тек белсенді табыспен өмір сүреді."},
         {"type": "paragraph", "text": "Пассивті табыс үнемі күш жұмсамай-ақ түседі. Жалдау ақысы, акция дивидендтері, депозит сыйақысы. Бастапқы уақыт немесе капитал керек — бірақ сіз ұйықтап жатқанда да жұмыс істейді."},
         {"type": "paragraph", "text": "Жалпы табыс — шартыңыздағы сан. Таза табыс — салықтар мен шегерімдерден кейін шотыңызға түсетін нақты ақша. Айырмашылық 20–40% болуы мүмкін."},
         {"type": "paragraph", "text": "Бюджет тек таза табыс негізінде жасалады. Әрқашан."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 3 ────────────────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 3),
     'ru', 'Пример',
     '{"blocks": [
         {"type": "paragraph", "text": "Арман получает 400 000 тенге по договору. После удержания ИПН (10%) и ОПВ (10%) на счёт приходит 328 000 тенге."},
         {"type": "table", "headers": ["", "Сумма"], "rows": [
             ["Валовый доход", "400 000 ₸"],
             ["Минус ОПВ (10%)", "− 40 000 ₸"],
             ["Минус ИПН (~8% от базы)", "− 32 000 ₸"],
             ["Чистый доход на руки", "≈ 328 000 ₸"]
         ]},
         {"type": "paragraph", "text": "Арман должен строить бюджет от 328 000, а не от 400 000. Иначе каждый месяц будет дефицит."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 3),
     'en', 'Example',
     '{"blocks": [
         {"type": "paragraph", "text": "Arman''s contract says 400,000 KZT. After pension contribution (10%) and income tax (~8% of the taxable base), he receives approximately 328,000 KZT."},
         {"type": "table", "headers": ["", "Amount"], "rows": [
             ["Gross income", "400,000 ₸"],
             ["Minus pension (10%)", "− 40,000 ₸"],
             ["Minus income tax (~8%)", "− 32,000 ₸"],
             ["Net take-home", "≈ 328,000 ₸"]
         ]},
         {"type": "paragraph", "text": "Arman must budget from 328,000 — not 400,000. Otherwise, every month ends in a shortfall."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 3),
     'kk', 'Мысал',
     '{"blocks": [
         {"type": "paragraph", "text": "Арманның шартында 400 000 теңге деп жазылған. ЗЖЖ (10%) және ЖТС (~8%) шегерімінен кейін шотына шамамен 328 000 теңге келеді."},
         {"type": "table", "headers": ["", "Сома"], "rows": [
             ["Жалпы табыс", "400 000 ₸"],
             ["Минус ЗЖЖ (10%)", "− 40 000 ₸"],
             ["Минус ЖТС (~8%)", "− 32 000 ₸"],
             ["Қолдағы таза табыс", "≈ 328 000 ₸"]
         ]},
         {"type": "paragraph", "text": "Арман бюджетін 400 000-нан емес, 328 000-нан бастап жасауы керек. Әйтпесе ай сайын тапшылық болады."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 4 ────────────────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 4),
     'ru', 'Главное',
     '{"blocks": [
         {"type": "paragraph", "text": "Чистый доход — ваше реальное число. Валовый — цифра на бумаге, которую нельзя потратить. Всегда планируйте от чистого."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 4),
     'en', 'Key Takeaway',
     '{"blocks": [
         {"type": "paragraph", "text": "Net income is your real number. Gross is a fiction you cannot spend. Always plan from net."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_income_types' and ls.order_index = 4),
     'kk', 'Негізгі қорытынды',
     '{"blocks": [
         {"type": "paragraph", "text": "Таза табыс — сіздің нақты санаңыз. Жалпы табыс — жұмсауға болмайтын қағаздағы сан. Әрқашан таза табыстан жоспарлаңыз."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;


-- ══════════════════════════════════════════════════════════════
-- SUBTOPIC: pf_net_worth
-- "Net Worth"
-- 🎮 Simulator | 4 min
-- Steps: introduction → explanation → example → interactive
-- ══════════════════════════════════════════════════════════════

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 1),
     'ru', 'Введение',
     '{"blocks": [
         {"type": "paragraph", "text": "Почти все знают свою зарплату. Почти никто не знает свой чистый капитал — хотя это гораздо важнее."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 1),
     'en', 'Introduction',
     '{"blocks": [
         {"type": "paragraph", "text": "Almost everyone knows their salary. Almost nobody knows their net worth — which is the more important number."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 1),
     'kk', 'Кіріспе',
     '{"blocks": [
         {"type": "paragraph", "text": "Барлығы дерлік өз жалақысын біледі. Ал таза капиталын — мүлдем аз адам біледі. Бірақ ол маңыздырақ."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 2 ────────────────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 2),
     'ru', 'Формула',
     '{"blocks": [
         {"type": "paragraph", "text": "Чистый капитал = Активы − Обязательства"},
         {"type": "bullet_list", "items": [
             "Активы — всё, что имеет денежную ценность: наличные, вклады, инвестиции, недвижимость, рыночная стоимость авто",
             "Обязательства — всё, что вы должны: кредиты, долг по карте, ипотека"
         ]},
         {"type": "paragraph", "text": "Два человека с одинаковой зарплатой могут иметь кардинально разный чистый капитал. Зарплата — это поток. Чистый капитал — это счёт."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 2),
     'en', 'The Formula',
     '{"blocks": [
         {"type": "paragraph", "text": "Net Worth = Assets − Liabilities"},
         {"type": "bullet_list", "items": [
             "Assets — anything with monetary value: cash, savings, investments, property, car resale value",
             "Liabilities — everything you owe: loans, credit card debt, mortgage balance"
         ]},
         {"type": "paragraph", "text": "Two people with the same salary can have completely different net worth. Salary is a flow. Net worth is the score."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 2),
     'kk', 'Формула',
     '{"blocks": [
         {"type": "paragraph", "text": "Таза капитал = Активтер − Міндеттемелер"},
         {"type": "bullet_list", "items": [
             "Активтер — ақшалай құны бар нәрселер: қолма-қол ақша, жинақ, инвестиция, жылжымайтын мүлік, көліктің нарықтық бағасы",
             "Міндеттемелер — барлық қарыз: несиелер, кредиттік карта қарызы, ипотека"
         ]},
         {"type": "paragraph", "text": "Бірдей жалақысы бар екі адамның таза капиталы мүлдем басқаша болуы мүмкін. Жалақы — ағын. Таза капитал — ұпай."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 3: example ───────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 3),
     'ru', 'Пример',
     '{"blocks": [
         {"type": "table", "headers": ["", "Человек А", "Человек Б"], "rows": [
             ["Зарплата", "400 000 ₸", "400 000 ₸"],
             ["Накопления", "500 000 ₸", "50 000 ₸"],
             ["Автокредит", "0 ₸", "2 000 000 ₸"],
             ["Чистый капитал", "+500 000 ₸", "−1 950 000 ₸"]
         ]},
         {"type": "paragraph", "text": "Одинаковая зарплата. Совершенно разная финансовая реальность. Чистый капитал делает разницу видимой."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 3),
     'en', 'Example',
     '{"blocks": [
         {"type": "table", "headers": ["", "Person A", "Person B"], "rows": [
             ["Salary", "400,000 ₸", "400,000 ₸"],
             ["Savings", "500,000 ₸", "50,000 ₸"],
             ["Car loan", "0 ₸", "2,000,000 ₸"],
             ["Net worth", "+500,000 ₸", "−1,950,000 ₸"]
         ]},
         {"type": "paragraph", "text": "Same salary. Completely different financial reality. Net worth makes the difference visible."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 3),
     'kk', 'Мысал',
     '{"blocks": [
         {"type": "table", "headers": ["", "А адамы", "Б адамы"], "rows": [
             ["Жалақы", "400 000 ₸", "400 000 ₸"],
             ["Жинақ", "500 000 ₸", "50 000 ₸"],
             ["Автокредит", "0 ₸", "2 000 000 ₸"],
             ["Таза капитал", "+500 000 ₸", "−1 950 000 ₸"]
         ]},
         {"type": "paragraph", "text": "Бірдей жалақы. Мүлдем басқаша қаржылық шындық. Таза капитал айырмашылықты көрінетін етеді."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 4: interactive (calculator) ─────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index, interactive_type)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth'), 'interactive', 4, 'net_worth_calculator')
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content, interactive_content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 4),
     'ru', 'Посчитайте свой чистый капитал',
     '{"blocks": [{"type": "paragraph", "text": "Введите свои данные. Даже если результат будет отрицательным — это ваша точка отсчёта."}]}'::jsonb,
     '{"inputs": [
         {"key": "cash",        "label": "Наличные и счета в банке",  "group": "assets"},
         {"key": "investments", "label": "Инвестиции",                 "group": "assets"},
         {"key": "property",    "label": "Недвижимость",               "group": "assets"},
         {"key": "vehicle",     "label": "Авто (рыночная стоимость)",  "group": "assets"},
         {"key": "loans",       "label": "Кредиты и займы",            "group": "liabilities"},
         {"key": "credit_card", "label": "Долг по карте",              "group": "liabilities"}
     ], "verdict_positive": "Вы владеете больше, чем должны. Продолжайте увеличивать разрыв.", "verdict_negative": "Вы должны больше, чем владеете. Цель — изменить знак. Это реально.", "cta": "Запомните эту цифру. Проверьте снова через 30 дней."}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 4),
     'en', 'Calculate Your Net Worth',
     '{"blocks": [{"type": "paragraph", "text": "Enter your numbers. Even if the result is negative — that is your starting point."}]}'::jsonb,
     '{"inputs": [
         {"key": "cash",        "label": "Cash and bank accounts",    "group": "assets"},
         {"key": "investments", "label": "Investments",                "group": "assets"},
         {"key": "property",    "label": "Property",                   "group": "assets"},
         {"key": "vehicle",     "label": "Vehicle (resale value)",     "group": "assets"},
         {"key": "loans",       "label": "Outstanding loans",          "group": "liabilities"},
         {"key": "credit_card", "label": "Credit card debt",           "group": "liabilities"}
     ], "verdict_positive": "You own more than you owe. Keep growing the gap.", "verdict_negative": "You owe more than you own. The goal is to flip this — and it is possible.", "cta": "Remember this number. Check again in 30 days."}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_net_worth' and ls.order_index = 4),
     'kk', 'Таза капиталыңызды есептеңіз',
     '{"blocks": [{"type": "paragraph", "text": "Деректеріңізді енгізіңіз. Нәтиже теріс болса да — бұл сіздің бастапқы нүктеңіз."}]}'::jsonb,
     '{"inputs": [
         {"key": "cash",        "label": "Қолма-қол ақша және банк шоттары", "group": "assets"},
         {"key": "investments", "label": "Инвестициялар",                     "group": "assets"},
         {"key": "property",    "label": "Жылжымайтын мүлік",                "group": "assets"},
         {"key": "vehicle",     "label": "Көлік (нарықтық бағасы)",          "group": "assets"},
         {"key": "loans",       "label": "Несиелер мен қарыздар",            "group": "liabilities"},
         {"key": "credit_card", "label": "Кредиттік карта қарызы",           "group": "liabilities"}
     ], "verdict_positive": "Сіз қарыздан гөрі көбірек иеленесіз. Айырмашылықты өсіруді жалғастырыңыз.", "verdict_negative": "Сіз иелегеннен гөрі көбірек қарыздасыз. Мақсат — белгіні өзгерту. Бұл мүмкін.", "cta": "Осы санды есте сақтаңыз. 30 күннен кейін қайта тексеріңіз."}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;


-- ══════════════════════════════════════════════════════════════
-- SUBTOPIC: pf_smart_goals
-- "Financial Goals"
-- 🌿 Scenario | 5 min
-- Steps: introduction → explanation → example → conclusion
-- ══════════════════════════════════════════════════════════════

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 1),
     'ru', 'Введение',
     '{"blocks": [
         {"type": "paragraph", "text": "Знать правильные шаги и делать их — разные задачи. Финансовые цели — это мост между ними."},
         {"type": "paragraph", "text": "Большинство целей проваливаются не из-за слабой воли, а из-за того, как они сформулированы. «Хочу откладывать больше» — это желание. Цель — это другое."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 1),
     'en', 'Introduction',
     '{"blocks": [
         {"type": "paragraph", "text": "Knowing the right moves and making them are different problems. Goals are the bridge between them."},
         {"type": "paragraph", "text": "Most financial goals fail not because of weak willpower, but because of how they are written. ''Save more'' is a wish. A goal is something else."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 1),
     'kk', 'Кіріспе',
     '{"blocks": [
         {"type": "paragraph", "text": "Дұрыс қадамдарды білу мен оларды жасау — екі бөлек мәселе. Мақсаттар — олардың арасындағы көпір."},
         {"type": "paragraph", "text": "Қаржылық мақсаттардың көпшілігі ерік-жігердің әлсіздігінен емес, дұрыс тұжырымдалмағандықтан орындалмайды. «Көбірек жинағым келеді» — бұл тілек. Мақсат — бөлек нәрсе."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 2 ────────────────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 2),
     'ru', 'SMART-цели и горизонты',
     '{"blocks": [
         {"type": "paragraph", "text": "Рабочая финансовая цель содержит пять элементов:"},
         {"type": "table", "headers": ["Элемент", "Что означает", "Пример"], "rows": [
             ["Конкретная", "Точный объект", "«Накопить 390 000 тенге»"],
             ["Измеримая", "Прогресс в числах", "«Осталось 150 000»"],
             ["Достижимая", "Реально при вашем доходе", "«25 000 в месяц»"],
             ["Значимая", "Важна для вашей жизни", "«Спокойствие при форс-мажоре»"],
             ["Ограниченная по времени", "Есть дедлайн", "«До апреля 2026»"]
         ]},
         {"type": "paragraph", "text": "Три горизонта: краткосрочные (до 1 года), среднесрочные (1–5 лет), долгосрочные (5+ лет). Финансово здоровый человек держит все три одновременно."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 2),
     'en', 'SMART Goals and Time Horizons',
     '{"blocks": [
         {"type": "paragraph", "text": "A working financial goal has five elements:"},
         {"type": "table", "headers": ["Element", "What it means", "Example"], "rows": [
             ["Specific", "Exact target", "''Save 390,000 KZT''"],
             ["Measurable", "Progress in numbers", "''150,000 left to go''"],
             ["Achievable", "Realistic on your income", "''25,000 per month''"],
             ["Relevant", "Matters to your life", "''Peace of mind in emergencies''"],
             ["Time-bound", "Has a deadline", "''By April 2026''"]
         ]},
         {"type": "paragraph", "text": "Three horizons: short-term (under 1 year), medium-term (1–5 years), long-term (5+ years). A financially healthy person holds all three at once."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 2),
     'kk', 'SMART мақсаттар және уақыт көкжиегі',
     '{"blocks": [
         {"type": "paragraph", "text": "Жұмыс істейтін қаржылық мақсатта бес элемент болады:"},
         {"type": "table", "headers": ["Элемент", "Мағынасы", "Мысал"], "rows": [
             ["Нақты", "Дәл мақсат", "«390 000 теңге жинау»"],
             ["Өлшемді", "Сандық прогресс", "«150 000 теңге қалды»"],
             ["Қолжетімді", "Табысыңызға шынайы", "«Айына 25 000 теңге»"],
             ["Маңызды", "Өміріңізге қажет", "«Төтенше жағдайда тыныштық»"],
             ["Уақытпен шектелген", "Мерзімі бар", "«2026 жылдың сәуіріне дейін»"]
         ]},
         {"type": "paragraph", "text": "Үш көкжиек: қысқамерзімді (1 жылға дейін), ортамерзімді (1–5 жыл), ұзақмерзімді (5+ жыл). Қаржылық жағынан сау адам үшеуін бір мезгілде ұстайды."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 3: example (Aisha scenario) ─────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 3),
     'ru', 'Пример: Айша',
     '{"blocks": [
         {"type": "paragraph", "text": "Айша, 26 лет, учитель в Алматы. Чистый доход — 220 000 тенге. Три желания: перестать паниковать при непредвиденных расходах, купить машину через ~2 года, не работать до 70 лет."},
         {"type": "paragraph", "text": "Желание → цель:"},
         {"type": "table", "headers": ["Желание", "SMART-цель"], "rows": [
             ["Перестать паниковать", "Накопить 390 000 ₸ экстренного фонда до апреля 2026, откладывая 25 000 ₸ каждую зарплату"],
             ["Купить машину", "Накопить 600 000 ₸ первоначального взноса до октября 2027, после выполнения цели №1"],
             ["Выйти на пенсию", "Начать пенсионные накопления до 28 лет, увеличивать взнос на 10% при каждом повышении"]
         ]},
         {"type": "paragraph", "text": "Порядок важен: экстренный фонд — первый. Без него любая непредвиденная трата разрушает остальные цели."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 3),
     'en', 'Example: Aisha',
     '{"blocks": [
         {"type": "paragraph", "text": "Aisha, 26, teacher in Almaty. Net income: 220,000 KZT. Three wishes: stop panicking at unexpected expenses, buy a car in ~2 years, not work until 70."},
         {"type": "paragraph", "text": "Wish → Goal:"},
         {"type": "table", "headers": ["Wish", "SMART Goal"], "rows": [
             ["Stop panicking", "Save 390,000 ₸ emergency fund by April 2026, transferring 25,000 ₸ every payday"],
             ["Buy a car", "Save 600,000 ₸ down payment by October 2027, starting after goal #1 is complete"],
             ["Retire comfortably", "Start pension contributions before age 28, increase by 10% with every raise"]
         ]},
         {"type": "paragraph", "text": "Order matters: emergency fund is always first. Without it, any unexpected cost destroys the other goals."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 3),
     'kk', 'Мысал: Айша',
     '{"blocks": [
         {"type": "paragraph", "text": "Айша, 26 жас, Алматыдағы мұғалім. Таза табысы — 220 000 теңге. Үш тілегі: күтпеген шығындарда үрейленуді тоқтату, ~2 жылда көлік сатып алу, 70 жасқа дейін жұмыс жасамау."},
         {"type": "paragraph", "text": "Тілек → Мақсат:"},
         {"type": "table", "headers": ["Тілек", "SMART мақсат"], "rows": [
             ["Үрейленбеу", "2026 жылдың сәуіріне дейін 390 000 ₸ төтенше қор жасақтау, әр жалақыда 25 000 ₸ аудару"],
             ["Көлік сатып алу", "1-мақсат орындалғаннан кейін, 2027 жылдың қазанына дейін 600 000 ₸ бастапқы жарна жинау"],
             ["Зейнетке шығу", "28 жасқа дейін зейнетақы жинауды бастау, әр жалақы өскенде 10%-ға арттыру"]
         ]},
         {"type": "paragraph", "text": "Ретке маңызды: төтенше қор — әрқашан бірінші. Онсыз кез келген күтпеген шығын қалған мақсаттарды бұзады."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── step 4: conclusion ────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content)
values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 4),
     'ru', 'Главное',
     '{"blocks": [
         {"type": "paragraph", "text": "Запишите три финансовые цели с конкретной суммой и датой. Расставьте приоритеты — они борются за одну и ту же зарплату, и вы должны заранее решить, кто победит."},
         {"type": "paragraph", "text": "Тема 1 завершена. Следующая тема: деньги и банки — как работает система вокруг ваших денег."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 4),
     'en', 'Key Takeaway',
     '{"blocks": [
         {"type": "paragraph", "text": "Write your top three financial goals with a specific amount and date. Prioritize them — they compete for the same paycheck, and you need to decide in advance who wins."},
         {"type": "paragraph", "text": "Topic 1 complete. Next: Money and Banking — how the system around your money actually works."}
     ]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'pf_smart_goals' and ls.order_index = 4),
     'kk', 'Негізгі қорытынды',
     '{"blocks": [
         {"type": "paragraph", "text": "Нақты соманы және мерзімді көрсете отырып, үш қаржылық мақсатыңызды жазыңыз. Оларды басымдық бойынша реттеңіз — олар бір жалақы үшін бәсекелеседі, сіз алдын ала кім жеңетінін шешуіңіз керек."},
         {"type": "paragraph", "text": "1-тақырып аяқталды. Келесі тақырып: ақша және банктер — ақшаңыздың айналасындағы жүйе қалай жұмыс істейді."}
     ]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

commit;
