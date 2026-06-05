begin;

drop function if exists seed_quiz_question(bigint, int, text, jsonb, jsonb);
drop function if exists seed_subtopic_quiz(text, int, jsonb);

commit;
