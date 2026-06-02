-- ══════════════════════════════════════════════════════════════
-- 000 — SECTIONS (runs before all topic seeds)
-- ══════════════════════════════════════════════════════════════

insert into sections (code, order_index, icon) values
    ('money_foundations',   1, '💰'),
    ('save_and_protect',    2, '🛡'),
    ('start_investing',     3, '📈'),
    ('where_to_invest',     4, '🏦'),
    ('understand_market',   5, '🌐'),
    ('modern_money',        6, '⚡'),
    ('optimizer',           7, '🎯')
on conflict (code) do update set
    order_index = excluded.order_index,
    icon        = excluded.icon,
    updated_at  = now();

insert into section_translations (section_id, language_code, title, description) values
    -- Section 1: Money Foundations
    ((select id from sections where code = 'money_foundations'), 'ru',
     'Основы денег',
     'Базовые навыки — зарабатывать, тратить, сберегать, защищать'),
    ((select id from sections where code = 'money_foundations'), 'en',
     'Money Basics',
     'Get your money basics right — earn, spend, save, protect'),
    ((select id from sections where code = 'money_foundations'), 'kk',
     'Ақшаның негіздері',
     'Негізгі дағдылар — табу, жұмсау, жинақтау, қорғау'),
    -- Section 2: Save & Protect
    ((select id from sections where code = 'save_and_protect'), 'ru',
     'Сбережения и защита',
     'Сначала защита — экстренный фонд и страховки'),
    ((select id from sections where code = 'save_and_protect'), 'en',
     'Save and Protect',
     'Defense first — emergency funds and insurance'),
    ((select id from sections where code = 'save_and_protect'), 'kk',
     'Жинақтау және қорғану',
     'Алдымен қорғаныс — төтенше қор және сақтандыру'),
    -- Section 3: Start Investing
    ((select id from sections where code = 'start_investing'), 'ru',
     'Начало инвестиций',
     'Заставьте деньги работать — компаундинг, акции, облигации'),
    ((select id from sections where code = 'start_investing'), 'en',
     'Start Investing',
     'Make your money work — compounding, stocks, bonds'),
    ((select id from sections where code = 'start_investing'), 'kk',
     'Инвестицияны бастау',
     'Ақшаны жұмыс істетіңіз — компаундинг, акциялар, облигациялар'),
    -- Section 4: Where to Invest
    ((select id from sections where code = 'where_to_invest'), 'ru',
     'Куда инвестировать',
     'Выберите инструменты — фонды, пенсия, недвижимость'),
    ((select id from sections where code = 'where_to_invest'), 'en',
     'Where to Invest',
     'Pick your vehicles — funds, retirement accounts, real estate'),
    ((select id from sections where code = 'where_to_invest'), 'kk',
     'Қайда инвестициялау',
     'Құралдарыңызды таңдаңыз — қорлар, зейнетақы, жылжымайтын мүлік'),
    -- Section 5: Understand the Market
    ((select id from sections where code = 'understand_market'), 'ru',
     'Понять рынок',
     'Изучите систему — рынки, макроэкономика, ставки'),
    ((select id from sections where code = 'understand_market'), 'en',
     'Understand the Market',
     'Know the system — markets, macro, rates'),
    ((select id from sections where code = 'understand_market'), 'kk',
     'Нарықты түсіну',
     'Жүйені біліңіз — нарықтар, макроэкономика, мөлшерлемелер'),
    -- Section 6: Modern Money
    ((select id from sections where code = 'modern_money'), 'ru',
     'Современные деньги',
     'Криптовалюта и финтех — современные инструменты'),
    ((select id from sections where code = 'modern_money'), 'en',
     'Modern Money',
     'Crypto and fintech — modern money tools'),
    ((select id from sections where code = 'modern_money'), 'kk',
     'Заманауи ақша',
     'Криптовалюта және финтех — заманауи құралдар'),
    -- Section 7: Optimizer
    ((select id from sections where code = 'optimizer'), 'ru',
     'Оптимизатор',
     'Мастер-уровень — оптимизация, налоги, планирование'),
    ((select id from sections where code = 'optimizer'), 'en',
     'Become an Optimizer',
     'Master mode — optimization, taxes, planning'),
    ((select id from sections where code = 'optimizer'), 'kk',
     'Оптимизатор болыңыз',
     'Шебер деңгей — оңтайландыру, салық, жоспарлау')
on conflict (section_id, language_code) do update set
    title       = excluded.title,
    description = excluded.description;
