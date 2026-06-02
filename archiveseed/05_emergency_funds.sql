-- ══════════════════════════════════════════════════════════════
-- TOPIC 05: emergency_funds
-- "Emergency Funds & Savings" | Level: beginner | Order: 5
-- 4 subtopics | ~16 min | Track A
-- Subtopics:
--   ef_why_it_matters    — Why 3–6 months, where to keep it
--   ef_starter_fund      — Building the first 150 000 ₸
--   ef_savings_vehicles  — Where to park your savings
--   ef_sinking_funds     — Sinking funds: saving for known future costs
-- ══════════════════════════════════════════════════════════════

-- ── TOPIC ─────────────────────────────────────────────────────

insert into topics (code, level, order_index, is_active) values
    ('emergency_funds', 'beginner', 9, true)
on conflict (code) do update set
    level = excluded.level, order_index = excluded.order_index,
    is_active = excluded.is_active, updated_at = now();

insert into topic_translations (topic_id, language_code, title, description) values
    ((select id from topics where code = 'emergency_funds'), 'ru', 'Экстренный фонд и сбережения', 'Финансовая подушка, которая превращает кризис в неудобство'),
    ((select id from topics where code = 'emergency_funds'), 'en', 'Emergency Funds & Savings',  'The buffer that turns a crisis into a mere inconvenience'),
    ((select id from topics where code = 'emergency_funds'), 'kk', 'Төтенше қор мен жинақтар',   'Дағдарысты тек ыңғайсыздыққа айналдыратын қаржылық жастық')
on conflict (topic_id, language_code) do update set title = excluded.title, description = excluded.description;

-- ── SUBTOPICS ─────────────────────────────────────────────────

insert into subtopics (topic_id, code, order_index, estimated_minutes, is_active) values
    ((select id from topics where code = 'emergency_funds'), 'ef_why_it_matters',   1, 3, true),
    ((select id from topics where code = 'emergency_funds'), 'ef_starter_fund',     2, 4, true),
    ((select id from topics where code = 'emergency_funds'), 'ef_savings_vehicles', 3, 5, true),
    ((select id from topics where code = 'emergency_funds'), 'ef_sinking_funds',    4, 4, true)
on conflict (code) do update set order_index = excluded.order_index,
    estimated_minutes = excluded.estimated_minutes, is_active = excluded.is_active, updated_at = now();

insert into subtopic_translations (subtopic_id, language_code, title) values
    ((select id from subtopics where code = 'ef_why_it_matters'),   'ru', 'Зачем нужен экстренный фонд'),
    ((select id from subtopics where code = 'ef_starter_fund'),     'ru', 'Как накопить первые 150 000 тенге'),
    ((select id from subtopics where code = 'ef_savings_vehicles'), 'ru', 'Куда положить сбережения'),
    ((select id from subtopics where code = 'ef_sinking_funds'),    'ru', 'Целевые фонды'),
    ((select id from subtopics where code = 'ef_why_it_matters'),   'en', 'Why You Need an Emergency Fund'),
    ((select id from subtopics where code = 'ef_starter_fund'),     'en', 'Building Your First 150,000 KZT'),
    ((select id from subtopics where code = 'ef_savings_vehicles'), 'en', 'Where to Keep Your Savings'),
    ((select id from subtopics where code = 'ef_sinking_funds'),    'en', 'Sinking Funds'),
    ((select id from subtopics where code = 'ef_why_it_matters'),   'kk', 'Неге төтенше қор керек'),
    ((select id from subtopics where code = 'ef_starter_fund'),     'kk', 'Алғашқы 150 000 теңгені қалай жинау'),
    ((select id from subtopics where code = 'ef_savings_vehicles'), 'kk', 'Жинақты қайда сақтау'),
    ((select id from subtopics where code = 'ef_sinking_funds'),    'kk', 'Мақсатты қорлар')
on conflict (subtopic_id, language_code) do update set title = excluded.title;

insert into lessons (subtopic_id, is_published)
select id, true from subtopics
where code in ('ef_why_it_matters','ef_starter_fund','ef_savings_vehicles','ef_sinking_funds')
on conflict (subtopic_id) do update set is_published = excluded.is_published;

insert into quizzes (subtopic_code, topic_code, quiz_type, passing_score, is_active) values
    (null, 'emergency_funds', 'topic_final_quiz', 75, true)
on conflict (topic_code) where quiz_type = 'topic_final_quiz' do update set
    passing_score = excluded.passing_score, is_active = excluded.is_active, updated_at = now();

insert into quiz_translations (quiz_id, language_code, title) values
    ((select id from quizzes where topic_code = 'emergency_funds' and quiz_type = 'topic_final_quiz'), 'ru', 'Итоговый квиз: Экстренный фонд'),
    ((select id from quizzes where topic_code = 'emergency_funds' and quiz_type = 'topic_final_quiz'), 'en', 'Final Quiz: Emergency Funds'),
    ((select id from quizzes where topic_code = 'emergency_funds' and quiz_type = 'topic_final_quiz'), 'kk', 'Қорытынды тест: Төтенше қор')
on conflict (quiz_id, language_code) do update set title = excluded.title;

-- ══════════════════════════════════════════════════════════════
-- QUIZ QUESTIONS
-- ══════════════════════════════════════════════════════════════

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('ef_why_it_matters', 70, '[
        {"lang":"ru","title":"Квиз: Зачем нужен экстренный фонд"},
        {"lang":"en","title":"Quiz: Why You Need an Emergency Fund"},
        {"lang":"kk","title":"Тест: Неге төтенше қор керек"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"У Санем нет экстренного фонда. Её машина сломалась — ремонт 180 000 тенге. Какой из вариантов наиболее вероятно навредит её финансам?"},
          {"lang":"en","text":"Sanem has no emergency fund. Her car broke down — repair costs 180,000 KZT. Which option is most likely to harm her finances?"},
          {"lang":"kk","text":"Санемнің төтенше қоры жоқ. Оның көлігі бұзылды — жөндеу 180 000 теңге. Қандай нұсқа оның қаржысына ең зиян тигізеді?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Попросить деньги у родственников"},
              {"lang":"en","text":"Ask family for money"},
              {"lang":"kk","text":"Туыстарынан ақша сұрау"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Взять потребкредит под 30% — вынуждена платить проценты месяцами"},
              {"lang":"en","text":"Take a consumer loan at 30% — forced to pay interest for months"},
              {"lang":"kk","text":"30%-бен тұтынушылық несие алу — айлар бойы пайыз төлеуге мәжбүр"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Использовать кредитную карту и сразу закрыть в следующем месяце"},
              {"lang":"en","text":"Use a credit card and close it next month"},
              {"lang":"kk","text":"Кредиттік карта пайдаланып, келесі айда жабу"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Продать ненужные вещи"},
              {"lang":"en","text":"Sell things she no longer needs"},
              {"lang":"kk","text":"Қажет емес заттарды сату"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Почему экстренный фонд не стоит хранить в инвестициях (акциях, фондах)?"},
          {"lang":"en","text":"Why should you not keep your emergency fund in investments like stocks or funds?"},
          {"lang":"kk","text":"Неліктен төтенше қорды инвестицияларда (акциялар, қорлар) сақтамау керек?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Там низкая доходность"},
              {"lang":"en","text":"Returns are too low"},
              {"lang":"kk","text":"Кіріс тым төмен"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Рынок может упасть именно тогда, когда деньги срочно нужны"},
              {"lang":"en","text":"The market may be down exactly when you urgently need the money"},
              {"lang":"kk","text":"Ақша кезек күттірмейтін болғанда нарық дәл сол кезде түсіп кетуі мүмкін"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Инвестиции — только для пенсии"},
              {"lang":"en","text":"Investments are only for retirement"},
              {"lang":"kk","text":"Инвестициялар тек зейнетке арналған"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Комиссии слишком высокие"},
              {"lang":"en","text":"Fees are too high"},
              {"lang":"kk","text":"Комиссиялар тым жоғары"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'true_false',
        '[{"lang":"ru","text":"Человек с экстренным фондом может позволить себе держать менее ликвидные инвестиции и не продавать их в панике во время кризиса."},
          {"lang":"en","text":"A person with an emergency fund can afford to hold less liquid investments and avoid panic-selling during a crisis."},
          {"lang":"kk","text":"Төтенше қоры бар адам өтімділігі төмен инвестицияларды ұстай алады және дағдарыс кезінде дүрбелеңмен сата алмайды."}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Верно — фонд создаёт финансовый буфер"},
              {"lang":"en","text":"True — the fund creates a financial buffer"},
              {"lang":"kk","text":"Дұрыс — қор қаржылық буфер жасайды"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Неверно"},{"lang":"en","text":"False"},{"lang":"kk","text":"Дұрыс емес"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только если фонд больше 6 месяцев расходов"},
              {"lang":"en","text":"Only if the fund covers more than 6 months"},
              {"lang":"kk","text":"Тек қор 6 айдан астам шығынды жапса"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Зависит от типа инвестиций"},{"lang":"en","text":"Depends on investment type"},{"lang":"kk","text":"Инвестиция түріне байланысты"}]}]'::jsonb);
end $$;

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('ef_starter_fund', 70, '[
        {"lang":"ru","title":"Квиз: Первые 150 000 тенге"},
        {"lang":"en","title":"Quiz: Building Your First 150,000 KZT"},
        {"lang":"kk","title":"Тест: Алғашқы 150 000 теңге"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Аян хочет создать стартовый экстренный фонд 150 000 тенге. Его чистый доход — 200 000 ₸/мес, расходы — 185 000 ₸. Какая тактика ускорит цель быстрее всего?"},
          {"lang":"en","text":"Ayan wants to build a 150,000 KZT starter emergency fund. Net income: 200,000 ₸/mo, expenses: 185,000 ₸. What tactic gets there fastest?"},
          {"lang":"kk","text":"Аян 150 000 теңге стартер төтенше қор жасағысы келеді. Таза табысы: 200 000 ₸/ай, шығыны: 185 000 ₸. Қандай тактика мақсатқа тезірек жетеді?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Откладывать остаток в конце месяца"},
              {"lang":"en","text":"Save whatever is left at the end of the month"},
              {"lang":"kk","text":"Ай соңында қалдықты жинаңыз"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Автоматически переводить 15 000 ₸ в день зарплаты + разово срезать подписки и кешбэк направить в фонд"},
              {"lang":"en","text":"Auto-transfer 15,000 ₸ on payday + do a one-time audit to cut subscriptions and redirect cashback"},
              {"lang":"kk","text":"Жалақы күні автоматты 15 000 ₸ аудару + бір рет жазылымдарды қысқартып, кэшбэкті қорға бағыттау"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Взять кредит и положить деньги в фонд"},
              {"lang":"en","text":"Take a loan and put the money in the fund"},
              {"lang":"kk","text":"Несие алып, ақшаны қорға салу"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Ждать повышения зарплаты"},
              {"lang":"en","text":"Wait for a raise"},
              {"lang":"kk","text":"Жалақы өскенін күту"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Зачем стартовый экстренный фонд именно 150 000 тенге, а не сразу 3–6 месяцев расходов?"},
          {"lang":"en","text":"Why target 150,000 KZT as a starter fund rather than 3–6 months of expenses straight away?"},
          {"lang":"kk","text":"Неліктен стартер төтенше қор бірден 3–6 айлық шығын емес, дәл 150 000 теңге?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"150 000 — официальный стандарт в Казахстане"},
              {"lang":"en","text":"150,000 is the official standard in Kazakhstan"},
              {"lang":"kk","text":"150 000 — Қазақстандағы ресми стандарт"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Маленькая конкретная цель достигается быстро и создаёт импульс продолжать"},
              {"lang":"en","text":"A small concrete goal is reached quickly and creates momentum to continue"},
              {"lang":"kk","text":"Шағын нақты мақсатқа тез жетіп, жалғастыру үшін серпін жасайды"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Больше нет смысла откладывать"},
              {"lang":"en","text":"There is no point saving beyond that"},
              {"lang":"kk","text":"Одан артық жинаудың мәні жоқ"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"3–6 месяцев слишком много для начинающих"},
              {"lang":"en","text":"3–6 months is too much for beginners"},
              {"lang":"kk","text":"3–6 ай бастаушылар үшін тым көп"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'true_false',
        '[{"lang":"ru","text":"Автоматический перевод сбережений в день зарплаты эффективнее, чем откладывать то, что осталось в конце месяца."},
          {"lang":"en","text":"Automating savings on payday is more effective than saving whatever is left at the end of the month."},
          {"lang":"kk","text":"Жалақы күні жинақты автоматтандыру ай соңында қалғанды жинаудан тиімдірек."}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Верно — принцип «заплати сначала себе» убирает соблазн потратить"},
              {"lang":"en","text":"True — ''pay yourself first'' removes the temptation to spend"},
              {"lang":"kk","text":"Дұрыс — «алдымен өзіңізге төлеңіз» принципі жұмсауға азғырылудан арылтады"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Неверно — оба метода одинаково эффективны"},
              {"lang":"en","text":"False — both methods are equally effective"},
              {"lang":"kk","text":"Дұрыс емес — екі әдіс те бірдей тиімді"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Зависит от размера зарплаты"},{"lang":"en","text":"Depends on salary size"},{"lang":"kk","text":"Жалақы мөлшеріне байланысты"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только при высоком доходе"},{"lang":"en","text":"Only with high income"},{"lang":"kk","text":"Тек жоғары табыспен"}]}]'::jsonb);
end $$;

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('ef_savings_vehicles', 70, '[
        {"lang":"ru","title":"Квиз: Куда положить сбережения"},
        {"lang":"en","title":"Quiz: Where to Keep Your Savings"},
        {"lang":"kk","title":"Тест: Жинақты қайда сақтау"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Где лучше всего хранить экстренный фонд?"},
          {"lang":"en","text":"Where is the best place to keep an emergency fund?"},
          {"lang":"kk","text":"Төтенше қорды қайда сақтаған дұрыс?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"В долгосрочном вкладе без досрочного снятия"},
              {"lang":"en","text":"In a long-term fixed deposit with no early withdrawal"},
              {"lang":"kk","text":"Мерзімінен бұрын шығармайтын ұзақмерзімді депозитте"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"В акциях — высокая доходность"},
              {"lang":"en","text":"In stocks — higher returns"},
              {"lang":"kk","text":"Акцияларда — жоғары кіріс"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"На накопительном счёте или депозите с возможностью снятия — доступность важнее доходности"},
              {"lang":"en","text":"In a savings account or accessible deposit — liquidity beats returns here"},
              {"lang":"kk","text":"Жинақ шотында немесе шығаруға болатын депозитте — қол жетімділік кірістен маңыздырақ"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Наличными дома"},{"lang":"en","text":"Cash at home"},{"lang":"kk","text":"Үйде қолма-қол ақша"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Ставка по накопительному счёту 9%, а инфляция — 11%. Реальная доходность составляет:"},
          {"lang":"en","text":"A savings account pays 9% while inflation is 11%. The real return is:"},
          {"lang":"kk","text":"Жинақ шотының мөлшерлемесі 9%, инфляция — 11%. Нақты кіріс:"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"+9% — банковская ставка"},
              {"lang":"en","text":"+9% — the bank rate"},
              {"lang":"kk","text":"+9% — банктік мөлшерлеме"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"+20% — сумма двух показателей"},
              {"lang":"en","text":"+20% — the sum of both figures"},
              {"lang":"kk","text":"+20% — екі көрсеткіштің қосындысы"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"−2% — покупательная способность снижается"},
              {"lang":"en","text":"−2% — purchasing power is falling"},
              {"lang":"kk","text":"−2% — сатып алу қабілеті азаяды"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"0% — они компенсируют друг друга"},
              {"lang":"en","text":"0% — they cancel each other out"},
              {"lang":"kk","text":"0% — олар бір-бірін өтейді"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'single_choice',
        '[{"lang":"ru","text":"Чем срочный депозит отличается от накопительного счёта применительно к экстренному фонду?"},
          {"lang":"en","text":"How does a term deposit differ from a savings account for emergency fund purposes?"},
          {"lang":"kk","text":"Мерзімді депозит жинақ шотынан төтенше қор тұрғысынан қалай ерекшеленеді?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Депозит всегда выгоднее по доходности"},
              {"lang":"en","text":"Deposits always offer better returns"},
              {"lang":"kk","text":"Депозит әрқашан кіріс бойынша тиімдірек"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Депозит даёт выше ставку, но блокирует деньги — плохо подходит для аварийного фонда"},
              {"lang":"en","text":"Term deposits offer higher rates but lock your money — poor fit for emergency funds"},
              {"lang":"kk","text":"Депозит жоғары мөлшерлеме береді, бірақ ақшаны бұғаттайды — төтенше қорға жарамайды"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Накопительный счёт застрахован, депозит — нет"},
              {"lang":"en","text":"Savings accounts are insured, deposits are not"},
              {"lang":"kk","text":"Жинақ шоты сақтандырылған, депозит — жоқ"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Разницы нет"},{"lang":"en","text":"There is no difference"},{"lang":"kk","text":"Айырмашылық жоқ"}]}]'::jsonb);
end $$;

do $$ declare v bigint; begin
    v := seed_subtopic_quiz('ef_sinking_funds', 70, '[
        {"lang":"ru","title":"Квиз: Целевые фонды"},
        {"lang":"en","title":"Quiz: Sinking Funds"},
        {"lang":"kk","title":"Тест: Мақсатты қорлар"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Что такое целевой фонд (sinking fund)?"},
          {"lang":"en","text":"What is a sinking fund?"},
          {"lang":"kk","text":"Мақсатты қор (sinking fund) дегеніміз не?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Экстренный резерв на непредвиденные расходы"},
              {"lang":"en","text":"Emergency reserve for unexpected costs"},
              {"lang":"kk","text":"Күтпеген шығындарға арналған төтенше резерв"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Ежемесячные накопления под заранее известную будущую трату"},
              {"lang":"en","text":"Monthly savings set aside for a known future expense"},
              {"lang":"kk","text":"Алдын ала белгілі болашақ шығынға арналған ай сайынғы жинақ"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Инвестиционный фонд с фиксированной доходностью"},
              {"lang":"en","text":"Investment fund with fixed returns"},
              {"lang":"kk","text":"Тіркелген кірісі бар инвестициялық қор"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Задолженность перед государством"},
              {"lang":"en","text":"A government liability"},
              {"lang":"kk","text":"Мемлекет алдындағы қарыз"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Дина хочет поехать в отпуск через 8 месяцев. Бюджет — 320 000 тенге. Сколько нужно откладывать ежемесячно?"},
          {"lang":"en","text":"Dina wants to go on holiday in 8 months. Budget: 320,000 KZT. How much should she save per month?"},
          {"lang":"kk","text":"Дина 8 айдан кейін демалысқа баруды жоспарлайды. Бюджеті — 320 000 теңге. Ай сайын қанша жинау керек?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"50 000 ₸"},{"lang":"en","text":"50,000 ₸"},{"lang":"kk","text":"50 000 ₸"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"40 000 ₸ (320 000 ÷ 8)"},{"lang":"en","text":"40,000 ₸ (320,000 ÷ 8)"},{"lang":"kk","text":"40 000 ₸ (320 000 ÷ 8)"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"320 000 ₸ — всё сразу"},{"lang":"en","text":"320,000 ₸ all at once"},{"lang":"kk","text":"320 000 ₸ — бірден бәрін"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"25 000 ₸"},{"lang":"en","text":"25,000 ₸"},{"lang":"kk","text":"25 000 ₸"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'true_false',
        '[{"lang":"ru","text":"Целевые фонды и экстренный фонд — это одно и то же, просто для разных целей."},
          {"lang":"en","text":"Sinking funds and the emergency fund are the same thing, just for different goals."},
          {"lang":"kk","text":"Мақсатты қорлар мен төтенше қор — бұл бірдей нәрсе, тек әртүрлі мақсаттар үшін."}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Верно — они взаимозаменяемы"},
              {"lang":"en","text":"True — they are interchangeable"},
              {"lang":"kk","text":"Дұрыс — олар бір-бірін алмастыра алады"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Неверно — экстренный фонд для непредвиденного, целевые — для запланированного"},
              {"lang":"en","text":"False — emergency fund covers the unexpected; sinking funds cover the planned"},
              {"lang":"kk","text":"Дұрыс емес — төтенше қор күтпегенге, мақсатты қорлар жоспарланғанға арналған"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Зависит от банка"},{"lang":"en","text":"Depends on the bank"},{"lang":"kk","text":"Банкке байланысты"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только при наличии бюджета"},{"lang":"en","text":"Only if you have a budget"},{"lang":"kk","text":"Тек бюджет болса"}]}]'::jsonb);
end $$;

-- ══════════════════════════════════════════════════════════════
-- LESSON STEPS
-- ══════════════════════════════════════════════════════════════

begin;

-- ── ef_why_it_matters ─────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 1), 'ru', 'Кризис или неудобство', '{"blocks":[{"type":"paragraph","text":"Машина ломается. Телефон падает в унитаз. Работодатель задерживает зарплату. Зуб. Трубу прорвало."},{"type":"paragraph","text":"Для человека с экстренным фондом это неудобство. Для человека без него — финансовый кризис. Разница — в заранее отложенных деньгах."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 1), 'en', 'Crisis or Inconvenience', '{"blocks":[{"type":"paragraph","text":"The car breaks down. The phone falls in the toilet. The employer delays the paycheck. A tooth. A burst pipe."},{"type":"paragraph","text":"For someone with an emergency fund, this is an inconvenience. For someone without one, it is a financial crisis. The difference is money set aside in advance."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 1), 'kk', 'Дағдарыс па, ыңғайсыздық па', '{"blocks":[{"type":"paragraph","text":"Көлік бұзылады. Телефон дәретханаға түседі. Жұмыс беруші жалақыны кешіктіреді. Тіс. Труба жарылды."},{"type":"paragraph","text":"Төтенше қоры бар адам үшін бұл ыңғайсыздық. Онсыз — қаржылық дағдарыс. Айырмашылығы — алдын ала жинаған ақшада."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 2), 'ru', 'Сколько, где и почему',
     '{"blocks":[{"type":"paragraph","text":"Стандартная рекомендация — 3–6 месяцев обязательных расходов. Не дохода — расходов. Только то, без чего вы не можете: жильё, еда, транспорт, обязательные платежи."},{"type":"table","headers":["Ситуация","Рекомендуемый размер"],"rows":[["Стабильная работа, пара в семье","3 месяца"],["Один источник дохода","4–5 месяцев"],["Фриланс / нестабильный доход","6 месяцев"],["Дети или иждивенцы","6 месяцев"]]},{"type":"paragraph","text":"Где хранить: накопительный счёт или депозит с возможностью быстрого снятия. Не в акциях (могут упасть когда они нужны), не наличными дома (инфляция + риск кражи), не на карте (слишком легко потратить)."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 2), 'en', 'How Much, Where, and Why',
     '{"blocks":[{"type":"paragraph","text":"The standard recommendation: 3–6 months of essential expenses. Not income — expenses. Only what you cannot live without: housing, food, transport, fixed obligations."},{"type":"table","headers":["Situation","Recommended size"],"rows":[["Stable job, dual income household","3 months"],["Single income source","4–5 months"],["Freelance / variable income","6 months"],["Dependents or children","6 months"]]},{"type":"paragraph","text":"Where to keep it: a savings account or accessible deposit. Not in stocks (may fall exactly when needed), not cash at home (inflation + theft risk), not on your everyday card (too easy to spend)."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 2), 'kk', 'Қанша, қайда және неге',
     '{"blocks":[{"type":"paragraph","text":"Стандарт ұсыныс — міндетті шығынның 3–6 айы. Табыс емес — шығын. Тек онсыз өмір сүре алмайтыныңыз: тұрғын үй, тамақ, көлік, міндетті төлемдер."},{"type":"table","headers":["Жағдай","Ұсынылатын мөлшер"],"rows":[["Тұрақты жұмыс, жұптық табыс","3 ай"],["Жалғыз табыс көзі","4–5 ай"],["Фриланс / тұрақсыз табыс","6 ай"],["Балалар немесе асырауындағылар","6 ай"]]},{"type":"paragraph","text":"Қайда сақтау: жинақ шоты немесе жылдам шығаруға болатын депозит. Акцияларда емес (қажет кезде түсіп кетуі мүмкін), үйде қолма-қол ақша емес (инфляция + ұрлану тәуекелі), күнделікті картада емес (жұмсауға тым оңай)."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 3), 'ru', 'Скрытая суперсила фонда',
     '{"blocks":[{"type":"paragraph","text":"Экстренный фонд не просто защищает от кризисов. Он меняет всю вашу инвестиционную стратегию."},{"type":"paragraph","text":"2020 год. Рынок упал на 30%. Два инвестора с одинаковыми портфелями:"},{"type":"bullet_list","items":["Инвестор А без фонда: потерял работу, продал акции на дне в панике, зафиксировал убыток −30%.","Инвестор Б с фондом на 6 месяцев: жил на резерв, не продал ничего, через 18 месяцев портфель вырос на +20% от исходной точки."]},{"type":"paragraph","text":"Фонд — это не просто деньги на чёрный день. Это разрешение не паниковать."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 3), 'en', 'The Hidden Superpower',
     '{"blocks":[{"type":"paragraph","text":"The emergency fund does not just protect against crises. It changes your entire investment strategy."},{"type":"paragraph","text":"Year 2020. The market dropped 30%. Two investors with identical portfolios:"},{"type":"bullet_list","items":["Investor A with no fund: lost job, panic-sold stocks at the bottom, locked in a −30% loss.","Investor B with 6 months of reserves: lived on the buffer, sold nothing, and 18 months later was up +20% from the starting point."]},{"type":"paragraph","text":"The fund is not just money for a rainy day. It is permission not to panic."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 3), 'kk', 'Жасырын суперкүш',
     '{"blocks":[{"type":"paragraph","text":"Төтенше қор тек дағдарыстардан қорғамайды. Ол сіздің барлық инвестициялық стратегияңызды өзгертеді."},{"type":"paragraph","text":"2020 жыл. Нарық 30%-ға түсті. Бірдей портфельі бар екі инвестор:"},{"type":"bullet_list","items":["А инвесторы қорсыз: жұмысынан айрылды, акцияларды дүрбелеңмен төменгі нүктеде сатты, −30% шығынды тіркеді.","Б инвесторы 6 ай резервімен: резервте өмір сүрді, ештеңе сатпады, 18 айдан кейін портфель бастапқы нүктеден +20%-ға өсті."]},{"type":"paragraph","text":"Қор — тек қара күнге арналған ақша емес. Бұл — дүрбелеңге берілмеуге рұқсат."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Экстренный фонд — это фундамент. Всё остальное строится поверх него. Без него любая инвестиция, любой кредитный план уязвим. С ним вы можете позволить себе терпение."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"The emergency fund is the foundation. Everything else is built on top of it. Without it, any investment plan or debt strategy is fragile. With it, you can afford to be patient."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_why_it_matters' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"Төтенше қор — негіз. Барлығы оның үстіне салынады. Онсыз кез келген инвестиция немесе несиелік жоспар осал. Оны иеленген кезде сіз шыдамды бола аласыз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── ef_starter_fund ───────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 1), 'ru', 'Не 6 месяцев. Сначала 150 000', '{"blocks":[{"type":"paragraph","text":"«Накопить 3–6 месяцев расходов» звучит правильно, но огромно. Для человека с доходом 200 000 тенге это 400–600 тысяч — непосильная цель."},{"type":"paragraph","text":"Поэтому начните с малого, но конкретного. 150 000 тенге. Один маленький фонд достаточен, чтобы пережить большинство бытовых кризисов и не залезть в долги."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 1), 'en', 'Not 6 Months. Start with 150,000', '{"blocks":[{"type":"paragraph","text":"''Save 3–6 months of expenses'' sounds right but feels enormous. For someone earning 200,000 KZT, that is 400–600K — an overwhelming target."},{"type":"paragraph","text":"So start small but specific. 150,000 KZT. One small fund is enough to survive most everyday crises without going into debt."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 1), 'kk', '6 ай емес. Алдымен 150 000', '{"blocks":[{"type":"paragraph","text":"«3–6 ай шығынын жинаңыз» дұрыс естіледі, бірақ өте үлкен. 200 000 теңге табатын адам үшін бұл 400–600 мың — орындалмайтын мақсат."},{"type":"paragraph","text":"Сондықтан кішіден, бірақ нақтыдан бастаңыз. 150 000 теңге. Бір шағын қор қарызға кірмей көптеген тұрмыстық дағдарыстарды жеңуге жеткілікті."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 2), 'ru', 'Три рычага',
     '{"blocks":[{"type":"paragraph","text":"Чтобы создать стартовый фонд быстрее, используйте все три рычага одновременно, а не только один:"},{"type":"table","headers":["Рычаг","Пример действия","Ежемесячный эффект"],"rows":[["Автоматизировать","Перевод 15 000 ₸ в день зарплаты","Убирает соблазн потратить"],["Срезать","Отписаться от 3 неиспользуемых сервисов","3 000–8 000 ₸/мес"],["Разово пополнить","Кешбэк, продажа вещей, подработка","20 000–50 000 единовременно"]]},{"type":"paragraph","text":"При 15 000/мес + 30 000 разово: 150 000 достигается за 8 месяцев. При 25 000/мес + 30 000 разово: за 5 месяцев."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 2), 'en', 'Three Levers',
     '{"blocks":[{"type":"paragraph","text":"To build a starter fund faster, pull all three levers at once, not just one:"},{"type":"table","headers":["Lever","Example action","Monthly impact"],"rows":[["Automate","Transfer 15,000 ₸ on payday","Removes temptation to spend"],["Cut","Cancel 3 unused subscriptions","3,000–8,000 ₸/mo"],["One-time boost","Cashback, selling stuff, side gig","20,000–50,000 ₸ one-off"]]},{"type":"paragraph","text":"At 15,000/mo + 30,000 one-off: you reach 150,000 in 8 months. At 25,000/mo + 30,000 one-off: 5 months."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 2), 'kk', 'Үш тетік',
     '{"blocks":[{"type":"paragraph","text":"Стартер қорды тезірек жасақтау үшін тек бір емес, үш тетікті бір мезгілде пайдаланыңыз:"},{"type":"table","headers":["Тетік","Мысал әрекет","Айлық әсер"],"rows":[["Автоматтандыру","Жалақы күні 15 000 ₸ аудару","Жұмсауға азғырылуды жояды"],["Қысқарту","3 пайдаланылмаған жазылымнан бас тарту","3 000–8 000 ₸/ай"],["Бір реттік толықтыру","Кэшбэк, заттарды сату, қосымша жұмыс","20 000–50 000 ₸ бір рет"]]},{"type":"paragraph","text":"Айына 15 000 + 30 000 бір рет: 150 000-ға 8 айда жетесіз. Айына 25 000 + 30 000 бір рет: 5 айда."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 3), 'ru', 'Аян: тесная зарплата, работающий план',
     '{"blocks":[{"type":"paragraph","text":"Аян зарабатывает 200 000 ₸, тратит 185 000 ₸. Свободно — 15 000 в месяц."},{"type":"bullet_list","items":["Автоматический перевод: 15 000 в день зарплаты на отдельный счёт.","Аудит подписок: отписался от трёх сервисов (+5 000/мес).","Продал старый велосипед на Колёсах: 35 000 ₸ единовременно.","Пересмотрел тариф мобильного: −2 000/мес."]},{"type":"paragraph","text":"Итого: 22 000/мес + 35 000 стартовый взнос. 150 000 достигнуты за 5 месяцев вместо 10."},{"type":"paragraph","text":"После достижения цели: увеличил ежемесячный перевод до 25 000 — теперь копит на полный фонд (390 000)."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 3), 'en', 'Ayan: Tight Budget, Working Plan',
     '{"blocks":[{"type":"paragraph","text":"Ayan earns 200,000 ₸ and spends 185,000 ₸. Free cash: 15,000 per month."},{"type":"bullet_list","items":["Automated transfer: 15,000 on payday to a separate account.","Subscription audit: cancelled three services (+5,000/mo).","Sold old bicycle on a classifieds app: 35,000 ₸ one-off.","Switched mobile plan: −2,000/mo."]},{"type":"paragraph","text":"Result: 22,000/mo + 35,000 opening deposit. Hit 150,000 in 5 months instead of 10."},{"type":"paragraph","text":"After hitting the goal: raised the monthly transfer to 25,000 — now building toward the full fund (390,000)."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 3), 'kk', 'Аян: Шағын бюджет, жұмысшы жоспар',
     '{"blocks":[{"type":"paragraph","text":"Аян 200 000 ₸ табады, 185 000 ₸ жұмсайды. Бос ақша: айына 15 000."},{"type":"bullet_list","items":["Автоматты аудару: жалақы күні жеке шотқа 15 000.","Жазылымдарды тексеру: үш сервистен бас тартты (+5 000/ай).","Ескі велосипедін хабарландырулар сайтынан сатты: 35 000 ₸ бір рет.","Мобильді тарифті ауыстырды: −2 000/ай."]},{"type":"paragraph","text":"Нәтиже: айына 22 000 + 35 000 бастапқы жарна. 150 000-ға 10 емес, 5 айда жетті."},{"type":"paragraph","text":"Мақсатқа жеткеннен кейін: айлық аударымды 25 000-ға дейін арттырды — енді толық қор (390 000) жинайды."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Начните с 150 000. Автоматизируйте перевод в день зарплаты. Когда цель выполнена — поднимите планку до полных 3–6 месяцев. Маленькая победа создаёт импульс для большой."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"Start with 150,000. Automate the transfer on payday. When that target is hit, raise the bar to the full 3–6 months. A small win creates momentum for the bigger one."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_starter_fund' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"150 000-нан бастаңыз. Жалақы күні аударымды автоматтандырыңыз. Мақсатқа жеткен соң, 3–6 айға дейін деңгейді көтеріңіз. Шағын жеңіс үлкен жеңіске серпін береді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── ef_savings_vehicles ───────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 1), 'ru', 'Не только «куда», но и «зачем туда»', '{"blocks":[{"type":"paragraph","text":"Деньги лежат по-разному — и выбор места влияет на доходность, доступность и безопасность. Для сбережений это важнее, чем кажется."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 1), 'en', 'Not Just Where — But Why There', '{"blocks":[{"type":"paragraph","text":"Money can sit in many places — and the choice affects returns, accessibility, and safety. For savings, this matters more than it seems."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 1), 'kk', 'Тек «қайда» емес, «неге сонда»', '{"blocks":[{"type":"paragraph","text":"Ақша әртүрлі жерде жатуы мүмкін — және орын таңдауы кіріске, қол жетімділікке және қауіпсіздікке әсер етеді. Жинақтар үшін бұл ойлағаннан да маңызды."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 2), 'ru', 'Три инструмента для сбережений',
     '{"blocks":[{"type":"table","headers":["Инструмент","Доступность","Доходность","Лучше всего для"],"rows":[["Накопительный счёт","Мгновенно","Низкая–средняя","Экстренный фонд"],["Срочный депозит","Только в конце срока","Средняя–высокая","Цели 6–24 мес"],["Депозит с частичным снятием","Частично, с потерей %","Средняя","Гибридный фонд"]]},{"type":"paragraph","text":"Реальная доходность = ставка − инфляция. Если ставка 9%, а инфляция 11% — вы теряете 2% покупательной способности ежегодно. Цель накопительного счёта — не заработать, а сохранить и обогнать инфляцию."},{"type":"paragraph","text":"Страхование вкладов: проверьте, застрахованы ли деньги в вашем банке и на какую сумму (в Казахстане — КФГД)."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 2), 'en', 'Three Savings Instruments',
     '{"blocks":[{"type":"table","headers":["Instrument","Access","Return","Best for"],"rows":[["Savings account","Instant","Low–medium","Emergency fund"],["Term deposit","End of term only","Medium–high","Goals 6–24 months out"],["Partial-withdrawal deposit","Partial (lose some interest)","Medium","Hybrid fund"]]},{"type":"paragraph","text":"Real return = rate − inflation. If the rate is 9% and inflation is 11%, you are losing 2% of purchasing power per year. The goal of a savings account is not to earn — it is to preserve and beat inflation."},{"type":"paragraph","text":"Deposit insurance: check whether your bank is covered and for how much (in Kazakhstan — KDIF)."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 2), 'kk', 'Жинаққа арналған үш құрал',
     '{"blocks":[{"type":"table","headers":["Құрал","Қол жетімділік","Кіріс","Не үшін жақсы"],"rows":[["Жинақ шоты","Лезде","Төмен–орташа","Төтенше қор"],["Мерзімді депозит","Тек мерзім соңында","Орташа–жоғары","6–24 айлық мақсаттар"],["Ішінара шығаратын депозит","Ішінара (пайыз жоғалады)","Орташа","Гибридті қор"]]},{"type":"paragraph","text":"Нақты кіріс = мөлшерлеме − инфляция. Мөлшерлеме 9%, инфляция 11% болса — жыл сайын сатып алу қабілетінің 2%-ын жоғалтасыз. Жинақ шотының мақсаты — табыс табу емес, сақтау және инфляциядан озу."},{"type":"paragraph","text":"Депозиттерді сақтандыру: сіздің банкіңіз сақтандырылған ба және қандай сомаға дейін екенін тексеріңіз (Қазақстанда — ҚДФКК)."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 3), 'ru', 'Стратегия двух ведер',
     '{"blocks":[{"type":"paragraph","text":"Практичный способ организовать сбережения — разделить на два «ведра»:"},{"type":"bullet_list","items":["Ведро 1 — Экстренный фонд (3–6 мес расходов): накопительный счёт. Всегда доступен. Ставка ниже — неважно, это не инвестиция.","Ведро 2 — Цели (отпуск, машина, ремонт): срочный депозит или депозит с частичным снятием. Выше ставка, горизонт 6–18 месяцев."]},{"type":"paragraph","text":"Оба ведра — в другом банке, а не там, где зарплатная карта. Это устраняет соблазн. Перевод занимает 1–2 дня — достаточно быстро для реального кризиса, достаточно медленно для спонтанных покупок."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 3), 'en', 'The Two-Bucket Strategy',
     '{"blocks":[{"type":"paragraph","text":"A practical way to organize savings: split into two buckets."},{"type":"bullet_list","items":["Bucket 1 — Emergency Fund (3–6 months expenses): savings account. Always accessible. Lower rate — does not matter, this is not an investment.","Bucket 2 — Goals (holiday, car, home): term deposit or partial-withdrawal deposit. Higher rate, 6–18 month horizon."]},{"type":"paragraph","text":"Keep both at a different bank from your salary account. This removes temptation. Transfers take 1–2 days — fast enough for a real crisis, slow enough to stop impulse spending."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 3), 'kk', 'Екі шелек стратегиясы',
     '{"blocks":[{"type":"paragraph","text":"Жинақты ұйымдастырудың практикалық жолы — екі «шелекке» бөлу:"},{"type":"bullet_list","items":["1-шелек — Төтенше қор (3–6 ай шығыны): жинақ шоты. Әрқашан қол жетімді. Мөлшерлемесі төмен — маңызды емес, бұл инвестиция емес.","2-шелек — Мақсаттар (демалыс, көлік, жөндеу): мерзімді депозит немесе ішінара шығаратын депозит. Жоғары мөлшерлеме, 6–18 айлық көкжиек."]},{"type":"paragraph","text":"Екі шелекті де жалақы картаңыз бар банктен өзге банкте ұстаңыз. Бұл азғырылуды жояды. Аударым 1–2 күн — нақты дағдарысқа жеткілікті жылдам, ал кенеттен сатып алуды тоқтатуға жеткілікті баяу."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Для экстренного фонда — доступность важнее доходности. Для целей — наоборот. Два разных инструмента, две разные задачи. Держите их раздельно."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"For the emergency fund — liquidity beats returns. For goals — the opposite. Two different tools, two different jobs. Keep them separate."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_savings_vehicles' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"Төтенше қор үшін — қол жетімділік кірістен маңыздырақ. Мақсаттар үшін — керісінше. Екі түрлі құрал, екі түрлі міндет. Оларды бөлек ұстаңыз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── ef_sinking_funds ──────────────────────────────────────────

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 1), 'ru', 'Расходы которые нельзя не предвидеть', '{"blocks":[{"type":"paragraph","text":"День рождения друга — не сюрприз. Техосмотр машины — не сюрприз. Новый учебный год — не сюрприз. Но большинство людей «вдруг» тратят на них деньги из текущего бюджета — и каждый раз это бьёт по плану."},{"type":"paragraph","text":"Целевые фонды решают именно эту проблему."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 1), 'en', 'Expenses You Cannot Call Unexpected', '{"blocks":[{"type":"paragraph","text":"A friend''s birthday is not a surprise. Annual car service is not a surprise. The new school year is not a surprise. But most people ''suddenly'' spend money on these from their monthly budget — and every time, the plan takes a hit."},{"type":"paragraph","text":"Sinking funds solve exactly this problem."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 1), 'kk', 'Болжай алатын шығындар', '{"blocks":[{"type":"paragraph","text":"Достың туған күні — тосын жағдай емес. Жылдық автокөлік техникалық тексерісі — тосын жағдай емес. Жаңа оқу жылы — тосын жағдай емес. Бірақ адамдардың көпшілігі ай бюджетінен «кенеттен» осыларға жұмсайды — және ол жоспарды бұзады."},{"type":"paragraph","text":"Мақсатты қорлар дәл осы мәселені шешеді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 2), 'ru', 'Как работают целевые фонды',
     '{"blocks":[{"type":"paragraph","text":"Принцип прост: возьмите известный будущий расход, разделите на месяцы до него, откладывайте эту сумму каждый месяц."},{"type":"table","headers":["Цель","Сумма","Горизонт","В месяц"],"rows":[["Отпуск","320 000 ₸","8 мес","40 000 ₸"],["Страховка авто","80 000 ₸","12 мес","6 700 ₸"],["Новогодние подарки","60 000 ₸","6 мес","10 000 ₸"],["ТО машины","45 000 ₸","9 мес","5 000 ₸"]]},{"type":"paragraph","text":"Эти фонды — не экстренный резерв. Деньги придут и уйдут по плану. Их задача — убрать крупные расходы из ежемесячного бюджета и прекратить цикл «вдруг потратил»."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 2), 'en', 'How Sinking Funds Work',
     '{"blocks":[{"type":"paragraph","text":"The principle is simple: take a known future expense, divide it by the months until it arrives, save that amount each month."},{"type":"table","headers":["Goal","Amount","Horizon","Per month"],"rows":[["Holiday","320,000 ₸","8 months","40,000 ₸"],["Car insurance","80,000 ₸","12 months","6,700 ₸"],["New Year gifts","60,000 ₸","6 months","10,000 ₸"],["Annual car service","45,000 ₸","9 months","5,000 ₸"]]},{"type":"paragraph","text":"These are not emergency reserves. The money comes in and goes out on schedule. Their job is to remove large expenses from the monthly budget and end the cycle of ''suddenly spent it''."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 2), 'kk', 'Мақсатты қорлар қалай жұмыс істейді',
     '{"blocks":[{"type":"paragraph","text":"Принцип қарапайым: белгілі болашақ шығынды алыңыз, оған дейінгі айларға бөліңіз, ай сайын сол соманы жинаңыз."},{"type":"table","headers":["Мақсат","Сома","Көкжиек","Айына"],"rows":[["Демалыс","320 000 ₸","8 ай","40 000 ₸"],["Авто сақтандыру","80 000 ₸","12 ай","6 700 ₸"],["Жаңа жыл сыйлықтары","60 000 ₸","6 ай","10 000 ₸"],["Жылдық ТО","45 000 ₸","9 ай","5 000 ₸"]]},{"type":"paragraph","text":"Бұл қорлар — төтенше резерв емес. Ақша кестемен келіп, кетеді. Олардың міндеті — ірі шығындарды ай бюджетінен алып тастау және «кенеттен жұмсадым» циклін тоқтату."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 3), 'ru', 'Дина: бюджет без «чёрных лебедей»',
     '{"blocks":[{"type":"paragraph","text":"Раньше у Дины каждый декабрь был финансовый стресс из-за подарков, праздников, страховки. В январе — долг по карте."},{"type":"paragraph","text":"Теперь она ведёт 4 целевых фонда общим взносом 61 700 ₸/мес:"},{"type":"bullet_list","items":["Отпуск (август): 40 000/мес","Страховка (январь): 6 700/мес","Подарки (декабрь): 10 000/мес","ТО (март): 5 000/мес"]},{"type":"paragraph","text":"Декабрь наступил. Дина открыла «фонд подарков» — там 60 000 ₸. Купила всё что нужно, не взяла ни одного кредита, не тронула экстренный резерв. Январь начался без долгов."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 3), 'en', 'Dina: Budget Without Black Swans',
     '{"blocks":[{"type":"paragraph","text":"Dina used to face financial stress every December — gifts, holidays, insurance renewal. January always started with credit card debt."},{"type":"paragraph","text":"Now she runs 4 sinking funds with a total monthly contribution of 61,700 ₸:"},{"type":"bullet_list","items":["Holiday (August): 40,000/mo","Car insurance (January): 6,700/mo","Gifts (December): 10,000/mo","Annual service (March): 5,000/mo"]},{"type":"paragraph","text":"December came. Dina opened her ''gifts fund'' — 60,000 ₸ was sitting there. She bought everything she needed, took no credit, did not touch the emergency reserve. January started debt-free."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 3), 'kk', 'Дина: «Қара аққусыз» бюджет',
     '{"blocks":[{"type":"paragraph","text":"Бұрын Дина әр желтоқсанда қаржылық стресс көретін — сыйлықтар, мерекелер, сақтандыру жаңарту. Қаңтар әрқашан кредиттік карта қарызымен басталатын."},{"type":"paragraph","text":"Енді ол айлық жалпы жарнасы 61 700 ₸ болатын 4 мақсатты қор жүргізеді:"},{"type":"bullet_list","items":["Демалыс (тамыз): 40 000/ай","Авто сақтандыру (қаңтар): 6 700/ай","Сыйлықтар (желтоқсан): 10 000/ай","ТО (наурыз): 5 000/ай"]},{"type":"paragraph","text":"Желтоқсан келді. Дина «сыйлықтар қорын» ашты — онда 60 000 ₸ бар. Қажет нәрсенің бәрін сатып алды, бірде-бір несие алмады, төтенше резервке тимеді. Қаңтар қарызсыз басталды."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;
insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 4), 'ru', 'Главное', '{"blocks":[{"type":"paragraph","text":"Запишите три крупных расхода, которые ждут вас в следующие 12 месяцев. Разделите каждый на месяцы. Начните откладывать. Это превращает предсказуемое «неожиданное» в плановое."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 4), 'en', 'Key Takeaway', '{"blocks":[{"type":"paragraph","text":"Write down three large expenses coming in the next 12 months. Divide each by the months until they arrive. Start saving. This turns the predictably ''unexpected'' into planned."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'ef_sinking_funds' and ls.order_index = 4), 'kk', 'Негізгі қорытынды', '{"blocks":[{"type":"paragraph","text":"Алдағы 12 айда сізді күтіп тұрған үш ірі шығынды жазыңыз. Әрқайсысын оған дейінгі айларға бөліңіз. Жинауды бастаңыз. Бұл болжанатын «күтпеген» нәрсені жоспарлыға айналдырады."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

commit;