-- ══════════════════════════════════════════════════════════════
-- 000 — SECTIONS (runs before all topic seeds)
-- 8 sections | codes match Curriculum_Section_Grouped_v3.md
-- icon paths to be filled in later
-- ══════════════════════════════════════════════════════════════

insert into sections (code, order_index, icon) values
    ('financial_foundations',   1, 'assets/financial_foundations.png'),
    ('banking_payments',        2, 'assets/banking_payments.png'),
    ('budgeting_saving_debt',   3, 'assets/budgeting_saving_debt.png'),
    ('insurance_protection',    4, 'assets/insurance_protection.png'),
    ('investing_basics',        5, 'assets/investing_basics.png'),
    ('investment_types',        6, 'assets/investment_types.png'),
    ('funds_accounts_markets',  7, 'assets/funds_accounts_markets.png'),
    ('building_wealth',         8, 'assets/building_wealth.png')
on conflict (code) do update set
    order_index = excluded.order_index,
    updated_at  = now();

insert into section_translations (section_id, language_code, title, description) values
    -- Section 1: Think & Foundations
    ((select id from sections where code = 'financial_foundations'), 'ru',
     'Основы мышления',
     'Сначала научитесь мыслить — потом продукты'),
    ((select id from sections where code = 'financial_foundations'), 'en',
     'Think & Foundations',
     'Learn to think before learning products'),
    ((select id from sections where code = 'financial_foundations'), 'kk',
     'Ойлау негіздері',
     'Алдымен ойлауды үйреніңіз — кейін өнімдерді'),
    -- Section 2: Money & Banking
    ((select id from sections where code = 'banking_payments'), 'ru',
     'Деньги и банки',
     'Система, которая хранит и двигает ваши деньги'),
    ((select id from sections where code = 'banking_payments'), 'en',
     'Money & Banking',
     'The system that holds and moves your money'),
    ((select id from sections where code = 'banking_payments'), 'kk',
     'Ақша және банктер',
     'Ақшаңызды сақтайтын және жылжытатын жүйе'),
    -- Section 3: Control Your Money
    ((select id from sections where code = 'budgeting_saving_debt'), 'ru',
     'Контроль денег',
     'Превратите доход в стабильность'),
    ((select id from sections where code = 'budgeting_saving_debt'), 'en',
     'Control Your Money',
     'Turn income into stability'),
    ((select id from sections where code = 'budgeting_saving_debt'), 'kk',
     'Ақшаны бақылау',
     'Табысты тұрақтылыққа айналдырыңыз'),
    -- Section 4: Protect Yourself
    ((select id from sections where code = 'insurance_protection'), 'ru',
     'Защита',
     'Страхование и финансовая безопасность'),
    ((select id from sections where code = 'insurance_protection'), 'en',
     'Protect Yourself',
     'Insurance and financial safety'),
    ((select id from sections where code = 'insurance_protection'), 'kk',
     'Өзіңізді қорғаңыз',
     'Сақтандыру және қаржылық қауіпсіздік'),
    -- Section 5: Investing Foundations
    ((select id from sections where code = 'investing_basics'), 'ru',
     'Основы инвестиций',
     'Зачем инвестировать — риск, доход, издержки'),
    ((select id from sections where code = 'investing_basics'), 'en',
     'Investing Foundations',
     'Why invest — risk, return, costs'),
    ((select id from sections where code = 'investing_basics'), 'kk',
     'Инвестиция негіздері',
     'Неге инвестициялау — тәуекел, табыс, шығын'),
    -- Section 6: Asset Classes
    ((select id from sections where code = 'investment_types'), 'ru',
     'Классы активов',
     'Акции, облигации, недвижимость, крипта'),
    ((select id from sections where code = 'investment_types'), 'en',
     'Asset Classes',
     'Stocks, bonds, real estate, crypto'),
    ((select id from sections where code = 'investment_types'), 'kk',
     'Актив кластерлері',
     'Акциялар, облигациялар, жылжымайтын мүлік, крипто'),
    -- Section 7: Vehicles & Markets
    ((select id from sections where code = 'funds_accounts_markets'), 'ru',
     'Инструменты и рынки',
     'Куда вложить и как устроен рынок'),
    ((select id from sections where code = 'funds_accounts_markets'), 'en',
     'Vehicles & Markets',
     'Where to invest and how markets work'),
    ((select id from sections where code = 'funds_accounts_markets'), 'kk',
     'Құралдар және нарықтар',
     'Инвестиция және нарық қалай жұмыс істейді'),
    -- Section 8: Build & Behave
    ((select id from sections where code = 'building_wealth'), 'ru',
     'Стратегия и поведение',
     'От знаний к действию — и психология денег'),
    ((select id from sections where code = 'building_wealth'), 'en',
     'Build & Behave',
     'From knowledge to action — and money psychology'),
    ((select id from sections where code = 'building_wealth'), 'kk',
     'Стратегия және мінез-құлық',
     'Білімнен әрекетке — және ақша психологиясы')
on conflict (section_id, language_code) do update set
    title       = excluded.title,
    description = excluded.description;