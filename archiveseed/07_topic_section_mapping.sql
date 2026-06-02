-- ══════════════════════════════════════════════════════════════
-- 07 — TOPIC→SECTION BACKFILL (runs after all topic seeds)
-- ══════════════════════════════════════════════════════════════

update topics
set section_id = (select id from sections where code = 'money_foundations')
where code in (
    'personal_finance_basics',
    'money_and_banking',
    'budgeting_cash_flow',
    'debt_and_credit'
);

update topics
set section_id = (select id from sections where code = 'save_and_protect')
where code in (
    'emergency_funds',
    'insurance_basics'
);

update topics
set section_id = (select id from sections where code = 'start_investing')
where code in (
    'why_invest',
    'stocks',
    'bonds'
);

update topics
set section_id = (select id from sections where code = 'where_to_invest')
where code in (
    'funds_etf',
    'retirement_accounts',
    'real_estate_lite'
);

update topics
set section_id = (select id from sections where code = 'understand_market')
where code in (
    'how_markets_work',
    'macro_for_investors',
    'interest_rates_inflation'
);

update topics
set section_id = (select id from sections where code = 'modern_money')
where code in (
    'crypto_blockchain',
    'fintech_payments'
);

update topics
set section_id = (select id from sections where code = 'optimizer')
where code in (
    'portfolio_construction',
    'financial_statements',
    'tax_planning',
    'estate_planning',
    'career_income',
    'behavioral_finance',
    'personal_financial_plan'
);

