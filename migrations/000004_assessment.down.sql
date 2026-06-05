begin;

drop trigger if exists trg_quiz_question_options_updated_at on quiz_question_options;
drop trigger if exists trg_quiz_questions_updated_at on quiz_questions;
drop trigger if exists trg_quizzes_updated_at on quizzes;

drop table if exists quiz_attempt_answers;
drop table if exists quiz_attempt_questions;
drop table if exists quiz_attempts;
drop table if exists quiz_question_option_translations;
drop table if exists quiz_question_options;
drop table if exists quiz_question_translations;
drop table if exists quiz_questions;
drop table if exists quiz_translations;
drop table if exists quizzes;

commit;
