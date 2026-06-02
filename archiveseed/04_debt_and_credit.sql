-- ══════════════════════════════════════════════════════════════
-- TOPIC 04: debt_and_credit
-- "Debt & Credit" | Level: beginner | Order: 4
-- 4 subtopics | ~16 min | Track A
-- Subtopics:
--   dc_good_vs_bad_debt   — Good vs. bad debt
--   dc_how_interest_works — How interest actually works
--   dc_payoff_strategies  — Debt payoff: avalanche vs. snowball
--   dc_credit_score       — Credit scores: what moves the needle
-- ══════════════════════════════════════════════════════════════

-- ── TOPIC ─────────────────────────────────────────────────────

insert into topics (code, level, order_index, is_active) values
    ('debt_and_credit', 'beginner', 8, true)
on conflict (code) do update set
    level = excluded.level, order_index = excluded.order_index,
    is_active = excluded.is_active, updated_at = now();

insert into topic_translations (topic_id, language_code, title, description) values
    ((select id from topics where code = 'debt_and_credit'), 'ru',
        'Долги и кредиты',
        'Как работает долг, сколько вы реально платите и как выбраться быстрее'),
    ((select id from topics where code = 'debt_and_credit'), 'en',
        'Debt & Credit',
        'How debt works, what it really costs, and how to get out faster'),
    ((select id from topics where code = 'debt_and_credit'), 'kk',
        'Қарыздар мен кредиттер',
        'Қарыз қалай жұмыс істейді, шынымен қанша төлейсіз және тезірек шығу жолдары')
on conflict (topic_id, language_code) do update set title = excluded.title, description = excluded.description;

-- ── SUBTOPICS ─────────────────────────────────────────────────

insert into subtopics (topic_id, code, order_index, estimated_minutes, is_active) values
    ((select id from topics where code = 'debt_and_credit'), 'dc_good_vs_bad_debt',   1, 4, true),
    ((select id from topics where code = 'debt_and_credit'), 'dc_how_interest_works', 2, 5, true),
    ((select id from topics where code = 'debt_and_credit'), 'dc_payoff_strategies',  3, 4, true),
    ((select id from topics where code = 'debt_and_credit'), 'dc_credit_score',       4, 4, true)
on conflict (code) do update set order_index = excluded.order_index,
    estimated_minutes = excluded.estimated_minutes, is_active = excluded.is_active, updated_at = now();

insert into subtopic_translations (subtopic_id, language_code, title) values
    ((select id from subtopics where code = 'dc_good_vs_bad_debt'),   'ru', 'Хороший и плохой долг'),
    ((select id from subtopics where code = 'dc_how_interest_works'), 'ru', 'Как на самом деле работает процент'),
    ((select id from subtopics where code = 'dc_payoff_strategies'),  'ru', 'Стратегии погашения долга'),
    ((select id from subtopics where code = 'dc_credit_score'),       'ru', 'Кредитная история'),
    ((select id from subtopics where code = 'dc_good_vs_bad_debt'),   'en', 'Good vs. Bad Debt'),
    ((select id from subtopics where code = 'dc_how_interest_works'), 'en', 'How Interest Really Works'),
    ((select id from subtopics where code = 'dc_payoff_strategies'),  'en', 'Debt Payoff Strategies'),
    ((select id from subtopics where code = 'dc_credit_score'),       'en', 'Credit Score'),
    ((select id from subtopics where code = 'dc_good_vs_bad_debt'),   'kk', 'Жақсы және жаман қарыз'),
    ((select id from subtopics where code = 'dc_how_interest_works'), 'kk', 'Пайыз шынымен қалай жұмыс істейді'),
    ((select id from subtopics where code = 'dc_payoff_strategies'),  'kk', 'Қарызды өтеу стратегиялары'),
    ((select id from subtopics where code = 'dc_credit_score'),       'kk', 'Несиелік тарих')
on conflict (subtopic_id, language_code) do update set title = excluded.title;

insert into lessons (subtopic_id, is_published)
select id, true from subtopics
where code in ('dc_good_vs_bad_debt','dc_how_interest_works','dc_payoff_strategies','dc_credit_score')
on conflict (subtopic_id) do update set is_published = excluded.is_published;

insert into quizzes (subtopic_code, topic_code, quiz_type, passing_score, is_active) values
    (null, 'debt_and_credit', 'topic_final_quiz', 75, true)
on conflict (topic_code) where quiz_type = 'topic_final_quiz' do update set
    passing_score = excluded.passing_score, is_active = excluded.is_active, updated_at = now();

insert into quiz_translations (quiz_id, language_code, title) values
    ((select id from quizzes where topic_code = 'debt_and_credit' and quiz_type = 'topic_final_quiz'), 'ru', 'Итоговый квиз: Долги и кредиты'),
    ((select id from quizzes where topic_code = 'debt_and_credit' and quiz_type = 'topic_final_quiz'), 'en', 'Final Quiz: Debt & Credit'),
    ((select id from quizzes where topic_code = 'debt_and_credit' and quiz_type = 'topic_final_quiz'), 'kk', 'Қорытынды тест: Қарыздар мен кредиттер')
on conflict (quiz_id, language_code) do update set title = excluded.title;

-- ══════════════════════════════════════════════════════════════
-- QUIZ QUESTIONS
-- ══════════════════════════════════════════════════════════════

-- ── dc_good_vs_bad_debt ───────────────────────────────────────

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('dc_good_vs_bad_debt', 70, '[
        {"lang":"ru","title":"Квиз: Хороший и плохой долг"},
        {"lang":"en","title":"Quiz: Good vs. Bad Debt"},
        {"lang":"kk","title":"Тест: Жақсы және жаман қарыз"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Студент взял кредит на получение IT-специальности, которая в среднем приносит на 40% больше, чем его текущая работа. Это пример:"},
          {"lang":"en","text":"A student takes a loan to get an IT qualification that typically pays 40% more than his current job. This is an example of:"},
          {"lang":"kk","text":"Студент қазіргі жұмысынан орта есеппен 40% көп табыс әкелетін IT мамандығына несие алды. Бұл мысалы:"}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Хорошего долга — инвестиция в будущий доход"},
              {"lang":"en","text":"Good debt — an investment in future income"},
              {"lang":"kk","text":"Жақсы қарыз — болашақ табысқа инвестиция"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Плохого долга — обучение всегда риск"},
              {"lang":"en","text":"Bad debt — education is always a risk"},
              {"lang":"kk","text":"Жаман қарыз — білім беру әрқашан тәуекел"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Нейтрального долга — зависит от результата"},
              {"lang":"en","text":"Neutral debt — depends on the outcome"},
              {"lang":"kk","text":"Бейтарап қарыз — нәтижеге байланысты"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Обеспеченного долга — нужен залог"},
              {"lang":"en","text":"Secured debt — needs collateral"},
              {"lang":"kk","text":"Қамтамасыз етілген қарыз — кепіл қажет"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Максим купил в кредит смартфон за 300 000 тенге под 35% годовых, хотя у него был рабочий телефон. Через год он заплатит примерно 405 000 тенге. Это пример:"},
          {"lang":"en","text":"Maxim bought a 300,000 KZT smartphone on credit at 35% APR, even though his old phone worked fine. After a year he will pay around 405,000 KZT. This is:"},
          {"lang":"kk","text":"Максим жұмыс жасайтын телефоны болса да, жылдық 35%-бен 300 000 теңгелік смартфонды несиеге алды. Бір жылдан кейін ол шамамен 405 000 теңге төлейді. Бұл:"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Хорошего долга — смартфон помогает работать"},
              {"lang":"en","text":"Good debt — a smartphone helps productivity"},
              {"lang":"kk","text":"Жақсы қарыз — смартфон жұмысқа көмектеседі"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Плохого долга — актив обесценивается, процент высокий"},
              {"lang":"en","text":"Bad debt — the asset depreciates and the rate is high"},
              {"lang":"kk","text":"Жаман қарыз — актив құнсызданады, пайыз жоғары"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Обеспеченного долга — телефон в залоге"},
              {"lang":"en","text":"Secured debt — the phone is collateral"},
              {"lang":"kk","text":"Қамтамасыз етілген қарыз — телефон кепіл"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Невозобновляемого долга — разовая выплата"},
              {"lang":"en","text":"Non-revolving debt — single repayment"},
              {"lang":"kk","text":"Жаңарымайтын қарыз — бір реттік төлем"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'true_false',
        '[{"lang":"ru","text":"Ипотека — это всегда плохой долг, потому что вы переплачиваете банку проценты."},
          {"lang":"en","text":"A mortgage is always bad debt because you pay interest to the bank."},
          {"lang":"kk","text":"Ипотека банкке пайыз төлейтіндіктен, әрқашан жаман қарыз болып табылады."}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Верно"},{"lang":"en","text":"True"},{"lang":"kk","text":"Дұрыс"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Неверно — ипотека может быть хорошим долгом, если актив растёт в цене"},
              {"lang":"en","text":"False — a mortgage can be good debt if the asset appreciates"},
              {"lang":"kk","text":"Дұрыс емес — актив бағасы өссе, ипотека жақсы қарыз бола алады"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Зависит от суммы"},{"lang":"en","text":"Depends on the amount"},{"lang":"kk","text":"Сомаға байланысты"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только для первой квартиры"},{"lang":"en","text":"Only for a first apartment"},{"lang":"kk","text":"Тек бірінші пәтер үшін"}]}]'::jsonb);
end $$;

-- ── dc_how_interest_works ─────────────────────────────────────

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('dc_how_interest_works', 70, '[
        {"lang":"ru","title":"Квиз: Как работает процент"},
        {"lang":"en","title":"Quiz: How Interest Works"},
        {"lang":"kk","title":"Тест: Пайыз қалай жұмыс істейді"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"У Асель долг по карте 200 000 тенге под 36% годовых. Она платит только минимальный платёж — 2% от остатка (~4 000 тенге). Что произойдёт?"},
          {"lang":"en","text":"Assel has 200,000 KZT credit card debt at 36% APR. She pays only the minimum — 2% of the balance (~4,000 KZT). What happens?"},
          {"lang":"kk","text":"Асельдің кредиттік картасында 36% жылдықпен 200 000 теңге қарызы бар. Ол тек минималды төлем — қалдықтың 2%-ін (~4 000 теңге) төлейді. Не болады?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Долг выплатится за ~4 года"},
              {"lang":"en","text":"The debt will be paid off in ~4 years"},
              {"lang":"kk","text":"Қарыз ~4 жылда өтеледі"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Долг практически не уменьшается — почти весь платёж уходит на проценты"},
              {"lang":"en","text":"The debt barely shrinks — almost the entire payment goes to interest"},
              {"lang":"kk","text":"Қарыз іс жүзінде азаймайды — төлемнің барлығы дерлік пайызға кетеді"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Банк спишет остаток через 10 лет"},
              {"lang":"en","text":"The bank will write off the balance after 10 years"},
              {"lang":"kk","text":"Банк 10 жылдан кейін қалдықты есептен шығарады"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Долг исчезнет при банкротстве автоматически"},
              {"lang":"en","text":"The debt disappears automatically in bankruptcy"},
              {"lang":"kk","text":"Қарыз банкроттықта автоматты түрде жоғалады"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Кредит 500 000 тенге под 24% годовых. Вы платите 15 000 тенге в месяц. Сколько из первого платежа идёт на погашение основного долга?"},
          {"lang":"en","text":"You have a 500,000 KZT loan at 24% APR and pay 15,000 KZT/month. How much of the first payment reduces your actual debt?"},
          {"lang":"kk","text":"500 000 теңге несие, жылдық 24%, ай сайын 15 000 теңге төлейсіз. Бірінші төлемнің қанша бөлігі негізгі қарызды азайтады?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"15 000 тенге — весь платёж"},
              {"lang":"en","text":"15,000 KZT — the full payment"},
              {"lang":"kk","text":"15 000 теңге — бүкіл төлем"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"7 500 тенге — половина"},
              {"lang":"en","text":"7,500 KZT — half"},
              {"lang":"kk","text":"7 500 теңге — жартысы"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"Только 5 000 тенге — 10 000 уходит на проценты (24%÷12 × 500 000)"},
              {"lang":"en","text":"Only 5,000 KZT — 10,000 goes to interest (24%÷12 × 500,000)"},
              {"lang":"kk","text":"Тек 5 000 теңге — 10 000 пайызға кетеді (24%÷12 × 500 000)"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Ничего — весь платёж идёт на проценты в первый год"},
              {"lang":"en","text":"Nothing — the full payment goes to interest in year one"},
              {"lang":"kk","text":"Ештеңе — бірінші жылда бүкіл төлем пайызға кетеді"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'true_false',
        '[{"lang":"ru","text":"При кредите с фиксированным ежемесячным платежом в начале срока большая часть платежа идёт на проценты, а в конце — на основной долг."},
          {"lang":"en","text":"With a fixed monthly payment loan, in the early months most of the payment goes to interest, and toward the end most goes to principal."},
          {"lang":"kk","text":"Тіркелген ай сайынғы төлемі бар несиеде алғашқы айларда төлемнің көп бөлігі пайызға, ал соңына қарай негізгі қарызға кетеді."}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Верно — это называется амортизация"},
              {"lang":"en","text":"True — this is called amortization"},
              {"lang":"kk","text":"Дұрыс — бұл амортизация деп аталады"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Неверно"},{"lang":"en","text":"False"},{"lang":"kk","text":"Дұрыс емес"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только при ипотеке"},{"lang":"en","text":"Only with mortgages"},{"lang":"kk","text":"Тек ипотекада"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Соотношение одинаковое весь срок"},{"lang":"en","text":"The ratio stays the same throughout"},{"lang":"kk","text":"Арақатынас бүкіл мерзім бойы бірдей"}]}]'::jsonb);
end $$;

-- ── dc_payoff_strategies ──────────────────────────────────────

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('dc_payoff_strategies', 70, '[
        {"lang":"ru","title":"Квиз: Стратегии погашения"},
        {"lang":"en","title":"Quiz: Payoff Strategies"},
        {"lang":"kk","title":"Тест: Өтеу стратегиялары"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"У Ерлана три долга: карта 28% (150 000 ₸), рассрочка 0% (300 000 ₸), автокредит 18% (800 000 ₸). Метод лавины предписывает сначала атаковать:"},
          {"lang":"en","text":"Yerlan has three debts: credit card 28% (150,000 ₸), installment 0% (300,000 ₸), car loan 18% (800,000 ₸). The avalanche method says attack first:"},
          {"lang":"kk","text":"Ерланның үш қарызы бар: карта 28% (150 000 ₸), бөліп төлеу 0% (300 000 ₸), автокредит 18% (800 000 ₸). Көшкін әдісі бойынша алдымен шабуыл жасайтын:"}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Карту под 28% — самый высокий процент"},
              {"lang":"en","text":"The 28% credit card — highest interest rate"},
              {"lang":"kk","text":"28% карта — ең жоғары пайыз мөлшерлемесі"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Рассрочку 0% — её проще закрыть"},
              {"lang":"en","text":"The 0% installment — easiest to close"},
              {"lang":"kk","text":"0% бөліп төлеу — жабуға оңай"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Автокредит — самая большая сумма"},
              {"lang":"en","text":"The car loan — largest balance"},
              {"lang":"kk","text":"Автокредит — ең үлкен сома"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Все одновременно — равными долями"},
              {"lang":"en","text":"All at once — in equal portions"},
              {"lang":"kk","text":"Барлығы бір мезгілде — тең үлеспен"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Метод снежного кома математически менее выгоден, чем лавина. Тогда зачем его используют?"},
          {"lang":"en","text":"The snowball method is mathematically less efficient than avalanche. So why do people use it?"},
          {"lang":"kk","text":"Қар шары әдісі математикалық жағынан көшкіннен тиімді емес. Онда неге адамдар оны қолданады?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Он быстрее избавляет от долгов"},
              {"lang":"en","text":"It pays off debt faster overall"},
              {"lang":"kk","text":"Ол қарыздан жалпы тезірек арылтады"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Быстрые победы поддерживают мотивацию — психология важнее математики"},
              {"lang":"en","text":"Quick wins maintain motivation — psychology beats math when you quit"},
              {"lang":"kk","text":"Жылдам жетістіктер мотивацияны сақтайды — психология математикадан маңыздырақ"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Банки предпочитают этот метод"},
              {"lang":"en","text":"Banks prefer this method"},
              {"lang":"kk","text":"Банктер бұл әдісті жақсы көреді"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Он лучше работает при высоких процентах"},
              {"lang":"en","text":"It works better with high interest rates"},
              {"lang":"kk","text":"Жоғары пайызбен жақсы жұмыс істейді"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'true_false',
        '[{"lang":"ru","text":"Досрочное погашение кредита — это гарантированная доходность, равная процентной ставке по кредиту."},
          {"lang":"en","text":"Paying off debt early is a guaranteed return equal to the loan interest rate."},
          {"lang":"kk","text":"Несиені мерзімінен бұрын өтеу — бұл несие пайыз мөлшерлемесіне тең кепілдендірілген кіріс."}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Верно — погашая долг под 24%, вы экономите 24% гарантированно"},
              {"lang":"en","text":"True — paying off 24% debt saves you 24%, guaranteed"},
              {"lang":"kk","text":"Дұрыс — 24% қарызды өтеу кепілдендірілген 24% үнемдеу береді"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Неверно — доходность зависит от рынка"},
              {"lang":"en","text":"False — the return depends on the market"},
              {"lang":"kk","text":"Дұрыс емес — кіріс нарыққа байланысты"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только при фиксированной ставке"},{"lang":"en","text":"Only with a fixed rate"},{"lang":"kk","text":"Тек тіркелген мөлшерлемемен"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Зависит от типа долга"},{"lang":"en","text":"Depends on debt type"},{"lang":"kk","text":"Қарыз түріне байланысты"}]}]'::jsonb);
end $$;

-- ── dc_credit_score ───────────────────────────────────────────

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('dc_credit_score', 70, '[
        {"lang":"ru","title":"Квиз: Кредитная история"},
        {"lang":"en","title":"Quiz: Credit Score"},
        {"lang":"kk","title":"Тест: Несиелік тарих"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Какой фактор сильнее всего влияет на кредитную историю?"},
          {"lang":"en","text":"Which factor has the strongest impact on your credit score?"},
          {"lang":"kk","text":"Несиелік тарихқа қандай фактор ең күшті әсер етеді?"}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Своевременность платежей — просрочки бьют сильнее всего"},
              {"lang":"en","text":"Payment history — late payments hurt more than anything"},
              {"lang":"kk","text":"Төлемдердің уақтылығы — мерзімінен кешіктіру ең қатты зақымдайды"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Уровень дохода"},{"lang":"en","text":"Income level"},{"lang":"kk","text":"Табыс деңгейі"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Количество банков, где открыты счета"},
              {"lang":"en","text":"Number of banks where you have accounts"},
              {"lang":"kk","text":"Шоттары бар банктер саны"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Сумма накоплений"},{"lang":"en","text":"Amount of savings"},{"lang":"kk","text":"Жинақ сомасы"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Диас закрыл старую кредитную карту, которой почти не пользовался. Как это повлияет на его кредитную историю?"},
          {"lang":"en","text":"Dias closed an old credit card he rarely used. How will this affect his credit score?"},
          {"lang":"kk","text":"Диас сирек пайдаланған ескі кредиттік картасын жапты. Бұл оның несиелік тарихына қалай әсер етеді?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Улучшит — меньше карт, меньше риска"},
              {"lang":"en","text":"Improve it — fewer cards, less risk"},
              {"lang":"kk","text":"Жақсартады — карта аз, тәуекел аз"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Может ухудшить — растёт утилизация лимита и теряется история"},
              {"lang":"en","text":"Likely worsen it — utilization rises and history length drops"},
              {"lang":"kk","text":"Нашарлатуы мүмкін — пайдалану коэффициенті өседі және тарих ұзындығы қысқарады"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Никак не повлияет"},{"lang":"en","text":"No effect at all"},{"lang":"kk","text":"Ешқандай әсер етпейді"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Улучшит через 6 месяцев"},{"lang":"en","text":"Improve it after 6 months"},{"lang":"kk","text":"6 айдан кейін жақсартады"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'single_choice',
        '[{"lang":"ru","text":"Самый быстрый способ начать строить кредитную историю с нуля — это:"},
          {"lang":"en","text":"The fastest way to start building a credit history from scratch is:"},
          {"lang":"kk","text":"Несиелік тарихты нөлден бастаудың ең жылдам жолы:"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Взять крупный потребительский кредит"},
              {"lang":"en","text":"Take a large consumer loan"},
              {"lang":"kk","text":"Үлкен тұтынушылық несие алу"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Оформить кредитную карту с небольшим лимитом и вовремя гасить полностью каждый месяц"},
              {"lang":"en","text":"Get a credit card with a small limit and pay it in full every month on time"},
              {"lang":"kk","text":"Шағын лимитпен кредиттік карта алып, оны ай сайын уақытында толық өтеу"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Открыть как можно больше счетов"},
              {"lang":"en","text":"Open as many accounts as possible"},
              {"lang":"kk","text":"Мүмкіндігінше көп шот ашу"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Подождать — история строится автоматически"},
              {"lang":"en","text":"Wait — history builds automatically over time"},
              {"lang":"kk","text":"Күту — тарих автоматты түрде қалыптасады"}]}]'::jsonb);
end $$;

-- ══════════════════════════════════════════════════════════════
-- LESSON STEPS
-- ══════════════════════════════════════════════════════════════

begin;

-- ══════════════════════════════════════════════════════════════
-- SUBTOPIC: dc_good_vs_bad_debt | 4 steps
-- ══════════════════════════════════════════════════════════════

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 1), 'ru', 'Долг — это инструмент',
     '{"blocks":[{"type":"paragraph","text":"Долг — не зло. Это инструмент. Молоток можно забить гвоздь, а можно разбить окно. Всё зависит от того, зачем и как вы берёте в долг."},{"type":"paragraph","text":"Разница между хорошим и плохим долгом — в том, что происходит с вашим состоянием после."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 1), 'en', 'Debt Is a Tool',
     '{"blocks":[{"type":"paragraph","text":"Debt is not evil. It is a tool. A hammer can drive a nail or break a window — it depends entirely on how and why you use it."},{"type":"paragraph","text":"The difference between good and bad debt is what happens to your net worth afterward."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 1), 'kk', 'Қарыз — бұл құрал',
     '{"blocks":[{"type":"paragraph","text":"Қарыз — жаман нәрсе емес. Бұл құрал. Балға шегені де қаға алады, терезені де сындыра алады — барлығы оны қалай және не үшін пайдаланатыңызға байланысты."},{"type":"paragraph","text":"Жақсы және жаман қарыздың айырмашылығы — сіздің жағдайыңызға кейін не болатынында."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 2), 'ru', 'Хороший vs. плохой долг',
     '{"blocks":[{"type":"table","headers":["","Хороший долг","Плохой долг"],"rows":[["Цель","Покупка актива, рост дохода","Потребление, вещи которые дешевеют"],["Ставка","Низкая или умеренная","Высокая (18–45%+)"],["Эффект","Увеличивает капитал","Уменьшает капитал"],["Примеры","Ипотека, образование, бизнес","Карта на телефон, шопинг в рассрочку"]]},{"type":"paragraph","text":"Ключевой вопрос перед любым кредитом: этот долг сделает меня богаче или беднее?"}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 2), 'en', 'Good vs. Bad Debt',
     '{"blocks":[{"type":"table","headers":["","Good Debt","Bad Debt"],"rows":[["Purpose","Buying assets, growing income","Consumption, depreciating items"],["Rate","Low to moderate","High (18–45%+)"],["Effect","Builds net worth","Drains net worth"],["Examples","Mortgage, education, business","Phone on credit, shopping installments"]]},{"type":"paragraph","text":"The key question before any loan: will this debt make me richer or poorer?"}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 2), 'kk', 'Жақсы vs. жаман қарыз',
     '{"blocks":[{"type":"table","headers":["","Жақсы қарыз","Жаман қарыз"],"rows":[["Мақсат","Актив сатып алу, табысты арттыру","Тұтыну, құнсызданатын заттар"],["Мөлшерлеме","Төмен немесе орташа","Жоғары (18–45%+)"],["Әсері","Капиталды арттырады","Капиталды азайтады"],["Мысалдар","Ипотека, білім, бизнес","Несиеге телефон, бөліп төлеп сауда"]]},{"type":"paragraph","text":"Кез келген несие алар алдындағы негізгі сұрақ: бұл қарыз мені байытады ма, кедейлете ме?"}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 3), 'ru', 'Один и тот же кредит — разный результат',
     '{"blocks":[{"type":"paragraph","text":"Максим и Дамир взяли по 500 000 тенге в кредит."},{"type":"bullet_list","items":["Максим купил смартфон и ноутбук. Через 3 года вещи стоят 100 000. Он заплатил 650 000 с процентами. Итог: −550 000 к капиталу.","Дамир оплатил курс программирования и фриланс-оборудование. Через 3 года зарабатывает на 150 000 тенге/мес больше. Итог: кредит окупился за 4 месяца дохода."]},{"type":"paragraph","text":"Разница не в сумме. Разница — в том, что производит этот долг."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 3), 'en', 'Same Loan, Different Outcome',
     '{"blocks":[{"type":"paragraph","text":"Maxim and Damir both borrowed 500,000 KZT."},{"type":"bullet_list","items":["Maxim bought a smartphone and laptop. After 3 years, the items are worth 100,000 KZT. With interest he paid 650,000. Net effect: −550,000 to net worth.","Damir paid for a programming course and freelance equipment. After 3 years he earns 150,000 KZT/month more. The loan paid itself back in 4 months of extra income."]},{"type":"paragraph","text":"The difference is not the amount. The difference is what the debt produces."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 3), 'kk', 'Бірдей несие — басқа нәтиже',
     '{"blocks":[{"type":"paragraph","text":"Максим мен Дамир екеуі де 500 000 теңге несие алды."},{"type":"bullet_list","items":["Максим смартфон мен ноутбук сатып алды. 3 жылдан кейін заттар 100 000 теңге тұрады. Пайызбен 650 000 төледі. Нәтиже: таза капиталға −550 000.","Дамир бағдарламалау курсы мен фриланс жабдығына төледі. 3 жылдан кейін айына 150 000 теңге көбірек табады. Несие қосымша табыстың 4 айында өтелді."]},{"type":"paragraph","text":"Айырмашылық сомада емес. Айырмашылық — бұл қарыз нені өндіретінінде."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Перед любым кредитом задайте один вопрос: этот долг работает на меня или против меня? Высокая ставка на падающий актив — почти всегда против."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"Before any loan, ask one question: does this debt work for me or against me? A high rate on a depreciating asset almost always works against you."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_good_vs_bad_debt' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"Кез келген несие алар алдында бір сұрақ қойыңыз: бұл қарыз маған жұмыс жасайды ма, қарсы ма? Құнсызданатын активке жоғары мөлшерлеме — дерлік әрқашан қарсы."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ══════════════════════════════════════════════════════════════
-- SUBTOPIC: dc_how_interest_works | 4 steps
-- ══════════════════════════════════════════════════════════════

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 1), 'ru', 'Скрытая цена кредита', '{"blocks":[{"type":"paragraph","text":"Когда вы видите «24% годовых», это ощущается абстрактно. Но стоит пересчитать в реальные деньги — и ощущение меняется навсегда."},{"type":"paragraph","text":"Этот урок — о том, как проценты работают против вас, если вы это не понимаете."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 1), 'en', 'The Hidden Price of Credit', '{"blocks":[{"type":"paragraph","text":"When you see ''24% APR'', it feels abstract. But translate it into real money and the feeling changes permanently."},{"type":"paragraph","text":"This lesson is about how interest works against you when you do not understand it."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 1), 'kk', 'Несиенің жасырын бағасы', '{"blocks":[{"type":"paragraph","text":"«Жылдық 24%» дегенді естіген кезде бұл абстрактты сезіледі. Бірақ нақты ақшаға аударғанда — сезім мәңгілікке өзгереді."},{"type":"paragraph","text":"Бұл сабақ — пайыздың сізді түсінбеген кезде қарсы қалай жұмыс істейтіні туралы."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 2), 'ru', 'Амортизация: почему в начале почти ничего не погашается',
     '{"blocks":[{"type":"paragraph","text":"Большинство кредитов работают по принципу амортизации: каждый месяц вы платите одну и ту же сумму, но её состав меняется."},{"type":"paragraph","text":"Формула ежемесячного процента проста: остаток долга × (ставка ÷ 12). При кредите 500 000 тенге под 24% годовых:"},{"type":"table","headers":["Месяц","Платёж","Проценты","Основной долг","Остаток"],"rows":[["1","15 000 ₸","10 000 ₸","5 000 ₸","495 000 ₸"],["12","15 000 ₸","9 009 ₸","5 991 ₸","441 000 ₸"],["36","15 000 ₸","5 100 ₸","9 900 ₸","244 000 ₸"]]},{"type":"paragraph","text":"В первый год почти 2/3 каждого платежа — чистые проценты банку. Вот почему досрочное погашение так выгодно: вы бьёте прямо по основному долгу."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 2), 'en', 'Amortization: Why You Barely Dent the Debt Early On',
     '{"blocks":[{"type":"paragraph","text":"Most loans are amortized: you pay the same amount every month, but the split between interest and principal shifts over time."},{"type":"paragraph","text":"Monthly interest = remaining balance × (rate ÷ 12). On a 500,000 KZT loan at 24% APR:"},{"type":"table","headers":["Month","Payment","Interest","Principal","Balance"],"rows":[["1","15,000 ₸","10,000 ₸","5,000 ₸","495,000 ₸"],["12","15,000 ₸","9,009 ₸","5,991 ₸","441,000 ₸"],["36","15,000 ₸","5,100 ₸","9,900 ₸","244,000 ₸"]]},{"type":"paragraph","text":"In the first year, nearly two-thirds of every payment is pure interest. This is why paying extra early is so powerful — it hits the principal directly."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 2), 'kk', 'Амортизация: Неліктен ерте кезде қарыз іс жүзінде азаймайды',
     '{"blocks":[{"type":"paragraph","text":"Несиелердің көпшілігі амортизация принципімен жұмыс істейді: ай сайын бірдей сома төлейсіз, бірақ оның құрамы өзгереді."},{"type":"paragraph","text":"Ай сайынғы пайыз = қарыз қалдығы × (мөлшерлеме ÷ 12). 500 000 теңге несиеде жылдық 24%:"},{"type":"table","headers":["Ай","Төлем","Пайыз","Негізгі қарыз","Қалдық"],"rows":[["1","15 000 ₸","10 000 ₸","5 000 ₸","495 000 ₸"],["12","15 000 ₸","9 009 ₸","5 991 ₸","441 000 ₸"],["36","15 000 ₸","5 100 ₸","9 900 ₸","244 000 ₸"]]},{"type":"paragraph","text":"Бірінші жылда әр төлемнің үштен екісі таза пайыз. Сондықтан мерзімінен бұрын өтеу тиімді: сіз тікелей негізгі қарызға соққы бересіз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 3), 'ru', 'Ловушка минимального платежа',
     '{"blocks":[{"type":"paragraph","text":"Асель задолжала по кредитке 200 000 тенге под 36% годовых. Минимальный платёж — 2% от остатка."},{"type":"table","headers":["Сценарий","Платёж/мес","Срок погашения","Переплата"],"rows":[["Только минимум","~4 000 ₸","27+ лет","~380 000 ₸"],["Фиксированные 10 000 ₸","10 000 ₸","2,5 года","~100 000 ₸"],["Фиксированные 20 000 ₸","20 000 ₸","11 месяцев","~37 000 ₸"]]},{"type":"paragraph","text":"Увеличив платёж в 5 раз, Асель сократила срок в 29 раз и переплату в 10 раз. Минимальный платёж — это минимальная выгода для вас."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 3), 'en', 'The Minimum Payment Trap',
     '{"blocks":[{"type":"paragraph","text":"Assel owes 200,000 KZT on a credit card at 36% APR. Minimum payment is 2% of the balance."},{"type":"table","headers":["Scenario","Payment/mo","Time to payoff","Interest paid"],"rows":[["Minimum only","~4,000 ₸","27+ years","~380,000 ₸"],["Fixed 10,000 ₸","10,000 ₸","2.5 years","~100,000 ₸"],["Fixed 20,000 ₸","20,000 ₸","11 months","~37,000 ₸"]]},{"type":"paragraph","text":"By paying 5× more per month, Assel cut the timeline by 29× and total interest by 10×. The minimum payment is the minimum benefit to you."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 3), 'kk', 'Минималды төлем тұзағы',
     '{"blocks":[{"type":"paragraph","text":"Асельдің кредиттік картасында жылдық 36%-бен 200 000 теңге қарызы бар. Минималды төлем — қалдықтың 2%."},{"type":"table","headers":["Сценарий","Ай сайынғы төлем","Өтелу мерзімі","Артық төлем"],"rows":[["Тек минималды","~4 000 ₸","27+ жыл","~380 000 ₸"],["Тіркелген 10 000 ₸","10 000 ₸","2,5 жыл","~100 000 ₸"],["Тіркелген 20 000 ₸","20 000 ₸","11 ай","~37 000 ₸"]]},{"type":"paragraph","text":"Айлық төлемді 5 есе арттыра отырып, Асель мерзімді 29 есе және артық төлемді 10 есе қысқартты. Минималды төлем — сіз үшін минималды пайда."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Любой кредит имеет реальную стоимость. Переведите ставку в рубли/тенге, посчитайте переплату — и вы увидите, стоит ли оно того. Никогда не берите кредит, не зная итоговую сумму переплаты."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"Every loan has a real cost. Translate the rate into actual money, calculate total interest paid — and you will see whether it is worth it. Never borrow without knowing the total you will pay back."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_how_interest_works' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"Кез келген несиенің нақты бағасы бар. Мөлшерлемені нақты ақшаға аударыңыз, артық төлемді есептеңіз — және оның тұрарлықтай екенін көресіз. Жалпы қайтарылатын соманы білмей ешқашан несие алмаңыз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ══════════════════════════════════════════════════════════════
-- SUBTOPIC: dc_payoff_strategies | 4 steps
-- ══════════════════════════════════════════════════════════════

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 1), 'ru', 'Два способа выбраться', '{"blocks":[{"type":"paragraph","text":"Если у вас несколько долгов и свободные деньги, встаёт вопрос: куда их направить? Существуют два проверенных подхода, и выбор между ними — дело не только математики."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 1), 'en', 'Two Ways Out', '{"blocks":[{"type":"paragraph","text":"When you have multiple debts and extra cash, the question is: where does the money go? There are two proven approaches, and choosing between them is not purely a math problem."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 1), 'kk', 'Шығудың екі жолы', '{"blocks":[{"type":"paragraph","text":"Бірнеше қарызыңыз болса және қосымша ақша болса, сұрақ туындайды: оларды қайда жіберу керек? Екі тексерілген тәсіл бар, олардың арасындағы таңдау тек математика мәселесі емес."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 2), 'ru', 'Лавина vs. Снежный ком',
     '{"blocks":[{"type":"table","headers":["","Лавина (Avalanche)","Снежный ком (Snowball)"],"rows":[["Принцип","Атакуй долг с высшим %","Атакуй самый маленький долг"],["Математика","Экономит больше денег","Экономит меньше денег"],["Психология","Требует терпения","Быстрые победы = мотивация"],["Подходит для","Дисциплинированных","Тех, кто бросал раньше"]]},{"type":"paragraph","text":"На всех остальных долгах — только минимальный платёж. Весь огонь — на одну цель. Когда она закрыта, весь высвободившийся платёж перекидывается на следующую. Так работает обе стратегии."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 2), 'en', 'Avalanche vs. Snowball',
     '{"blocks":[{"type":"table","headers":["","Avalanche","Snowball"],"rows":[["Principle","Attack highest interest first","Attack smallest balance first"],["Math","Saves most money","Saves less money"],["Psychology","Requires patience","Quick wins build motivation"],["Best for","Disciplined people","People who have quit before"]]},{"type":"paragraph","text":"On all other debts — minimum payments only. All extra cash goes to one target. When it is gone, that freed-up payment rolls into the next debt. That is how both methods work."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 2), 'kk', 'Көшкін vs. Қар шары',
     '{"blocks":[{"type":"table","headers":["","Көшкін (Avalanche)","Қар шары (Snowball)"],"rows":[["Принцип","Ең жоғары %-ды шабуылда","Ең кіші қарызды шабуылда"],["Математика","Ең көп ақша үнемдейді","Аз ақша үнемдейді"],["Психология","Шыдамдылық талап етеді","Жылдам жетістіктер = мотивация"],["Кімге лайық","Тәртіпті адамдарға","Бұрын тастап кеткендерге"]]},{"type":"paragraph","text":"Барлық басқа қарыздарда — тек минималды төлем. Барлық қосымша ақша бір нысанаға бағытталады. Ол жабылғаннан кейін, бүкіл босаған төлем келесі қарызға ауысады. Екі әдіс те осылай жұмыс істейді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 3), 'ru', 'Ерлан: три долга, 50 000 тенге в месяц',
     '{"blocks":[{"type":"paragraph","text":"У Ерлана три долга. Каждый месяц он может бросить 50 000 тенге сверх минимумов."},{"type":"table","headers":["Долг","Остаток","Ставка","Мин. платёж"],"rows":[["Кредитная карта","150 000 ₸","28%","3 000 ₸"],["Рассрочка","300 000 ₸","0%","15 000 ₸"],["Автокредит","800 000 ₸","18%","22 000 ₸"]]},{"type":"bullet_list","items":["Лавина: 50 000 → кредитка (28%). Карта закрыта за 3 месяца. Потом 50 000 → автокредит. Итог: экономия ~85 000 тенге на процентах.","Снежком: 50 000 → кредитка (маленький остаток). Карта закрыта за 3 месяца — тот же срок! Здесь выигрыш лавины меньше, потому что маленький долг совпал с высокой ставкой."]},{"type":"paragraph","text":"Правило: если самый маленький долг и самый дорогой — одно и то же, оба метода дают один результат. Если нет — лавина экономит больше."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 3), 'en', 'Yerlan: Three Debts, 50,000 KZT Extra Per Month',
     '{"blocks":[{"type":"paragraph","text":"Yerlan has three debts and can throw 50,000 KZT extra each month above minimums."},{"type":"table","headers":["Debt","Balance","Rate","Min. payment"],"rows":[["Credit card","150,000 ₸","28%","3,000 ₸"],["Installment plan","300,000 ₸","0%","15,000 ₸"],["Car loan","800,000 ₸","18%","22,000 ₸"]]},{"type":"bullet_list","items":["Avalanche: 50,000 → card (28%). Card gone in 3 months. Then 50,000 → car loan. Total savings: ~85,000 KZT in interest.","Snowball: 50,000 → card (smallest balance). Card also gone in 3 months — same timeline! Here the avalanche advantage is small because the smallest debt happened to carry the highest rate."]},{"type":"paragraph","text":"Rule: if the smallest balance and highest rate are the same debt, both methods tie. If not, avalanche saves more."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 3), 'kk', 'Ерлан: үш қарыз, айына 50 000 теңге қосымша',
     '{"blocks":[{"type":"paragraph","text":"Ерланның үш қарызы бар және минимумдардан тыс айына 50 000 теңге қосымша бере алады."},{"type":"table","headers":["Қарыз","Қалдық","Мөлшерлеме","Мин. төлем"],"rows":[["Кредиттік карта","150 000 ₸","28%","3 000 ₸"],["Бөліп төлеу","300 000 ₸","0%","15 000 ₸"],["Автокредит","800 000 ₸","18%","22 000 ₸"]]},{"type":"bullet_list","items":["Көшкін: 50 000 → карта (28%). Карта 3 айда жабылады. Содан кейін 50 000 → автокредит. Жалпы үнемдеу: ~85 000 теңге пайыз.","Қар шары: 50 000 → карта (кіші қалдық). Карта да 3 айда жабылады — бірдей мерзім! Мұнда кіші қарыз ең жоғары мөлшерлемемен сәйкес келгендіктен, айырмашылық аз."]},{"type":"paragraph","text":"Ереже: егер ең кіші қалдық және ең жоғары мөлшерлеме бір қарыз болса — екі әдіс тең нәтиже береді. Болмаса — көшкін көбірек үнемдейді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Лучшая стратегия — та, которой вы будете придерживаться. Если математика мотивирует — лавина. Если вам нужны быстрые победы — снежный ком. Плохой только один вариант: не делать ничего."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"The best strategy is the one you will actually stick to. If math motivates you — avalanche. If you need quick wins to stay on track — snowball. The only bad option is doing nothing."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_payoff_strategies' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"Ең жақсы стратегия — сіз ұстана алатыны. Математика мотивациялайтын болса — көшкін. Жылдам жетістіктер қажет болса — қар шары. Жаман нұсқа тек біреу: ештеңе жасамау."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ══════════════════════════════════════════════════════════════
-- SUBTOPIC: dc_credit_score | 4 steps
-- ══════════════════════════════════════════════════════════════

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 1), 'ru', 'Ваша финансовая репутация', '{"blocks":[{"type":"paragraph","text":"Кредитная история — это ваша финансовая репутация. Банки, арендодатели, а иногда и работодатели смотрят на неё, чтобы понять: можно ли вам доверять."},{"type":"paragraph","text":"Хорошая история открывает двери и снижает ставки. Плохая — закрывает их или делает кредит очень дорогим."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 1), 'en', 'Your Financial Reputation', '{"blocks":[{"type":"paragraph","text":"Your credit history is your financial reputation. Banks, landlords, and sometimes employers look at it to decide: can this person be trusted?"},{"type":"paragraph","text":"A good history opens doors and lowers rates. A poor one closes them or makes borrowing very expensive."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 1), 'kk', 'Сіздің қаржылық беделіңіз', '{"blocks":[{"type":"paragraph","text":"Несиелік тарих — бұл сіздің қаржылық беделіңіз. Банктер, жалға берушілер, кейде жұмыс берушілер оны қарайды: бұл адамға сенуге бола ма?"},{"type":"paragraph","text":"Жақсы тарих есіктерді ашып, мөлшерлемені төмендетеді. Нашары — оларды жабады немесе несиені өте қымбатқа түсіреді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 2), 'ru', 'Что движет вашей историей',
     '{"blocks":[{"type":"paragraph","text":"Системы оценки кредита отличаются по странам, но пять факторов универсальны:"},{"type":"table","headers":["Фактор","Вес","Что улучшает"],"rows":[["Своевременность платежей","~35%","Ни одной просрочки — никогда"],["Утилизация лимита","~30%","Держать задолженность ниже 30% лимита карты"],["Длина истории","~15%","Не закрывать старые счета без причины"],["Новые запросы","~10%","Не подавать много заявок одновременно"],["Разнообразие типов","~10%","Иметь разные виды кредита"]]},{"type":"paragraph","text":"Первые два фактора вместе — 65%. Платите вовремя и не перегружайте карты. Остальное придёт само."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 2), 'en', 'What Drives Your Score',
     '{"blocks":[{"type":"paragraph","text":"Scoring models differ by country, but five factors are universal:"},{"type":"table","headers":["Factor","Weight","What helps"],"rows":[["Payment history","~35%","Never miss a payment — not once"],["Credit utilization","~30%","Keep balances below 30% of your card limit"],["Length of history","~15%","Do not close old accounts without reason"],["New inquiries","~10%","Do not apply for many loans at once"],["Credit mix","~10%","Having different types of credit"]]},{"type":"paragraph","text":"The first two factors together are 65% of your score. Pay on time and do not max out cards. Everything else follows."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 2), 'kk', 'Тарихыңызды нелер қозғайды',
     '{"blocks":[{"type":"paragraph","text":"Бағалау жүйелері елге қарай ерекшеленеді, бірақ бес фактор әмбебап:"},{"type":"table","headers":["Фактор","Үлесі","Не жақсартады"],"rows":[["Төлемдердің уақтылығы","~35%","Ешқашан мерзімін кешіктірмеу"],["Лимиттің пайдалануы","~30%","Карта лимитінің 30%-нан аспау"],["Тарих ұзындығы","~15%","Ескі шоттарды себепсіз жаппау"],["Жаңа сауалдар","~10%","Бір мезгілде көп өтінім бермеу"],["Түрлердің алуандығы","~10%","Әр түрлі несие түрлері болу"]]},{"type":"paragraph","text":"Алғашқы екі фактор бірге ұпайдың 65%. Уақытында төлеңіз және карталарды шамадан тыс жүктемеңіз. Қалғаны өздігінен келеді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 3), 'ru', 'Реальная цена плохой истории',
     '{"blocks":[{"type":"paragraph","text":"Разница в ставке по ипотеке между отличной и плохой кредитной историей может составлять 3–5 процентных пункта. На практике:"},{"type":"table","headers":["История","Ставка","Ипотека 15 млн ₸ на 20 лет","Итого переплата"],"rows":[["Отличная","12%","~165 000 ₸/мес","~24,7 млн ₸"],["Средняя","16%","~207 000 ₸/мес","~34,6 млн ₸"],["Плохая","20%","~249 000 ₸/мес","~44,8 млн ₸"]]},{"type":"paragraph","text":"Разница между отличной и плохой историей — 20 миллионов тенге переплаты на одну ипотеку. Ваша кредитная история стоит реальных денег."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 3), 'en', 'The Real Cost of a Poor Score',
     '{"blocks":[{"type":"paragraph","text":"The difference in mortgage rates between excellent and poor credit history can be 3–5 percentage points. In practice:"},{"type":"table","headers":["History","Rate","15M KZT mortgage, 20 years","Total interest paid"],"rows":[["Excellent","12%","~165,000 ₸/mo","~24.7M ₸"],["Average","16%","~207,000 ₸/mo","~34.6M ₸"],["Poor","20%","~249,000 ₸/mo","~44.8M ₸"]]},{"type":"paragraph","text":"The difference between excellent and poor history: 20 million KZT in extra interest on a single mortgage. Your credit history has a real price tag."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 3), 'kk', 'Нашар тарихтың нақты бағасы',
     '{"blocks":[{"type":"paragraph","text":"Тамаша және нашар несиелік тарих арасындағы ипотека мөлшерлемесіндегі айырмашылық 3–5 пайыздық тармақты құрауы мүмкін. Іс жүзінде:"},{"type":"table","headers":["Тарих","Мөлшерлеме","15 млн ₸ ипотека, 20 жыл","Жалпы артық төлем"],"rows":[["Тамаша","12%","~165 000 ₸/ай","~24,7 млн ₸"],["Орташа","16%","~207 000 ₸/ай","~34,6 млн ₸"],["Нашар","20%","~249 000 ₸/ай","~44,8 млн ₸"]]},{"type":"paragraph","text":"Тамаша және нашар тарих арасындағы айырмашылық — бір ипотекада 20 миллион теңге артық төлем. Сіздің несиелік тарихыңыздың нақты бағасы бар."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Два действия покрывают 65% вашего результата: платите вовремя и не используйте больше 30% лимита карты. Всё остальное — оптимизация. Начните с этих двух."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"Two actions cover 65% of your score: pay on time, every time, and keep card balances below 30% of the limit. Everything else is optimization. Start with these two."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'dc_credit_score' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"Екі іс-әрекет ұпайыңыздың 65%-ын қамтиды: уақытында төлеңіз және карта қалдығын лимиттің 30%-нан аспатыңыз. Қалғаны — оңтайландыру. Осы екеуінен бастаңыз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

commit;