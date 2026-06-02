-- ══════════════════════════════════════════════════════════════
-- TOPIC 02: money_and_banking
-- Part 1 | Track A | Level: beginner
-- 4 subtopics | ~17 min total
-- ══════════════════════════════════════════════════════════════

-- ── TOPIC ─────────────────────────────────────────────────────
insert into topics (code, level, order_index, is_active) values
    ('money_and_banking', 'beginner', 5, true)
on conflict (code) do update set
    level = excluded.level, order_index = excluded.order_index,
    is_active = excluded.is_active, updated_at = now();

insert into topic_translations (topic_id, language_code, title, description) values
    ((select id from topics where code = 'money_and_banking'), 'ru', 'Деньги и банки',        'Как работают деньги и банковская система вокруг вас'),
    ((select id from topics where code = 'money_and_banking'), 'en', 'Money & Banking',        'How money and the banking system around you actually work'),
    ((select id from topics where code = 'money_and_banking'), 'kk', 'Ақша және банктер',     'Ақша және сіздің айналаңыздағы банк жүйесі қалай жұмыс істейді')
on conflict (topic_id, language_code) do update set title = excluded.title, description = excluded.description;

-- ── SUBTOPICS ─────────────────────────────────────────────────
insert into subtopics (topic_id, code, order_index, estimated_minutes, is_active) values
    ((select id from topics where code = 'money_and_banking'), 'mb_what_is_money',    1, 3, true),
    ((select id from topics where code = 'money_and_banking'), 'mb_account_types',    2, 4, true),
    ((select id from topics where code = 'money_and_banking'), 'mb_how_banks_earn',   3, 5, true),
    ((select id from topics where code = 'money_and_banking'), 'mb_deposit_insurance',4, 5, true)
on conflict (code) do update set
    order_index = excluded.order_index, estimated_minutes = excluded.estimated_minutes,
    is_active = excluded.is_active, updated_at = now();

insert into subtopic_translations (subtopic_id, language_code, title) values
    ((select id from subtopics where code = 'mb_what_is_money'),     'ru', 'Что такое деньги'),
    ((select id from subtopics where code = 'mb_account_types'),     'ru', 'Виды банковских счетов'),
    ((select id from subtopics where code = 'mb_how_banks_earn'),    'ru', 'Как банки зарабатывают'),
    ((select id from subtopics where code = 'mb_deposit_insurance'), 'ru', 'Страхование вкладов'),
    ((select id from subtopics where code = 'mb_what_is_money'),     'en', 'What Is Money'),
    ((select id from subtopics where code = 'mb_account_types'),     'en', 'Bank Account Types'),
    ((select id from subtopics where code = 'mb_how_banks_earn'),    'en', 'How Banks Make Money'),
    ((select id from subtopics where code = 'mb_deposit_insurance'), 'en', 'Deposit Insurance'),
    ((select id from subtopics where code = 'mb_what_is_money'),     'kk', 'Ақша дегеніміз не'),
    ((select id from subtopics where code = 'mb_account_types'),     'kk', 'Банк шоттарының түрлері'),
    ((select id from subtopics where code = 'mb_how_banks_earn'),    'kk', 'Банктер қалай табыс табады'),
    ((select id from subtopics where code = 'mb_deposit_insurance'), 'kk', 'Салымдарды сақтандыру')
on conflict (subtopic_id, language_code) do update set title = excluded.title;

-- ── LESSON SHELLS ─────────────────────────────────────────────
insert into lessons (subtopic_id, is_published)
select id, true from subtopics
where code in ('mb_what_is_money','mb_account_types','mb_how_banks_earn','mb_deposit_insurance')
on conflict (subtopic_id) do update set is_published = excluded.is_published;

-- ── TOPIC FINAL QUIZ ──────────────────────────────────────────
insert into quizzes (subtopic_code, topic_code, quiz_type, passing_score, is_active) values
    (null, 'money_and_banking', 'topic_final_quiz', 75, true)
on conflict (topic_code) where quiz_type = 'topic_final_quiz' do update set
    passing_score = excluded.passing_score, is_active = excluded.is_active, updated_at = now();

insert into quiz_translations (quiz_id, language_code, title) values
    ((select id from quizzes where topic_code = 'money_and_banking' and quiz_type = 'topic_final_quiz'), 'ru', 'Итоговый квиз: Деньги и банки'),
    ((select id from quizzes where topic_code = 'money_and_banking' and quiz_type = 'topic_final_quiz'), 'en', 'Final Quiz: Money & Banking'),
    ((select id from quizzes where topic_code = 'money_and_banking' and quiz_type = 'topic_final_quiz'), 'kk', 'Қорытынды тест: Ақша және банктер')
on conflict (quiz_id, language_code) do update set title = excluded.title;

-- ══════════════════════════════════════════════════════════════
-- QUIZ QUESTIONS
-- ══════════════════════════════════════════════════════════════

-- ── mb_what_is_money ──────────────────────────────────────────
do $$ declare v bigint; begin
    v := seed_subtopic_quiz('mb_what_is_money', 70, '[
        {"lang":"ru","title":"Квиз: Что такое деньги"},
        {"lang":"en","title":"Quiz: What Is Money"},
        {"lang":"kk","title":"Тест: Ақша дегеніміз не"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Какую из функций деньги НЕ выполняют?"},
          {"lang":"en","text":"Which of the following is NOT a function of money?"},
          {"lang":"kk","text":"Төмендегілердің қайсысы ақшаның қызметі ЕМЕС?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Средство обмена"},{"lang":"en","text":"Medium of exchange"},{"lang":"kk","text":"Айырбас құралы"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Мера стоимости"},{"lang":"en","text":"Unit of account"},{"lang":"kk","text":"Құн өлшемі"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Средство сбережения"},{"lang":"en","text":"Store of value"},{"lang":"kk","text":"Жинақтау құралы"}]},
          {"order_index":4,"is_correct":true,"translations":[
              {"lang":"ru","text":"Источник дохода сам по себе"},{"lang":"en","text":"A source of income by itself"},{"lang":"kk","text":"Өздігінен табыс көзі"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'true_false',
        '[{"lang":"ru","text":"Фиатные деньги обеспечены физическим золотом, хранящимся в центральном банке."},
          {"lang":"en","text":"Fiat money is backed by physical gold stored in the central bank."},
          {"lang":"kk","text":"Фиаттық ақша орталық банкте сақталған физикалық алтынмен қамтамасыз етілген."}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Верно"},{"lang":"en","text":"True"},{"lang":"kk","text":"Дұрыс"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Неверно — фиатные деньги обеспечены доверием к государству"},{"lang":"en","text":"False — fiat money is backed by government trust, not gold"},{"lang":"kk","text":"Дұрыс емес — фиаттық ақша алтынмен емес, мемлекетке деген сенімімен қамтамасыз етілген"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только в Казахстане"},{"lang":"en","text":"Only in Kazakhstan"},{"lang":"kk","text":"Тек Қазақстанда ғана"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только частично"},{"lang":"en","text":"Only partially"},{"lang":"kk","text":"Тек ішінара"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'single_choice',
        '[{"lang":"ru","text":"Инфляция означает, что со временем на одну и ту же сумму можно купить:"},
          {"lang":"en","text":"Inflation means that over time, the same amount of money buys:"},
          {"lang":"kk","text":"Инфляция дегеніміз — уақыт өте келе бір сома ақшаға:"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Больше товаров"},{"lang":"en","text":"More goods"},{"lang":"kk","text":"Көбірек тауар сатып алуға болады"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Меньше товаров"},{"lang":"en","text":"Fewer goods"},{"lang":"kk","text":"Азырақ тауар сатып алуға болады"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Столько же товаров"},{"lang":"en","text":"The same amount of goods"},{"lang":"kk","text":"Сондай-ақ тауар сатып алуға болады"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Это зависит от банка"},{"lang":"en","text":"It depends on the bank"},{"lang":"kk","text":"Бұл банкке байланысты"}]}]'::jsonb);
end $$;

-- ── mb_account_types ──────────────────────────────────────────
do $$ declare v bigint; begin
    v := seed_subtopic_quiz('mb_account_types', 70, '[
        {"lang":"ru","title":"Квиз: Виды счетов"},
        {"lang":"en","title":"Quiz: Account Types"},
        {"lang":"kk","title":"Тест: Шот түрлері"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Бибигуль хочет хранить экстренный фонд так, чтобы деньги были доступны в любой момент, но зарабатывали больше, чем на текущем счёте. Что ей подойдёт лучше всего?"},
          {"lang":"en","text":"Bibigul wants to keep her emergency fund accessible at any time but earning more than a checking account. What fits best?"},
          {"lang":"kk","text":"Бибігүл төтенше қорын кез келген уақытта қолжетімді ұстағысы келеді, бірақ ағымдағы шоттан көбірек пайда тапсын. Не сәйкес келеді?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Текущий (расчётный) счёт"},{"lang":"en","text":"Checking account"},{"lang":"kk","text":"Ағымдағы шот"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Накопительный счёт (сберегательный)"},{"lang":"en","text":"High-yield savings account"},{"lang":"kk","text":"Жинақ шоты"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Срочный депозит"},{"lang":"en","text":"Fixed-term deposit"},{"lang":"kk","text":"Мерзімді депозит"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Брокерский счёт"},{"lang":"en","text":"Brokerage account"},{"lang":"kk","text":"Брокерлік шот"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Ерлан открыл депозит под 12% годовых на 1 год. Через 6 месяцев ему срочно понадобились деньги. Что скорее всего произойдёт при досрочном снятии?"},
          {"lang":"en","text":"Erlan opened a 12% annual deposit for 1 year. After 6 months he urgently needs the money. What most likely happens if he withdraws early?"},
          {"lang":"kk","text":"Ерлан 1 жылға 12% жылдық депозит ашты. 6 айдан кейін оған шұғыл ақша қажет болды. Мерзімінен бұрын алса не болады?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Он получит полные 12% за 6 месяцев"},{"lang":"en","text":"He gets the full 12% for 6 months"},{"lang":"kk","text":"Ол 6 айға толық 12% алады"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Он потеряет часть или все начисленные проценты"},{"lang":"en","text":"He loses some or all of the accrued interest"},{"lang":"kk","text":"Ол есептелген сыйақының бір бөлігін немесе барлығын жоғалтады"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Ничего не произойдёт — депозит гибкий"},{"lang":"en","text":"Nothing happens — deposits are always flexible"},{"lang":"kk","text":"Ештеңе болмайды — депозит икемді"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Банк заблокирует счёт"},{"lang":"en","text":"The bank will freeze his account"},{"lang":"kk","text":"Банк шотты блоктайды"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'multiple_choice',
        '[{"lang":"ru","text":"Какие из этих счетов лучше всего подходят для ежедневных расходов и платежей? (выберите все верные)"},
          {"lang":"en","text":"Which of these accounts are best suited for daily spending and payments? (select all that apply)"},
          {"lang":"kk","text":"Осы шоттардың қайсысы күнделікті шығындар мен төлемдерге жақсы сәйкес келеді? (барлық дұрысты белгілеңіз)"}]'::jsonb,
        '[{"order_index":1,"is_correct":true,"translations":[
              {"lang":"ru","text":"Текущий (расчётный) счёт"},{"lang":"en","text":"Checking account"},{"lang":"kk","text":"Ағымдағы шот"}]},
          {"order_index":2,"is_correct":false,"translations":[
              {"lang":"ru","text":"Срочный депозит на 2 года"},{"lang":"en","text":"2-year fixed deposit"},{"lang":"kk","text":"2 жылдық мерзімді депозит"}]},
          {"order_index":3,"is_correct":true,"translations":[
              {"lang":"ru","text":"Карточный счёт с дебетовой картой"},{"lang":"en","text":"Debit card account"},{"lang":"kk","text":"Дебеттік картасы бар карт-шот"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Инвестиционный счёт в ценных бумагах"},{"lang":"en","text":"Securities investment account"},{"lang":"kk","text":"Бағалы қағаздарға инвестициялық шот"}]}]'::jsonb);
end $$;

-- ── mb_how_banks_earn ─────────────────────────────────────────
do $$ declare v bigint; begin
    v := seed_subtopic_quiz('mb_how_banks_earn', 70, '[
        {"lang":"ru","title":"Квиз: Как банки зарабатывают"},
        {"lang":"en","title":"Quiz: How Banks Make Money"},
        {"lang":"kk","title":"Тест: Банктер қалай табыс табады"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"Банк принимает депозиты под 9% годовых и выдаёт кредиты под 18%. На чём основана прибыль банка?"},
          {"lang":"en","text":"A bank pays 9% on deposits and charges 18% on loans. What is the bank profiting from?"},
          {"lang":"kk","text":"Банк депозиттерге 9% төлейді және несиелерге 18% алады. Банктің пайдасы неден?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Комиссии за обслуживание карт"},{"lang":"en","text":"Card service fees"},{"lang":"kk","text":"Карт қызмет көрсету комиссиялары"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Процентная маржа — разница между ставкой по кредиту и депозиту"},{"lang":"en","text":"Interest spread — the difference between loan and deposit rates"},{"lang":"kk","text":"Пайыздық маржа — несие мен депозит мөлшерлемесінің айырмашылығы"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Покупка иностранной валюты"},{"lang":"en","text":"Foreign currency purchases"},{"lang":"kk","text":"Шетел валютасын сатып алу"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Государственные субсидии"},{"lang":"en","text":"Government subsidies"},{"lang":"kk","text":"Мемлекеттік субсидиялар"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'true_false',
        '[{"lang":"ru","text":"Банк хранит в хранилище 100% средств, которые вкладчики положили на депозиты."},
          {"lang":"en","text":"A bank keeps 100% of deposited funds in its vault at all times."},
          {"lang":"kk","text":"Банк салымшылар салған қаражаттың 100%-ын сейфте ұстайды."}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Верно"},{"lang":"en","text":"True"},{"lang":"kk","text":"Дұрыс"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Неверно — банки выдают большую часть депозитов в виде кредитов"},{"lang":"en","text":"False — banks lend out most deposits, keeping only a fraction in reserve"},{"lang":"kk","text":"Дұрыс емес — банктер депозиттердің басым бөлігін несие ретінде береді"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только государственные банки"},{"lang":"en","text":"Only state-owned banks"},{"lang":"kk","text":"Тек мемлекеттік банктер"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только в Казахстане"},{"lang":"en","text":"Only in Kazakhstan"},{"lang":"kk","text":"Тек Қазақстанда"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'single_choice',
        '[{"lang":"ru","text":"Какое из утверждений объясняет, почему выгоднее хранить деньги на накопительном счёте, а не на текущем?"},
          {"lang":"en","text":"Which statement explains why keeping money in a savings account beats a checking account?"},
          {"lang":"kk","text":"Қай тұжырым ақшаны ағымдағы шотта емес жинақ шотында ұстаудың тиімдірек екенін түсіндіреді?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Текущий счёт застрахован, а накопительный — нет"},{"lang":"en","text":"Checking accounts are insured, savings are not"},{"lang":"kk","text":"Ағымдағы шот сақтандырылған, жинақ шоты сақтандырылмаған"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Накопительный счёт начисляет проценты на остаток, текущий — обычно нет"},{"lang":"en","text":"Savings accounts earn interest on the balance; checking accounts usually do not"},{"lang":"kk","text":"Жинақ шоты қалдыққа пайыз есептейді, ағымдағы шот әдетте есептемейді"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"С накопительного счёта нельзя снять деньги"},{"lang":"en","text":"You cannot withdraw from a savings account"},{"lang":"kk","text":"Жинақ шотынан ақша алуға болмайды"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Текущий счёт имеет более высокую ставку"},{"lang":"en","text":"Checking accounts have higher interest rates"},{"lang":"kk","text":"Ағымдағы шоттың мөлшерлемесі жоғарырақ"}]}]'::jsonb);
end $$;

-- ── mb_deposit_insurance ──────────────────────────────────────
do $$ declare v bigint; begin
    v := seed_subtopic_quiz('mb_deposit_insurance', 70, '[
        {"lang":"ru","title":"Квиз: Страхование вкладов"},
        {"lang":"en","title":"Quiz: Deposit Insurance"},
        {"lang":"kk","title":"Тест: Салымдарды сақтандыру"}]'::jsonb);

    perform seed_quiz_question(v, 1, 'single_choice',
        '[{"lang":"ru","text":"В Казахстане вклады физических лиц застрахованы через:"},
          {"lang":"en","text":"In Kazakhstan, individual deposits are insured through:"},
          {"lang":"kk","text":"Қазақстанда жеке тұлғалардың салымдары қай ұйым арқылы сақтандырылады?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Национальный банк Казахстана"},{"lang":"en","text":"The National Bank of Kazakhstan"},{"lang":"kk","text":"Қазақстан Ұлттық банкі"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Казахстанский фонд гарантирования депозитов (КФГД)"},{"lang":"en","text":"Kazakhstan Deposit Guarantee Fund (KDGF)"},{"lang":"kk","text":"Қазақстанның депозиттерге кепілдік беру қоры (ҚДКҚ)"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Министерство финансов"},{"lang":"en","text":"Ministry of Finance"},{"lang":"kk","text":"Қаржы министрлігі"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Сам банк-кредитор"},{"lang":"en","text":"The bank itself"},{"lang":"kk","text":"Банктің өзі"}]}]'::jsonb);

    perform seed_quiz_question(v, 2, 'single_choice',
        '[{"lang":"ru","text":"Нурия держит в одном банке 25 000 000 тенге. Банк лишился лицензии. Лимит страхования — 20 000 000 тенге. Сколько она гарантированно вернёт?"},
          {"lang":"en","text":"Nuria holds 25,000,000 KZT in one bank. The bank loses its licence. The insurance limit is 20,000,000 KZT. How much is she guaranteed to get back?"},
          {"lang":"kk","text":"Нурия бір банкте 25 000 000 теңге ұстайды. Банк лицензиясынан айырылды. Сақтандыру шегі — 20 000 000 теңге. Ол қанша теңгені кепілді түрде қайтарып алады?"}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"25 000 000 тенге — страховка покрывает всё"},{"lang":"en","text":"25,000,000 KZT — insurance covers everything"},{"lang":"kk","text":"25 000 000 теңге — сақтандыру барлығын жабады"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"20 000 000 тенге — остальные 5 000 000 не застрахованы"},{"lang":"en","text":"20,000,000 KZT — the remaining 5,000,000 is not covered"},{"lang":"kk","text":"20 000 000 теңге — қалған 5 000 000 сақтандырылмаған"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Ничего — страховка не распространяется на крупные вклады"},{"lang":"en","text":"Nothing — insurance does not apply to large deposits"},{"lang":"kk","text":"Ештеңе — сақтандыру ірі салымдарға қолданылмайды"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только половину — 12 500 000 тенге"},{"lang":"en","text":"Only half — 12,500,000 KZT"},{"lang":"kk","text":"Тек жартысы — 12 500 000 теңге"}]}]'::jsonb);

    perform seed_quiz_question(v, 3, 'true_false',
        '[{"lang":"ru","text":"Инвестиции в акции и облигации, купленные через брокера, застрахованы так же, как банковские вклады."},
          {"lang":"en","text":"Investments in stocks and bonds purchased through a broker are insured the same way as bank deposits."},
          {"lang":"kk","text":"Брокер арқылы сатып алынған акциялар мен облигацияларға салынған инвестициялар банк салымдарымен бірдей сақтандырылады."}]'::jsonb,
        '[{"order_index":1,"is_correct":false,"translations":[
              {"lang":"ru","text":"Верно"},{"lang":"en","text":"True"},{"lang":"kk","text":"Дұрыс"}]},
          {"order_index":2,"is_correct":true,"translations":[
              {"lang":"ru","text":"Неверно — инвестиции не застрахованы государством, они несут рыночный риск"},{"lang":"en","text":"False — investments are not government-insured; they carry market risk"},{"lang":"kk","text":"Дұрыс емес — инвестициялар мемлекет тарапынан сақтандырылмаған, олар нарықтық тәуекел алып жүреді"}]},
          {"order_index":3,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только государственные облигации"},{"lang":"en","text":"Only government bonds"},{"lang":"kk","text":"Тек мемлекеттік облигациялар"}]},
          {"order_index":4,"is_correct":false,"translations":[
              {"lang":"ru","text":"Только если сумма меньше лимита"},{"lang":"en","text":"Only if the amount is below the limit"},{"lang":"kk","text":"Тек сома шектен аз болса ғана"}]}]'::jsonb);
end $$;

-- ══════════════════════════════════════════════════════════════
-- LESSON STEPS
-- ══════════════════════════════════════════════════════════════
begin;

-- ── mb_what_is_money ──────────────────────────────────────────
insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 1), 'ru', 'Введение',
     '{"blocks":[{"type":"paragraph","text":"Деньги окружают нас каждый день, но мало кто задумывается, что они собой представляют. Понимание природы денег меняет то, как вы ими пользуетесь."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 1), 'en', 'Introduction',
     '{"blocks":[{"type":"paragraph","text":"Money surrounds us every day, yet few people think about what it actually is. Understanding the nature of money changes how you use it."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 1), 'kk', 'Кіріспе',
     '{"blocks":[{"type":"paragraph","text":"Ақша бізді күн сайын қоршап алған, бірақ оның шынымен не екенін аз адам ойлайды. Ақшаның табиғатын түсіну оны қолдану тәсіліңізді өзгертеді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 2), 'ru', 'Три функции денег',
     '{"blocks":[{"type":"paragraph","text":"Деньги выполняют три функции:"},{"type":"bullet_list","items":["Средство обмена — вместо того чтобы менять хлеб на молоко, вы платите деньгами. Упрощает торговлю.","Мера стоимости — единый язык цен. Благодаря ему вы можете сравнивать стоимость совершенно разных вещей.","Средство сбережения — деньги сохраняют ценность со временем, хотя инфляция постепенно её снижает."]},{"type":"paragraph","text":"Современные деньги — фиатные. Они не обеспечены золотом. Их ценность держится на доверии к государству и центральному банку."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 2), 'en', 'Three Functions of Money',
     '{"blocks":[{"type":"paragraph","text":"Money serves three functions:"},{"type":"bullet_list","items":["Medium of exchange — instead of bartering bread for milk, you pay money. Simplifies all trade.","Unit of account — a common language of prices. It lets you compare the value of completely different things.","Store of value — money holds value over time, though inflation gradually erodes it."]},{"type":"paragraph","text":"Modern money is fiat money. It is not backed by gold. Its value rests on trust in the government and central bank."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 2), 'kk', 'Ақшаның үш қызметі',
     '{"blocks":[{"type":"paragraph","text":"Ақша үш қызмет атқарады:"},{"type":"bullet_list","items":["Айырбас құралы — нанды сүтке айырбастаудың орнына ақша төлейсіз. Саудаласуды жеңілдетеді.","Құн өлшемі — бағаның ортақ тілі. Ол мүлдем басқа заттардың құнын салыстыруға мүмкіндік береді.","Жинақтау құралы — ақша уақыт өте өзінің құнын сақтайды, дегенмен инфляция оны біртіндеп төмендетеді."]},{"type":"paragraph","text":"Заманауи ақша — фиаттық ақша. Ол алтынмен қамтамасыз етілмеген. Оның құны мемлекет пен орталық банкке деген сенімге негізделген."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 3), 'ru', 'Инфляция в жизни',
     '{"blocks":[{"type":"paragraph","text":"В 2014 году на 1000 тенге в Алматы можно было купить продуктов на весь обед. В 2024 году той же суммы едва хватит на пару позиций. Деньги те же. Количество товаров — меньше."},{"type":"paragraph","text":"Именно поэтому держать все сбережения наличными невыгодно: каждый год без работающих инвестиций вы теряете часть покупательной способности."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 3), 'en', 'Inflation in Real Life',
     '{"blocks":[{"type":"paragraph","text":"In 2014, 1,000 KZT could buy a full lunch in Almaty. In 2024, the same amount barely covers a couple of items. Same money. Far fewer goods."},{"type":"paragraph","text":"This is why holding all savings in cash is costly: every year without working investments, you quietly lose purchasing power."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 3), 'kk', 'Инфляция өмірде',
     '{"blocks":[{"type":"paragraph","text":"2014 жылы Алматыда 1000 теңгеге толық түскі ас сатып алуға болатын. 2024 жылы сол сомаға бірнеше тауар ғана жетеді. Ақша сол. Тауар мөлшері — азайды."},{"type":"paragraph","text":"Сондықтан барлық жинақты қолма-қол ақшада ұстау тиімсіз: инвестициясыз өткен әр жылда сіз сатып алу қабілетіңіздің бір бөлігін үнсіз жоғалтасыз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 4), 'ru', 'Главное',
     '{"blocks":[{"type":"paragraph","text":"Деньги — инструмент с тремя функциями. Фиатные деньги держатся на доверии. Инфляция означает, что бездействующие деньги постепенно дешевеют."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 4), 'en', 'Key Takeaway',
     '{"blocks":[{"type":"paragraph","text":"Money is a tool with three functions. Fiat money runs on trust. Inflation means idle money quietly loses value every year."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_what_is_money' and ls.order_index = 4), 'kk', 'Негізгі қорытынды',
     '{"blocks":[{"type":"paragraph","text":"Ақша — үш қызметі бар құрал. Фиаттық ақша сенімге негізделген. Инфляция жатып қалған ақшаның жыл сайын құнын азайтатынын білдіреді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── mb_account_types ──────────────────────────────────────────
insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 1), 'ru', 'Введение',
     '{"blocks":[{"type":"paragraph","text":"Не все банковские счета одинаковы. Правильный выбор счёта под конкретную задачу напрямую влияет на то, сколько вы зарабатываете на своих деньгах."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 1), 'en', 'Introduction',
     '{"blocks":[{"type":"paragraph","text":"Not all bank accounts are the same. Choosing the right account for the right job directly affects how much your money earns."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 1), 'kk', 'Кіріспе',
     '{"blocks":[{"type":"paragraph","text":"Барлық банктік шоттар бірдей емес. Нақты міндетке сәйкес шотты дұрыс таңдау ақшаңыздың қанша табыс табатынына тікелей әсер етеді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 2), 'ru', 'Типы счетов',
     '{"blocks":[{"type":"table","headers":["Тип счёта","Для чего","Доходность","Доступность"],"rows":[["Текущий (расчётный)","Ежедневные платежи, зарплата","Почти нет","Мгновенно"],["Накопительный","Экстренный фонд, короткий горизонт","Умеренная (выше текущего)","Обычно 1–3 дня"],["Срочный депозит","Деньги, которые не нужны X месяцев","Высокая (фиксированная)","Нельзя без потери процентов"],["Карточный счёт","Расчёты картой","Почти нет","Мгновенно"]]}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 2), 'en', 'Account Types',
     '{"blocks":[{"type":"table","headers":["Account type","Best for","Returns","Access"],"rows":[["Checking","Daily payments, salary","Almost none","Instant"],["Savings / HYSA","Emergency fund, short horizon","Moderate (beats checking)","Usually 1–3 days"],["Fixed deposit","Money not needed for X months","High (locked rate)","Early exit loses interest"],["Debit card account","Card payments","Almost none","Instant"]]}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 2), 'kk', 'Шот түрлері',
     '{"blocks":[{"type":"table","headers":["Шот түрі","Не үшін","Кірістілік","Қолжетімділік"],"rows":[["Ағымдағы","Күнделікті төлемдер, жалақы","Мүлдем аз","Лезде"],["Жинақ шоты","Төтенше қор, қысқа мерзім","Орташа (ағымдағыдан жоғары)","Әдетте 1–3 күн"],["Мерзімді депозит","X ай бойы қажет емес ақша","Жоғары (бекітілген)","Пайызсыз мерзімінен бұрын алу мүмкін емес"],["Карт-шот","Картамен есеп айырысу","Мүлдем аз","Лезде"]]}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 3), 'ru', 'Пример: три кошелька',
     '{"blocks":[{"type":"paragraph","text":"Дания делит деньги на три роли:"},{"type":"bullet_list","items":["Текущий счёт — зарплата, аренда, продукты. Всё, что нужно прямо сейчас.","Накопительный счёт — экстренный фонд в 390 000 ₸. Неприкосновенен, но доступен за 1–2 дня.","Депозит на 12 месяцев — деньги на первоначальный взнос за квартиру. Знает, что они не понадобятся раньше."]},{"type":"paragraph","text":"Каждый тенге знает свою роль. Это и есть эффективное управление счетами."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 3), 'en', 'Example: Three Buckets',
     '{"blocks":[{"type":"paragraph","text":"Daniya splits her money into three roles:"},{"type":"bullet_list","items":["Checking account — salary, rent, groceries. Everything needed right now.","Savings account — her 390,000 KZT emergency fund. Untouched, but reachable in 1–2 days.","12-month deposit — down payment savings. She knows she will not need them before then."]},{"type":"paragraph","text":"Every tenge knows its job. That is effective account management."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 3), 'kk', 'Мысал: үш себет',
     '{"blocks":[{"type":"paragraph","text":"Дания ақшасын үш рөлге бөледі:"},{"type":"bullet_list","items":["Ағымдағы шот — жалақы, жалдау, азық-түлік. Қазір қажет нәрселердің барлығы.","Жинақ шоты — 390 000 ₸ төтенше қоры. Қол тигізілмейді, бірақ 1–2 күнде қолжетімді.","12 айлық депозит — пәтер бастапқы жарнасына жинақ. Ол мерзімінен бұрын қажет болмайтынын біледі."]},{"type":"paragraph","text":"Әр теңге өз рөлін біледі. Бұл — тиімді шот басқарушылығы."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 4), 'ru', 'Главное',
     '{"blocks":[{"type":"paragraph","text":"Текущий счёт — для расходов. Накопительный — для экстренного фонда. Депозит — для денег с конкретным сроком. Не смешивайте роли."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 4), 'en', 'Key Takeaway',
     '{"blocks":[{"type":"paragraph","text":"Checking for spending. Savings for the emergency fund. Fixed deposit for money with a deadline. Do not mix the roles."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_account_types' and ls.order_index = 4), 'kk', 'Негізгі қорытынды',
     '{"blocks":[{"type":"paragraph","text":"Ағымдағы шот — шығындарға. Жинақ — төтенше қорға. Депозит — мерзімі бар ақшаға. Рөлдерді араластырмаңыз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── mb_how_banks_earn ─────────────────────────────────────────
insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 1), 'ru', 'Введение',
     '{"blocks":[{"type":"paragraph","text":"Банк — не благотворительность. Он предоставляет услуги и зарабатывает на этом. Понимая бизнес-модель банка, вы лучше видите, когда банк работает на вас, а когда — на себя."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 1), 'en', 'Introduction',
     '{"blocks":[{"type":"paragraph","text":"A bank is not a charity. It provides services and earns money doing it. Understanding the bank business model helps you see when the bank works for you — and when it works for itself."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 1), 'kk', 'Кіріспе',
     '{"blocks":[{"type":"paragraph","text":"Банк — қайырымдылық ұйымы емес. Ол қызмет көрсетеді және осыдан табыс табады. Банктің бизнес-моделін түсіну банктің сіз үшін қашан жұмыс істейтінін, ал өзі үшін — қашан жұмыс істейтінін анықтауға мүмкіндік береді."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 2), 'ru', 'Три источника дохода банка',
     '{"blocks":[{"type":"bullet_list","items":["Процентная маржа — банк берёт депозиты под 9% и выдаёт кредиты под 18%. Разница в 9% — его основной доход.","Комиссии и сборы — обслуживание карты, переводы, SMS-уведомления, штрафы за просрочку.","Дополнительные услуги — страховки, брокерские счета, валютный обмен."]},{"type":"paragraph","text":"Главный вывод: банк зарабатывает, когда вы берёте кредиты и платите комиссии. Ваша задача — минимизировать и то, и другое там, где это возможно."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 2), 'en', 'Three Revenue Sources',
     '{"blocks":[{"type":"bullet_list","items":["Interest spread — bank takes deposits at 9% and lends at 18%. The 9% difference is its main revenue.","Fees and charges — card maintenance, transfers, SMS alerts, late payment penalties.","Ancillary services — insurance products, brokerage, currency exchange."]},{"type":"paragraph","text":"Key insight: the bank earns when you borrow and pay fees. Your goal is to minimise both wherever possible."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 2), 'kk', 'Банктің үш табыс көзі',
     '{"blocks":[{"type":"bullet_list","items":["Пайыздық маржа — банк депозиттерді 9%-пен қабылдайды да, несиелерді 18%-пен береді. 9%-дық айырма — оның негізгі табысы.","Комиссиялар мен алымдар — карт қызметі, аударымдар, SMS-хабарламалар, мерзімі өткен төлемдер үшін айыппұлдар.","Қосымша қызметтер — сақтандыру өнімдері, брокерлік, валюта айырбасы."]},{"type":"paragraph","text":"Негізгі тұжырым: банк несие алып, комиссия төлегенде табыс табады. Сіздің мақсатыңыз — мүмкін болса осылардың екеуін де азайту."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 3), 'ru', 'Пример: скрытые комиссии',
     '{"blocks":[{"type":"paragraph","text":"Серик открыл «бесплатную» карту. За год он заплатил:"},{"type":"table","headers":["Статья","Сумма"],"rows":[["SMS-уведомления (12 мес × 300 ₸)","3 600 ₸"],["Межбанковский перевод × 4","1 200 ₸"],["Просрочка платежа × 1","3 000 ₸"],["Итого «бесплатная» карта","7 800 ₸"]]},{"type":"paragraph","text":"Карта бесплатна. Поведение — нет. Читайте тарифы и отключайте то, что не используете."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 3), 'en', 'Example: Hidden Fees',
     '{"blocks":[{"type":"paragraph","text":"Serik opened a ''free'' card. Over a year he paid:"},{"type":"table","headers":["Item","Amount"],"rows":[["SMS alerts (12 mo × 300 ₸)","3,600 ₸"],["Inter-bank transfers × 4","1,200 ₸"],["Late payment penalty × 1","3,000 ₸"],["Total for ''free'' card","7,800 ₸"]]},{"type":"paragraph","text":"The card is free. The behaviour is not. Read the fee schedule and disable what you do not use."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 3), 'kk', 'Мысал: жасырын комиссиялар',
     '{"blocks":[{"type":"paragraph","text":"Серік «тегін» карт ашты. Бір жыл ішінде ол төледі:"},{"type":"table","headers":["Баптама","Сома"],"rows":[["SMS-хабарламалар (12 ай × 300 ₸)","3 600 ₸"],["Банкаралық аударым × 4","1 200 ₸"],["Мерзімі өткен төлем айыппұлы × 1","3 000 ₸"],["«Тегін» карттың жалпы сомасы","7 800 ₸"]]},{"type":"paragraph","text":"Карт тегін. Мінез-құлық — тегін емес. Тарифтерді оқыңыз және пайдаланбайтын нәрселерді өшіріңіз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 4), 'ru', 'Главное',
     '{"blocks":[{"type":"paragraph","text":"Банки зарабатывают на марже и комиссиях. Понимая это, вы выбираете продукты осознанно и не кормите банк там, где можно не кормить."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 4), 'en', 'Key Takeaway',
     '{"blocks":[{"type":"paragraph","text":"Banks earn on spread and fees. Understanding this lets you choose products deliberately and avoid feeding the bank where you do not have to."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_how_banks_earn' and ls.order_index = 4), 'kk', 'Негізгі қорытынды',
     '{"blocks":[{"type":"paragraph","text":"Банктер маржа мен комиссиядан табыс табады. Мұны түсіне отырып, өнімдерді саналы таңдайсыз және мүмкін болған жерде банкті «тамақтандырмайсыз»."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

-- ── mb_deposit_insurance ──────────────────────────────────────
insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance'), 'introduction', 1)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 1), 'ru', 'Введение',
     '{"blocks":[{"type":"paragraph","text":"Банки иногда банкротятся. Страхование вкладов — это защитная сетка, которая позволяет не терять сон из-за денег на депозите."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 1), 'en', 'Introduction',
     '{"blocks":[{"type":"paragraph","text":"Banks sometimes fail. Deposit insurance is the safety net that means you do not have to lose sleep over money in a bank account."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 1), 'kk', 'Кіріспе',
     '{"blocks":[{"type":"paragraph","text":"Банктер кейде банкротқа ұшырайды. Салымдарды сақтандыру — банктік шоттағы ақшаға уайымдамауға мүмкіндік беретін қауіпсіздік торы."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance'), 'explanation', 2)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 2), 'ru', 'Как работает КФГД',
     '{"blocks":[{"type":"paragraph","text":"В Казахстане вклады физических лиц застрахованы через Казахстанский фонд гарантирования депозитов (КФГД). Все банки с лицензией обязаны участвовать."},{"type":"bullet_list","items":["Тенговые вклады: до 20 000 000 ₸ на человека в одном банке","Валютные вклады: до 5 000 000 ₸-эквивалента","Вклады ИП и МСБ: до 20 000 000 ₸"]},{"type":"paragraph","text":"Что НЕ застраховано: инвестиции в акции, облигации, паевые фонды, брокерские счета — всё, что несёт рыночный риск."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 2), 'en', 'How Deposit Insurance Works',
     '{"blocks":[{"type":"paragraph","text":"In Kazakhstan, individual deposits are protected by the Kazakhstan Deposit Guarantee Fund (KDGF). All licensed banks are required to participate."},{"type":"bullet_list","items":["KZT deposits: up to 20,000,000 ₸ per person per bank","Foreign currency deposits: up to 5,000,000 ₸ equivalent","SME / sole trader deposits: up to 20,000,000 ₸"]},{"type":"paragraph","text":"What is NOT covered: investments in stocks, bonds, mutual funds, brokerage accounts — anything carrying market risk."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 2), 'kk', 'ҚДКҚ қалай жұмыс істейді',
     '{"blocks":[{"type":"paragraph","text":"Қазақстанда жеке тұлғалардың салымдары Қазақстанның депозиттерге кепілдік беру қоры (ҚДКҚ) арқылы қорғалады. Лицензиясы бар барлық банктер қатысуға міндетті."},{"type":"bullet_list","items":["Теңгелік салымдар: бір банктегі бір адамға 20 000 000 ₸ дейін","Шетел валютасындағы салымдар: 5 000 000 ₸-эквивалентке дейін","ЖК және ШОБ салымдары: 20 000 000 ₸ дейін"]},{"type":"paragraph","text":"Не сақтандырылмайды: акциялар, облигациялар, үлестік қорлар, брокерлік шоттар — нарықтық тәуекел алып жүретін барлық нәрсе."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance'), 'example', 3)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 3), 'ru', 'Пример: больше лимита',
     '{"blocks":[{"type":"paragraph","text":"У Нурии 25 000 000 тенге в одном банке. Банк теряет лицензию."},{"type":"table","headers":["","Сумма"],"rows":[["Вклад","25 000 000 ₸"],["Лимит КФГД","20 000 000 ₸"],["Гарантированный возврат","20 000 000 ₸"],["Под риском","5 000 000 ₸"]]},{"type":"paragraph","text":"Решение: если сумма превышает лимит, распределите её по двум-трём надёжным банкам. Каждый вклад застрахован отдельно."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 3), 'en', 'Example: Above the Limit',
     '{"blocks":[{"type":"paragraph","text":"Nuria has 25,000,000 KZT in one bank. The bank loses its licence."},{"type":"table","headers":["","Amount"],"rows":[["Deposit","25,000,000 ₸"],["KDGF limit","20,000,000 ₸"],["Guaranteed return","20,000,000 ₸"],["At risk","5,000,000 ₸"]]},{"type":"paragraph","text":"Solution: if your amount exceeds the limit, spread it across two or three solid banks. Each deposit is insured separately."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 3), 'kk', 'Мысал: шектен асқанда',
     '{"blocks":[{"type":"paragraph","text":"Нурияның бір банкте 25 000 000 теңгесі бар. Банк лицензиясынан айырылды."},{"type":"table","headers":["","Сома"],"rows":[["Салым","25 000 000 ₸"],["ҚДКҚ шегі","20 000 000 ₸"],["Кепілді қайтару","20 000 000 ₸"],["Тәуекелде","5 000 000 ₸"]]},{"type":"paragraph","text":"Шешім: сома шектен асса, оны екі-үш сенімді банкке бөліп орналастырыңыз. Әр салым жеке сақтандырылады."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

insert into lesson_steps (lesson_id, step_type, order_index)
values ((select l.id from lessons l join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance'), 'conclusion', 4)
on conflict (lesson_id, order_index) do update set step_type = excluded.step_type, interactive_type = excluded.interactive_type;

insert into lesson_step_translations (lesson_step_id, language_code, title, content) values
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 4), 'ru', 'Главное',
     '{"blocks":[{"type":"paragraph","text":"Вклады в казахстанских банках застрахованы КФГД до 20 млн тенге. Инвестиции — нет. Суммы выше лимита — распределяйте по банкам."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 4), 'en', 'Key Takeaway',
     '{"blocks":[{"type":"paragraph","text":"Deposits in Kazakh banks are insured by the KDGF up to 20M KZT. Investments are not. Amounts above the limit — split across banks."}]}'::jsonb),
    ((select ls.id from lesson_steps ls join lessons l on l.id = ls.lesson_id join subtopics s on s.id = l.subtopic_id where s.code = 'mb_deposit_insurance' and ls.order_index = 4), 'kk', 'Негізгі қорытынды',
     '{"blocks":[{"type":"paragraph","text":"Қазақстандық банктердегі салымдар ҚДКҚ арқылы 20 млн теңгеге дейін сақтандырылады. Инвестициялар — жоқ. Шектен асатын сомаларды банктерге бөліп орналастырыңыз."}]}'::jsonb)
on conflict (lesson_step_id, language_code) do update set title = excluded.title, content = excluded.content, interactive_content = excluded.interactive_content;

commit;