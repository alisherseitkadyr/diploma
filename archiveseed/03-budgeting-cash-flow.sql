-- ══════════════════════════════════════════════════════════════
-- TOPIC 03: budgeting_cash_flow
-- Part 1 | Track A | Level: beginner
-- 4 subtopics | ~17 min total
-- ══════════════════════════════════════════════════════════════

insert into topics (code, level, order_index, is_active) values
    ('budgeting_cash_flow', 'beginner', 6, true)
on conflict (code) do update set
    level = excluded.level, order_index = excluded.order_index,
    is_active = excluded.is_active, updated_at = now();

insert into topic_translations (topic_id, language_code, title, description) values
    ((select id from topics where code = 'budgeting_cash_flow'), 'ru', 'Бюджет и денежный поток',    'Как перестать гадать, куда уходят деньги, и начать управлять ими'),
    ((select id from topics where code = 'budgeting_cash_flow'), 'en', 'Budgeting & Cash Flow',       'How to stop guessing where your money goes and start directing it'),
    ((select id from topics where code = 'budgeting_cash_flow'), 'kk', 'Бюджет және ақша ағыны',     'Ақшаның қайда кететінін болжауды тоқтатып, оны басқаруды бастау')
on conflict (topic_id, language_code) do update set title = excluded.title, description = excluded.description;

insert into subtopics (topic_id, code, order_index, estimated_minutes, is_active) values
    ((select id from topics where code = 'budgeting_cash_flow'), 'bc_fixed_variable',    1, 3, true),
    ((select id from topics where code = 'budgeting_cash_flow'), 'bc_budget_methods',    2, 5, true),
    ((select id from topics where code = 'budgeting_cash_flow'), 'bc_spending_audit',    3, 4, true),
    ((select id from topics where code = 'budgeting_cash_flow'), 'bc_cut_expenses',      4, 5, true)
on conflict (code) do update set
    order_index = excluded.order_index, estimated_minutes = excluded.estimated_minutes,
    is_active = excluded.is_active, updated_at = now();

insert into subtopic_translations (subtopic_id, language_code, title) values
    ((select id from subtopics where code = 'bc_fixed_variable'), 'ru', 'Постоянные и переменные расходы'),
    ((select id from subtopics where code = 'bc_budget_methods'), 'ru', 'Методы бюджетирования'),
    ((select id from subtopics where code = 'bc_spending_audit'), 'ru', '30-дневный аудит расходов'),
    ((select id from subtopics where code = 'bc_cut_expenses'),   'ru', 'Сокращение расходов'),
    ((select id from subtopics where code = 'bc_fixed_variable'), 'en', 'Fixed vs Variable Expenses'),
    ((select id from subtopics where code = 'bc_budget_methods'), 'en', 'Budget Methods'),
    ((select id from subtopics where code = 'bc_spending_audit'), 'en', '30-Day Spending Audit'),
    ((select id from subtopics where code = 'bc_cut_expenses'),   'en', 'Cutting Expenses'),
    ((select id from subtopics where code = 'bc_fixed_variable'), 'kk', 'Тұрақты және өзгермелі шығындар'),
    ((select id from subtopics where code = 'bc_budget_methods'), 'kk', 'Бюджеттеу әдістері'),
    ((select id from subtopics where code = 'bc_spending_audit'), 'kk', '30 күндік шығындар аудиті'),
    ((select id from subtopics where code = 'bc_cut_expenses'),   'kk', 'Шығындарды қысқарту')
on conflict (subtopic_id, language_code) do update set title = excluded.title;

insert into lessons (subtopic_id, is_published)
select id, true from subtopics
where code in ('bc_fixed_variable','bc_budget_methods','bc_spending_audit','bc_cut_expenses')
on conflict (subtopic_id) do update set is_published = excluded.is_published;

insert into quizzes (subtopic_code, topic_code, quiz_type, passing_score, is_active) values
    (null, 'budgeting_cash_flow', 'topic_final_quiz', 75, true)
on conflict (topic_code) where quiz_type = 'topic_final_quiz' do update set
    passing_score = excluded.passing_score, is_active = excluded.is_active, updated_at = now();

insert into quiz_translations (quiz_id, language_code, title) values
    ((select id from quizzes where topic_code = 'budgeting_cash_flow' and quiz_type = 'topic_final_quiz'), 'ru', 'Итоговый квиз: Бюджет и денежный поток'),
    ((select id from quizzes where topic_code = 'budgeting_cash_flow' and quiz_type = 'topic_final_quiz'), 'en', 'Final Quiz: Budgeting & Cash Flow'),
    ((select id from quizzes where topic_code = 'budgeting_cash_flow' and quiz_type = 'topic_final_quiz'), 'kk', 'Қорытынды тест: Бюджет және ақша ағыны')
on conflict (quiz_id, language_code) do update set title = excluded.title;

-- ══════════════════════════════════════════════════════════════
-- QUIZ QUESTIONS
-- ══════════════════════════════════════════════════════════════

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('bc_fixed_variable', 70, '[
        {"lang":"ru","title":"Квиз: Постоянные и переменные расходы"},
        {"lang":"en","title":"Quiz: Fixed vs Variable Expenses"},
        {"lang":"kk","title":"Тест: Тұрақты және өзгермелі шығындар"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'multiple_choice',
        '[{"lang":"ru","text":"Какие из этих расходов являются постоянными? (выберите все верные)"},
          {"lang":"en","text":"Which of these are fixed expenses? (select all that apply)"},
          {"lang":"kk","text":"Осылардың қайсысы тұрақты шығындар? (барлық дұрысты белгілеңіз)"}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Аренда квартиры"},{"lang":"en","text":"Apartment rent"},{"lang":"kk","text":"Пәтер жалдау"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Расходы на продукты"},{"lang":"en","text":"Grocery spending"},{"lang":"kk","text":"Азық-түлік шығындары"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"Ежемесячный платёж по кредиту"},{"lang":"en","text":"Monthly loan payment"},{"lang":"kk","text":"Несие бойынша ай сайынғы төлем"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Расходы на такси"},{"lang":"en","text":"Taxi spending"},{"lang":"kk","text":"Такси шығындары"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Почему переменные расходы важнее контролировать, чем постоянные?"},
          {"lang":"en","text":"Why is it more important to control variable expenses than fixed ones?"},
          {"lang":"kk","text":"Неліктен өзгермелі шығындарды тұрақты шығындарға қарағанда бақылау маңыздырақ?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Постоянные расходы нельзя изменить вообще"},{"lang":"en","text":"Fixed expenses can never be changed"},{"lang":"kk","text":"Тұрақты шығындарды мүлдем өзгертуге болмайды"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Переменные расходы можно контролировать каждый день — они и формируют большую часть перерасхода"},{"lang":"en","text":"Variable expenses can be controlled daily and are where most overspending happens"},{"lang":"kk","text":"Өзгермелі шығындарды күн сайын бақылауға болады — артық шығынның басым бөлігі осыдан келеді"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Переменные расходы всегда больше постоянных"},{"lang":"en","text":"Variable expenses are always larger than fixed ones"},{"lang":"kk","text":"Өзгермелі шығындар әрқашан тұрақтыдан үлкен"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Банки требуют детализировать переменные расходы"},{"lang":"en","text":"Banks require detailed tracking of variable expenses"},{"lang":"kk","text":"Банктер өзгермелі шығындарды толық есепке алуды талап етеді"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'single_choice',
        '[{"lang":"ru","text":"Мадина тратит на аренду 120 000 ₸, на Netflix 3 500 ₸, на продукты ~55 000 ₸, на кредит 45 000 ₸. Её постоянные расходы составляют:"},
          {"lang":"en","text":"Madina pays 120,000 ₸ rent, 3,500 ₸ Netflix, ~55,000 ₸ groceries, 45,000 ₸ loan. Her fixed expenses total:"},
          {"lang":"kk","text":"Мадина жалдауға 120 000 ₸, Netflix-ке 3 500 ₸, азық-түлікке ~55 000 ₸, несиеге 45 000 ₸ жұмсайды. Оның тұрақты шығындары:"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"223 500 ₸ — всё перечисленное"},{"lang":"en","text":"223,500 ₸ — everything listed"},{"lang":"kk","text":"223 500 ₸ — барлығы"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"168 500 ₸ — аренда + Netflix + кредит"},{"lang":"en","text":"168,500 ₸ — rent + Netflix + loan"},{"lang":"kk","text":"168 500 ₸ — жалдау + Netflix + несие"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"165 000 ₸ — только аренда и кредит"},{"lang":"en","text":"165,000 ₸ — rent and loan only"},{"lang":"kk","text":"165 000 ₸ — тек жалдау және несие"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"120 000 ₸ — только аренда"},{"lang":"en","text":"120,000 ₸ — rent only"},{"lang":"kk","text":"120 000 ₸ — тек жалдау"}]}]'::jsonb);
end $$;

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('bc_budget_methods', 70, '[
        {"lang":"ru","title":"Квиз: Методы бюджетирования"},
        {"lang":"en","title":"Quiz: Budget Methods"},
        {"lang":"kk","title":"Тест: Бюджеттеу әдістері"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"По методу 50/30/20 человек с чистым доходом 300 000 ₸ должен тратить на нужды не более:"},
          {"lang":"en","text":"Using the 50/30/20 rule on a 300,000 ₸ net income, the maximum for needs is:"},
          {"lang":"kk","text":"50/30/20 әдісі бойынша таза табысы 300 000 ₸ адам қажеттіліктерге ең көп шамамен жұмсауы керек:"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"90 000 ₸"},{"lang":"en","text":"90,000 ₸"},{"lang":"kk","text":"90 000 ₸"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"150 000 ₸"},{"lang":"en","text":"150,000 ₸"},{"lang":"kk","text":"150 000 ₸"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"200 000 ₸"},{"lang":"en","text":"200,000 ₸"},{"lang":"kk","text":"200 000 ₸"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"60 000 ₸"},{"lang":"en","text":"60,000 ₸"},{"lang":"kk","text":"60 000 ₸"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Принцип «заплати сначала себе» означает:"},
          {"lang":"en","text":"The pay-yourself-first principle means:"},
          {"lang":"kk","text":"«Алдымен өзіңізге төлеңіз» принципі дегеніміз:"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Сначала оплатить все счета, потом всё остальное"},{"lang":"en","text":"Pay all bills first, then everything else"},{"lang":"kk","text":"Алдымен барлық шоттарды төлеу, содан кейін қалғанын"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Тратить на себя столько, сколько хочется"},{"lang":"en","text":"Spend on yourself as much as you want"},{"lang":"kk","text":"Өзіңізге қаншалықты қаласаңыз сонша жұмсау"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"Автоматически откладывать сбережения в день зарплаты до любых расходов"},{"lang":"en","text":"Automatically transfer savings on payday before any spending"},{"lang":"kk","text":"Кез келген шығынға дейін жалақы күні жинақты автоматты түрде аудару"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Не брать кредиты ни при каких обстоятельствах"},{"lang":"en","text":"Never take out loans under any circumstances"},{"lang":"kk","text":"Ешқандай жағдайда несие алмау"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'single_choice',
        '[{"lang":"ru","text":"Нулевой бюджет (zero-based budgeting) означает, что в конце месяца:"},
          {"lang":"en","text":"Zero-based budgeting means that at the end of the month:"},
          {"lang":"kk","text":"Нөлдік бюджет (zero-based budgeting) ай соңында мынаны білдіреді:"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"На счету должно быть ровно 0 тенге"},{"lang":"en","text":"Your account balance must be exactly zero"},{"lang":"kk","text":"Шотта дәл 0 теңге болуы керек"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Каждый тенге дохода заранее получил роль — доход минус все распределения равно нулю"},{"lang":"en","text":"Every tenge of income has been assigned a job — income minus all allocations equals zero"},{"lang":"kk","text":"Табыстың әр теңгесіне алдын ала рөл берілген — табыс пен барлық бөлулердің айырмасы нөлге тең"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Все кредиты должны быть погашены"},{"lang":"en","text":"All loans must be paid off"},{"lang":"kk","text":"Барлық несиелер өтелуі керек"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Сбережений не остаётся"},{"lang":"en","text":"No savings remain"},{"lang":"kk","text":"Жинақ қалмайды"}]}]'::jsonb);
end $$;

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('bc_spending_audit', 70, '[
        {"lang":"ru","title":"Квиз: Аудит расходов"},
        {"lang":"en","title":"Quiz: Spending Audit"},
        {"lang":"kk","title":"Тест: Шығындар аудиті"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Зачем вести учёт расходов в течение 30 дней, прежде чем строить бюджет?"},
          {"lang":"en","text":"Why track spending for 30 days before building a budget?"},
          {"lang":"kk","text":"Бюджет жасаудан бұрын 30 күн бойы шығындарды неліктен жазу керек?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Этого требует банк"},{"lang":"en","text":"The bank requires it"},{"lang":"kk","text":"Банк талап етеді"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Чтобы строить бюджет на реальных цифрах, а не на догадках"},{"lang":"en","text":"To build a budget on real numbers, not guesses"},{"lang":"kk","text":"Болжаммен емес, нақты сандар негізінде бюджет жасау үшін"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Чтобы сразу сократить все лишние траты"},{"lang":"en","text":"To immediately cut all unnecessary spending"},{"lang":"kk","text":"Барлық артық шығындарды бірден қысқарту үшін"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Это нужно только людям с долгами"},{"lang":"en","text":"This is only needed for people with debt"},{"lang":"kk","text":"Бұл тек қарыздары бар адамдарға қажет"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'true_false',
        '[{"lang":"ru","text":"Большинство людей точно знают, сколько они тратят на кофе, доставку еды и развлечения каждый месяц."},
          {"lang":"en","text":"Most people accurately know how much they spend on coffee, food delivery, and entertainment each month."},
          {"lang":"kk","text":"Адамдардың көпшілігі ай сайын кофеге, тағам жеткізуге және ойын-сауыққа қанша жұмсайтынын дәл біледі."}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Верно"},{"lang":"en","text":"True"},{"lang":"kk","text":"Дұрыс"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Неверно — исследования показывают, что люди систематически занижают мелкие ежедневные траты"},{"lang":"en","text":"False — research shows people consistently underestimate small daily spending"},{"lang":"kk","text":"Дұрыс емес — зерттеулер адамдардың ұсақ күнделікті шығындарды жүйелі түрде бағаламайтынын көрсетеді"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только те, кто использует приложения"},{"lang":"en","text":"Only those who use apps"},{"lang":"kk","text":"Тек қолданбаларды пайдаланатындар"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только при безналичных платежах"},{"lang":"en","text":"Only with cashless payments"},{"lang":"kk","text":"Тек қолма-қол емес төлемдер кезінде"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'single_choice',
        '[{"lang":"ru","text":"После 30-дневного аудита Арман обнаружил, что тратит 28 000 ₸ в месяц на доставку еды. Что это даёт?"},
          {"lang":"en","text":"After a 30-day audit, Arman found he spends 28,000 ₸ per month on food delivery. What does this give him?"},
          {"lang":"kk","text":"30 күндік аудиттен кейін Арман ай сайын тағам жеткізуге 28 000 ₸ жұмсайтынын анықтады. Бұл оған не береді?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Ничего — это его деньги и его выбор"},{"lang":"en","text":"Nothing — it is his money and his choice"},{"lang":"kk","text":"Ештеңе — бұл оның ақшасы және оның таңдауы"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Осознанный выбор: он может решить, стоит ли это удовольствие той суммы, или перенаправить часть средств"},{"lang":"en","text":"An informed choice: he can decide whether that pleasure is worth the cost, or redirect some of it"},{"lang":"kk","text":"Саналы таңдау: ол осы рахаттың осынша сомаға тұрарлығын шеше алады немесе бір бөлігін қайта бағыттай алады"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Обязательство полностью отказаться от доставки"},{"lang":"en","text":"An obligation to quit food delivery entirely"},{"lang":"kk","text":"Тағам жеткізуден мүлдем бас тарту міндеттемесі"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Повод для стыда и самокритики"},{"lang":"en","text":"A reason for shame and self-criticism"},{"lang":"kk","text":"Ұялу мен өзін-өзі сынауға себеп"}]}]'::jsonb);
end $$;

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('bc_cut_expenses', 70, '[
        {"lang":"ru","title":"Квиз: Сокращение расходов"},
        {"lang":"en","title":"Quiz: Cutting Expenses"},
        {"lang":"kk","title":"Тест: Шығындарды қысқарту"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Какие три категории расходов дают наибольший эффект при сокращении?"},
          {"lang":"en","text":"Which three expense categories give the biggest impact when reduced?"},
          {"lang":"kk","text":"Қысқарту кезінде ең үлкен нәтиже беретін үш шығын санаты қандай?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Кофе, подписки, одежда"},{"lang":"en","text":"Coffee, subscriptions, clothing"},{"lang":"kk","text":"Кофе, жазылымдар, киім"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Жильё, транспорт, еда"},{"lang":"en","text":"Housing, transport, food"},{"lang":"kk","text":"Тұрғын үй, көлік, тамақ"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Развлечения, путешествия, рестораны"},{"lang":"en","text":"Entertainment, travel, restaurants"},{"lang":"kk","text":"Ойын-сауық, саяхат, мейрамханалар"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Телефон, интернет, коммунальные услуги"},{"lang":"en","text":"Phone, internet, utilities"},{"lang":"kk","text":"Телефон, интернет, коммуналдық қызметтер"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'true_false',
        '[{"lang":"ru","text":"Отказ от ежедневного кофе — лучшая стратегия для экономии значительной суммы денег."},
          {"lang":"en","text":"Giving up daily coffee is the best strategy for saving a significant amount of money."},
          {"lang":"kk","text":"Күнделікті кофеден бас тарту — айтарлықтай ақша үнемдеудің ең жақсы стратегиясы."}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Верно"},{"lang":"en","text":"True"},{"lang":"kk","text":"Дұрыс"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Неверно — экономия на «латте» даёт копейки по сравнению с оптимизацией жилья, транспорта и еды"},{"lang":"en","text":"False — cutting the latte saves pennies compared to optimising housing, transport, and food"},{"lang":"kk","text":"Дұрыс емес — «латте» сатып алмау тұрғын үй, көлік және тамақты оңтайландырумен салыстырғанда тиын ғана үнемдейді"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только для людей с доходом менее 200 000 ₸"},{"lang":"en","text":"Only for people earning under 200,000 ₸"},{"lang":"kk","text":"Тек табысы 200 000 ₸-дан аз адамдарға"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Зависит от цены кофе"},{"lang":"en","text":"It depends on the price of coffee"},{"lang":"kk","text":"Бұл кофенің бағасына байланысты"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'single_choice',
        '[{"lang":"ru","text":"Какой подход к сокращению расходов наиболее устойчив в долгосрочной перспективе?"},
          {"lang":"en","text":"Which approach to cutting expenses is most sustainable long-term?"},
          {"lang":"kk","text":"Шығындарды қысқартудың қай тәсілі ұзақ мерзімді тұрғыдан ең тұрақты?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Урезать все удовольствия сразу"},{"lang":"en","text":"Cut all pleasures at once"},{"lang":"kk","text":"Барлық рахаттарды бірден қысқарту"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Перестать есть в ресторанах навсегда"},{"lang":"en","text":"Stop eating at restaurants forever"},{"lang":"kk","text":"Мейрамханаларда мәңгіге тамақтануды тоқтату"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"Оптимизировать большие статьи (жильё, авто, еда), сохранив небольшие радости"},{"lang":"en","text":"Optimise the big items (housing, car, food) while keeping small pleasures intact"},{"lang":"kk","text":"Ірі баптамаларды (тұрғын үй, авто, тамақ) оңтайландырып, ұсақ рахаттарды сақтау"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Жить на 20% дохода и инвестировать остальное"},{"lang":"en","text":"Live on 20% of income and invest the rest"},{"lang":"kk","text":"Табыстың 20%-ына өмір сүріп, қалғанын инвестициялау"}]}]'::jsonb);
end $$;

-- ══════════════════════════════════════════════════════════════
-- LESSON STEPS
-- ══════════════════════════════════════════════════════════════
begin;

-- ── bc_fixed_variable ─────────────────────────────────────────
insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable'), 'introduction', 1) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 1), 'ru', 'Введение', '{"blocks":[{"type":"paragraph","text":"Прежде чем управлять расходами, нужно их классифицировать. Не все траты одинаково гибкие — и это меняет то, где именно вы будете искать возможности для экономии."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 1), 'en', 'Introduction', '{"blocks":[{"type":"paragraph","text":"Before managing expenses, you need to categorise them. Not all spending is equally flexible — and that changes where you will look for savings."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 1), 'kk', 'Кіріспе', '{"blocks":[{"type":"paragraph","text":"Шығындарды басқармас бұрын, оларды жіктеу керек. Барлық шығындар бірдей икемді емес — бұл үнемдеу мүмкіндіктерін іздейтін жеріңізді өзгертеді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable'), 'explanation', 2) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 2), 'ru', 'Постоянные vs переменные', '{"blocks":[{"type":"paragraph","text":"Постоянные расходы — одинаковые каждый месяц: аренда, кредитные платежи, подписки. Их трудно изменить быстро, но именно здесь самые большие суммы."},{"type":"paragraph","text":"Переменные расходы — меняются каждый месяц: продукты, кафе, такси, одежда, развлечения. Здесь больше гибкости и, как правило, больше неосознанных трат."},{"type":"paragraph","text":"Правило: сначала оптимизируй постоянные (они дают разовый, но крупный выигрыш), потом системно управляй переменными (это требует дисциплины, но даёт ежемесячный результат)."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 2), 'en', 'Fixed vs Variable', '{"blocks":[{"type":"paragraph","text":"Fixed expenses are the same every month: rent, loan payments, subscriptions. Hard to change quickly, but this is where the biggest numbers live."},{"type":"paragraph","text":"Variable expenses change monthly: groceries, cafes, taxis, clothing, entertainment. More flexibility here — and usually more unconscious spending."},{"type":"paragraph","text":"Rule: optimise fixed expenses first (one-time but large win), then systematically manage variable ones (requires discipline but delivers monthly results)."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 2), 'kk', 'Тұрақты vs өзгермелі', '{"blocks":[{"type":"paragraph","text":"Тұрақты шығындар — ай сайын бірдей: жалдау, несие төлемдері, жазылымдар. Тез өзгерту қиын, бірақ ең үлкен сомалар осында."},{"type":"paragraph","text":"Өзгермелі шығындар — ай сайын өзгереді: азық-түлік, кафе, такси, киім, ойын-сауық. Мұнда икемділік көбірек — және, әдетте, саналы емес шығындар да көбірек."},{"type":"paragraph","text":"Ереже: алдымен тұрақты шығындарды оңтайландырыңыз (бір реттік, бірақ ірі ұтыс), содан кейін өзгермелілерді жүйелі басқарыңыз (тәртіп керек, бірақ ай сайын нәтиже береді)."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable'), 'example', 3) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 3), 'ru', 'Пример: бюджет Мадины', '{"blocks":[{"type":"table","headers":["Категория","Сумма","Тип"],"rows":[["Аренда квартиры","120 000 ₸","Постоянный"],["Платёж по кредиту","45 000 ₸","Постоянный"],["Netflix","3 500 ₸","Постоянный"],["Продукты","55 000 ₸","Переменный"],["Кафе и доставка","22 000 ₸","Переменный"],["Транспорт","18 000 ₸","Переменный"],["Одежда","15 000 ₸","Переменный"]]},{"type":"paragraph","text":"Мадина видит: постоянные расходы — 168 500 ₸, переменные — 110 000 ₸. Чтобы сэкономить, проще всего начать с переменных. Но переезд в квартиру на 20 000 ₸ дешевле сэкономит больше за год, чем все остальные оптимизации."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 3), 'en', 'Example: Madina''s Budget', '{"blocks":[{"type":"table","headers":["Category","Amount","Type"],"rows":[["Apartment rent","120,000 ₸","Fixed"],["Loan payment","45,000 ₸","Fixed"],["Netflix","3,500 ₸","Fixed"],["Groceries","55,000 ₸","Variable"],["Cafes & delivery","22,000 ₸","Variable"],["Transport","18,000 ₸","Variable"],["Clothing","15,000 ₸","Variable"]]},{"type":"paragraph","text":"Madina sees: fixed expenses 168,500 ₸, variable 110,000 ₸. The easiest place to start saving is variable. But moving to a flat 20,000 ₸ cheaper saves more over a year than all the other optimisations combined."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 3), 'kk', 'Мысал: Мадинаның бюджеті', '{"blocks":[{"type":"table","headers":["Санат","Сома","Түрі"],"rows":[["Пәтер жалдау","120 000 ₸","Тұрақты"],["Несие төлемі","45 000 ₸","Тұрақты"],["Netflix","3 500 ₸","Тұрақты"],["Азық-түлік","55 000 ₸","Өзгермелі"],["Кафе және жеткізу","22 000 ₸","Өзгермелі"],["Көлік","18 000 ₸","Өзгермелі"],["Киім","15 000 ₸","Өзгермелі"]]},{"type":"paragraph","text":"Мадина көреді: тұрақты шығындар — 168 500 ₸, өзгермелі — 110 000 ₸. Үнемдеуді бастаудың ең оңай жері — өзгермелілер. Бірақ 20 000 ₸ арзанырақ пәтерге көшу бір жыл ішінде барлық басқа оңтайландырулардан бірге алғанда үнемдейді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable'), 'conclusion', 4) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Постоянные расходы — большие числа, редко меняются. Переменные — гибкие, ежедневный контроль. Оптимизируй оба слоя, начиная с наибольшего выигрыша."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"Fixed expenses are big numbers, changed rarely. Variable expenses are flexible, controlled daily. Optimise both layers, starting with the biggest win."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_fixed_variable' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"Тұрақты шығындар — үлкен сандар, сирек өзгереді. Өзгермелі шығындар — икемді, күнделікті бақылау. Ең үлкен ұтыстан бастап екі деңгейді де оңтайландырыңыз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── bc_budget_methods ─────────────────────────────────────────
insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods'), 'introduction', 1) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 1), 'ru', 'Введение', '{"blocks":[{"type":"paragraph","text":"Бюджет — не наказание. Это план того, что вы хотите делать со своими деньгами, до того как они разошлись сами по себе. Подходов несколько, и лучший — тот, которого вы будете придерживаться."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 1), 'en', 'Introduction', '{"blocks":[{"type":"paragraph","text":"A budget is not a punishment. It is a plan for what you want to do with your money before it decides for itself. There are several approaches — the best one is the one you will actually follow."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 1), 'kk', 'Кіріспе', '{"blocks":[{"type":"paragraph","text":"Бюджет — жаза емес. Бұл ақшаңыз өздігінен кетіп қалмас бұрын, онымен не істегіңіз келетінінің жоспары. Бірнеше тәсіл бар — ең жақсысы — сіз шынымен ұстанатыны."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods'), 'explanation', 2) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 2), 'ru', 'Три метода', '{"blocks":[{"type":"table","headers":["Метод","Принцип","Кому подходит"],"rows":[["50/30/20","50% — нужды, 30% — желания, 20% — сбережения","Новичкам, хотят простую структуру"],["Нулевой бюджет","Каждому тенге — роль, доход − расходы = 0","Любят детальный контроль"],["Заплати сначала себе","Сбережения уходят автоматически в день зарплаты","Не хотят думать о бюджете каждый день"]]},{"type":"paragraph","text":"Все три метода работают. Разница — в уровне детализации и дисциплины, которую они требуют."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 2), 'en', 'Three Methods', '{"blocks":[{"type":"table","headers":["Method","Principle","Best for"],"rows":[["50/30/20","50% needs, 30% wants, 20% savings","Beginners who want simple structure"],["Zero-based","Every tenge has a job, income − expenses = 0","People who love detailed control"],["Pay yourself first","Savings auto-transfer on payday before any spending","Those who dislike budgeting daily"]]},{"type":"paragraph","text":"All three methods work. The difference is the level of detail and discipline each requires."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 2), 'kk', 'Үш әдіс', '{"blocks":[{"type":"table","headers":["Әдіс","Принцип","Кімге сәйкес"],"rows":[["50/30/20","50% — қажеттіліктер, 30% — тілектер, 20% — жинақ","Қарапайым құрылым қалайтын жаңадан бастаушылар"],["Нөлдік бюджет","Әр теңгеге рөл, табыс − шығын = 0","Егжей-тегжейлі бақылауды жақсы көретіндер"],["Алдымен өзіңізге төлеңіз","Жалақы күні кез келген шығынға дейін жинақ автоматты аударылады","Күн сайын бюджет туралы ойлағысы келмейтіндер"]]},{"type":"paragraph","text":"Үш әдіс те жұмыс істейді. Айырмашылығы — олар талап ететін егжей-тегжей деңгейі мен тәртіпте."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods'), 'example', 3) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 3), 'ru', 'Пример: 50/30/20 для Айши', '{"blocks":[{"type":"paragraph","text":"Чистый доход Айши — 220 000 ₸."},{"type":"table","headers":["Категория","Лимит","Что входит"],"rows":[["Нужды (50%)","110 000 ₸","Аренда 80 000, коммуналка 10 000, продукты 20 000"],["Желания (30%)","66 000 ₸","Кафе, одежда, развлечения, такси"],["Сбережения (20%)","44 000 ₸","Экстренный фонд + цель на машину"]]},{"type":"paragraph","text":"Первый месяц нужды составили 118 000 — на 8 000 больше лимита. Айша решила не гнаться за идеалом сразу, а сокращать аренду при следующем переезде."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 3), 'en', 'Example: 50/30/20 for Aisha', '{"blocks":[{"type":"paragraph","text":"Aisha''s net income: 220,000 ₸."},{"type":"table","headers":["Category","Limit","What''s included"],"rows":[["Needs (50%)","110,000 ₸","Rent 80,000 + utilities 10,000 + groceries 20,000"],["Wants (30%)","66,000 ₸","Cafes, clothing, entertainment, taxis"],["Savings (20%)","44,000 ₸","Emergency fund + car goal"]]},{"type":"paragraph","text":"First month her needs were 118,000 — 8,000 over the limit. Aisha decided not to chase perfection immediately, but to reduce rent at her next move."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 3), 'kk', 'Мысал: Айша үшін 50/30/20', '{"blocks":[{"type":"paragraph","text":"Айшаның таза табысы — 220 000 ₸."},{"type":"table","headers":["Санат","Шек","Не кіреді"],"rows":[["Қажеттіліктер (50%)","110 000 ₸","Жалдау 80 000 + коммуналдық 10 000 + азық-түлік 20 000"],["Тілектер (30%)","66 000 ₸","Кафе, киім, ойын-сауық, такси"],["Жинақ (20%)","44 000 ₸","Төтенше қор + көлік мақсаты"]]},{"type":"paragraph","text":"Бірінші айда қажеттіліктері 118 000 болды — шектен 8 000 артық. Айша бірден жетілдіруге ұмтылмай, келесі көшуде жалдауды азайтуды шешті."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods'), 'conclusion', 4) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Выберите один метод и попробуйте его в течение 60 дней. Идеальный бюджет, которого не придерживаются, хуже несовершенного, который работает."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"Pick one method and try it for 60 days. A perfect budget that is not followed is worse than an imperfect one that works."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_budget_methods' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"Бір әдісті таңдап, оны 60 күн бойы қолданып көріңіз. Ұсталмаған тамаша бюджет — жұмыс істейтін кемшілік бюджеттен нашар."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── bc_spending_audit ─────────────────────────────────────────
insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit'), 'introduction', 1) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 1), 'ru', 'Введение', '{"blocks":[{"type":"paragraph","text":"Большинство людей думают, что знают, куда уходят деньги. Исследования показывают: они ошибаются — особенно в мелких ежедневных тратах. 30-дневный аудит устраняет это слепое пятно."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 1), 'en', 'Introduction', '{"blocks":[{"type":"paragraph","text":"Most people think they know where their money goes. Research shows they are wrong — especially on small daily spending. The 30-day audit removes that blind spot."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 1), 'kk', 'Кіріспе', '{"blocks":[{"type":"paragraph","text":"Адамдардың көпшілігі ақшасының қайда кететінін білемін деп ойлайды. Зерттеулер олардың қателесетінін көрсетеді — әсіресе ұсақ күнделікті шығындарда. 30 күндік аудит бұл соқыр нүктені жояды."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit'), 'explanation', 2) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 2), 'ru', 'Как провести аудит', '{"blocks":[{"type":"bullet_list","items":["Записывайте каждую трату в день, когда она произошла — не по памяти в конце недели.","Категоризируйте: жильё, транспорт, еда, кафе/доставка, подписки, одежда, здоровье, прочее.","Не цензурируйте себя — цель не осудить, а увидеть.","В конце 30 дней просуммируйте по категориям и сравните с вашими ожиданиями."]},{"type":"paragraph","text":"Инструмент не важен: банковское приложение, таблица, заметки в телефоне. Главное — фиксировать сразу."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 2), 'en', 'How to Run the Audit', '{"blocks":[{"type":"bullet_list","items":["Log every expense on the day it happens — not from memory at the end of the week.","Categorise: housing, transport, food, cafes/delivery, subscriptions, clothing, health, other.","Do not censor yourself — the goal is to see, not to judge.","At the end of 30 days, total by category and compare to your expectations."]},{"type":"paragraph","text":"The tool does not matter: banking app, spreadsheet, phone notes. What matters is logging immediately."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 2), 'kk', 'Аудитті қалай жүргізу керек', '{"blocks":[{"type":"bullet_list","items":["Әр шығынды болған күні жазыңыз — апта соңында жадыңыздан емес.","Санаттаңыз: тұрғын үй, көлік, тамақ, кафе/жеткізу, жазылымдар, киім, денсаулық, басқа.","Өзіңізді цензурамаңыз — мақсат соттамау, көру.","30 күн соңында санаттар бойынша жиынтықтап, күтіліміңізбен салыстырыңыз."]},{"type":"paragraph","text":"Құрал маңызды емес: банк қолданбасы, кесте, телефондағы жазбалар. Маңыздысы — бірден жазу."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit'), 'example', 3) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 3), 'ru', 'Что нашёл Арман', '{"blocks":[{"type":"paragraph","text":"Арман думал, что тратит на еду около 60 000 ₸. Аудит показал:"},{"type":"table","headers":["Категория еды","Факт","Ожидание"],"rows":[["Продукты","42 000 ₸","50 000 ₸"],["Кафе и обеды на работе","18 000 ₸","5 000 ₸"],["Доставка еды","28 000 ₸","5 000 ₸"],["Итого","88 000 ₸","60 000 ₸"]]},{"type":"paragraph","text":"Разрыв в 28 000 ₸ в месяц — это 336 000 ₸ в год. Арман не стал отказываться от доставки совсем. Он поставил лимит 10 000 ₸ в месяц и сэкономил 18 000 ₸ без особых усилий."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 3), 'en', 'What Arman Found', '{"blocks":[{"type":"paragraph","text":"Arman thought he spent about 60,000 ₸ on food. The audit showed:"},{"type":"table","headers":["Food category","Actual","Expected"],"rows":[["Groceries","42,000 ₸","50,000 ₸"],["Cafes & work lunches","18,000 ₸","5,000 ₸"],["Food delivery","28,000 ₸","5,000 ₸"],["Total","88,000 ₸","60,000 ₸"]]},{"type":"paragraph","text":"A gap of 28,000 ₸ per month — 336,000 ₸ per year. Arman did not quit delivery entirely. He set a 10,000 ₸ monthly cap and saved 18,000 ₸ with minimal effort."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 3), 'kk', 'Арман не тапты', '{"blocks":[{"type":"paragraph","text":"Арман тамаққа шамамен 60 000 ₸ жұмсайды деп ойлады. Аудит көрсетті:"},{"type":"table","headers":["Тамақ санаты","Нақты","Күтілген"],"rows":[["Азық-түлік","42 000 ₸","50 000 ₸"],["Кафе және жұмыстағы түскі ас","18 000 ₸","5 000 ₸"],["Тағам жеткізу","28 000 ₸","5 000 ₸"],["Жиыны","88 000 ₸","60 000 ₸"]]},{"type":"paragraph","text":"Айына 28 000 ₸ алшақтық — жылына 336 000 ₸. Арман жеткізуден мүлдем бас тартпады. Ол айына 10 000 ₸ шек қойып, аз күшпен 18 000 ₸ үнемдеді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit'), 'conclusion', 4) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"30-дневный аудит — это разовая инвестиция времени, которая окупается годами экономии. Начните сегодня — в конце месяца у вас будут реальные цифры для настоящего бюджета."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"A 30-day audit is a one-time time investment that pays off for years. Start today — at the end of the month you will have real numbers for a real budget."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_spending_audit' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"30 күндік аудит — жылдар бойы үнемдеуді өтейтін бірреттік уақыт инвестициясы. Бүгін бастаңыз — ай соңында нақты бюджетке арналған нақты сандар болады."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── bc_cut_expenses ───────────────────────────────────────────
insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses'), 'introduction', 1) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 1), 'ru', 'Введение', '{"blocks":[{"type":"paragraph","text":"Отказаться от кофе — плохой совет. Оптимизировать жильё, транспорт и еду — хороший. Разница в том, где реально живут большие деньги."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 1), 'en', 'Introduction', '{"blocks":[{"type":"paragraph","text":"Giving up coffee is bad advice. Optimising housing, transport, and food is good advice. The difference is where the big money actually lives."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 1), 'kk', 'Кіріспе', '{"blocks":[{"type":"paragraph","text":"Кофеден бас тарту — жаман кеңес. Тұрғын үй, көлік және тамақты оңтайландыру — жақсы кеңес. Айырмашылық — үлкен ақша шынымен қай жерде тұрады."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses'), 'explanation', 2) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 2), 'ru', 'Большая тройка', '{"blocks":[{"type":"bullet_list","items":["Жильё (обычно 30–50% расходов) — снять квартиру с соседом, переехать в район подешевле, договориться о снижении аренды. Экономия: 20 000–80 000 ₸/мес.","Транспорт — пересесть с личного авто на общественный транспорт или самокат хотя бы частично. Экономия: 30 000–60 000 ₸/мес.","Еда — готовить дома чаще, ставить лимиты на доставку, брать обед на работу. Экономия: 15 000–40 000 ₸/мес."]},{"type":"paragraph","text":"Всё остальное (кофе, подписки, развлечения) — вторичная оптимизация. Начинайте с того, где деньги большие."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 2), 'en', 'The Big Three', '{"blocks":[{"type":"bullet_list","items":["Housing (usually 30–50% of spending) — share a flat, move to a cheaper area, negotiate a rent reduction. Savings: 20,000–80,000 ₸/mo.","Transport — switch from a personal car to public transport or e-scooter at least partially. Savings: 30,000–60,000 ₸/mo.","Food — cook at home more, cap delivery spending, bring lunch to work. Savings: 15,000–40,000 ₸/mo."]},{"type":"paragraph","text":"Everything else (coffee, subscriptions, entertainment) is secondary. Start where the money is big."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 2), 'kk', 'Үлкен үштік', '{"blocks":[{"type":"bullet_list","items":["Тұрғын үй (әдетте шығынның 30–50%) — бөлмелесімен пәтер жалдау, арзанырақ ауданға көшу, жалдау бағасын азайту туралы келісу. Үнемдеу: 20 000–80 000 ₸/ай.","Көлік — жеке автомобильден қоғамдық көлікке немесе самокатқа кем дегенде жартылай ауысу. Үнемдеу: 30 000–60 000 ₸/ай.","Тамақ — үйде жиі пісіру, жеткізуге шек қою, жұмысқа тамақ алып бару. Үнемдеу: 15 000–40 000 ₸/ай."]},{"type":"paragraph","text":"Қалғанының барлығы (кофе, жазылымдар, ойын-сауық) — екінші деңгейдегі оңтайландыру. Ақша үлкен жерден бастаңыз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses'), 'example', 3) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 3), 'ru', 'Кофе vs квартира', '{"blocks":[{"type":"table","headers":["Действие","Экономия в месяц","Экономия в год"],"rows":[["Отказаться от кофе (1 раз в день × 600 ₸)","18 000 ₸","216 000 ₸"],["Отменить 2 подписки","3 000 ₸","36 000 ₸"],["Взять соседа в квартиру","40 000 ₸","480 000 ₸"],["Продать авто, пересесть на метро","55 000 ₸","660 000 ₸"]]},{"type":"paragraph","text":"Совет «откажись от кофе» экономит 216 000 в год. Совет «возьми соседа» — 480 000. Оба честны. Но один в два раза эффективнее."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 3), 'en', 'Coffee vs Apartment', '{"blocks":[{"type":"table","headers":["Action","Monthly saving","Annual saving"],"rows":[["Cut daily coffee (1×600 ₸)","18,000 ₸","216,000 ₸"],["Cancel 2 subscriptions","3,000 ₸","36,000 ₸"],["Get a flatmate","40,000 ₸","480,000 ₸"],["Sell car, switch to metro","55,000 ₸","660,000 ₸"]]},{"type":"paragraph","text":"''Skip the coffee'' advice saves 216,000 per year. ''Get a flatmate'' saves 480,000. Both are honest. One is twice as powerful."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 3), 'kk', 'Кофе vs пәтер', '{"blocks":[{"type":"table","headers":["Әрекет","Айлық үнемдеу","Жылдық үнемдеу"],"rows":[["Күнделікті кофеден бас тарту (1 рет × 600 ₸)","18 000 ₸","216 000 ₸"],["2 жазылымды бұзу","3 000 ₸","36 000 ₸"],["Пәтерге бөлмелес алу","40 000 ₸","480 000 ₸"],["Көлікті сатып, метроға ауысу","55 000 ₸","660 000 ₸"]]},{"type":"paragraph","text":"«Кофеден бас тарт» кеңесі жылына 216 000 үнемдейді. «Бөлмелес ал» кеңесі — 480 000. Екеуі де адал. Бірақ бірі екі есе тиімді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index) values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses'), 'conclusion', 4) on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Оптимизируйте большое. Сохраните малое, что приносит радость. Устойчивая экономия — это не аскетизм, а осознанность."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"Optimise the big things. Keep the small things that bring joy. Sustainable saving is not asceticism — it is intentionality."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'bc_cut_expenses' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"Үлкен нәрселерді оңтайландырыңыз. Қуаныш әкелетін кішкентай нәрселерді сақтаңыз. Тұрақты үнемдеу — аскетизм емес, саналылық."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

commit;