package postgres

import (
	"context"
	"errors"

	"diplomaBackend/assessment_service/dto"
	assessmentErrors "diplomaBackend/assessment_service/errors"
	"diplomaBackend/assessment_service/model"
	storagePostgres "diplomaBackend/internal/storage/postgres"

	"github.com/jackc/pgx/v5"
)

type AssessmentRepository struct {
	db storagePostgres.DBTX
}

func NewAssessmentRepository(db storagePostgres.DBTX) *AssessmentRepository {
	return &AssessmentRepository{db: db}
}

func (r *AssessmentRepository) GetQuizByID(ctx context.Context, quizID int64, languageCode string) (*dto.QuizResponse, error) {
	quizQuery := `
	select
		q.id,
		q.subtopic_code,
		q.topic_code,
		coalesce(q.quiz_type, 'subtopic_quiz') as quiz_type,
		qt.title,
		q.passing_score,
		q.time_limit_seconds
	from quizzes q
	join quiz_translations qt
		on qt.quiz_id = q.id
	   and qt.language_code = $2
	where q.id = $1
	  and q.is_active = true
`

	var quiz dto.QuizResponse

	if err := r.db.QueryRow(ctx, quizQuery, quizID, languageCode).Scan(
		&quiz.ID,
		&quiz.SubtopicCode,
		&quiz.TopicCode,
		&quiz.QuizType,
		&quiz.Title,
		&quiz.PassingScore,
		&quiz.TimeLimitSeconds,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, assessmentErrors.ErrQuizNotFound
		}
		return nil, err
	}

	questions, err := r.getQuestionsWithOptions(ctx, quizID, languageCode)
	if err != nil {
		return nil, err
	}

	quiz.Questions = questions
	return &quiz, nil
}

func (r *AssessmentRepository) GetQuizStartMeta(ctx context.Context, quizID int64, languageCode string) (*model.QuizStartMeta, error) {
	query := `
    select
        q.id,
        coalesce(q.quiz_type, 'subtopic_quiz') as quiz_type,
        qt.title,
        q.topic_code,
        t.level,
        q.passing_score
    from quizzes q
    join quiz_translations qt
        on qt.quiz_id = q.id
       and qt.language_code = $2
    left join subtopics s
        on s.code = q.subtopic_code
    join topics t
        on (
            coalesce(q.quiz_type, 'subtopic_quiz') = 'subtopic_quiz'
            and t.id = s.topic_id
        )
        or (
            q.quiz_type = 'topic_final_quiz'
            and t.code = q.topic_code
        )
    where q.id = $1
      and q.is_active = true
`

	var meta model.QuizStartMeta

	if err := r.db.QueryRow(ctx, query, quizID, languageCode).Scan(
		&meta.ID,
		&meta.QuizType,
		&meta.Title,
		&meta.TopicCode,
		&meta.TopicLevel,
		&meta.PassingScore,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, assessmentErrors.ErrQuizNotFound
		}
		return nil, err
	}

	return &meta, nil
}

func (r *AssessmentRepository) GetSubtopicQuizInfoByTopicCode(ctx context.Context, topicCode string) ([]model.SubtopicQuizInfo, error) {
	query := `
		select s.id, s.code, q.id as quiz_id
		from subtopics s
		join topics t on t.id = s.topic_id
		join quizzes q
			on q.subtopic_code = s.code
		   and q.quiz_type = 'subtopic_quiz'
		   and q.is_active = true
		where t.code = $1
		  and t.is_active = true
		  and s.is_active = true
		order by s.order_index
	`

	rows, err := r.db.Query(ctx, query, topicCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var infos []model.SubtopicQuizInfo
	for rows.Next() {
		var info model.SubtopicQuizInfo
		if err := rows.Scan(&info.SubtopicID, &info.SubtopicCode, &info.QuizID); err != nil {
			return nil, err
		}
		infos = append(infos, info)
	}

	return infos, rows.Err()
}

func (r *AssessmentRepository) GetRandomQuestionsByQuizID(ctx context.Context, quizID int64, languageCode string, limit int) ([]dto.QuestionResponse, error) {
	query := `
		with selected_questions as (
			select
				qq.id,
				qq.question_type,
				row_number() over () as attempt_order
			from quiz_questions qq
			where qq.quiz_id = $1
			order by random()
			limit $3
		)
		select
			sq.id as question_id,
			sq.question_type,
			sq.attempt_order::int as question_order,
			qqt.question_text,
			qqo.id as option_id,
			qqo.order_index as option_order,
			qqot.option_text,
			qqo.is_correct
		from selected_questions sq
		join quiz_question_translations qqt
			on qqt.question_id = sq.id
		   and qqt.language_code = $2
		join quiz_question_options qqo
			on qqo.question_id = sq.id
		join quiz_question_option_translations qqot
			on qqot.option_id = qqo.id
		   and qqot.language_code = $2
		order by sq.attempt_order, qqo.order_index
	`

	rows, err := r.db.Query(ctx, query, quizID, languageCode, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	questions := make([]dto.QuestionResponse, 0)
	questionIndex := make(map[int64]int)

	for rows.Next() {
		var questionID int64
		var questionType string
		var questionOrder int
		var questionText string
		var option dto.OptionResponse

		if err := rows.Scan(
			&questionID,
			&questionType,
			&questionOrder,
			&questionText,
			&option.ID,
			&option.OrderIndex,
			&option.Text,
			&option.IsCorrect,
		); err != nil {
			return nil, err
		}

		idx, ok := questionIndex[questionID]
		if !ok {
			questions = append(questions, dto.QuestionResponse{
				ID:           questionID,
				QuestionType: questionType,
				OrderIndex:   questionOrder,
				QuestionText: questionText,
				Options:      make([]dto.OptionResponse, 0),
			})
			idx = len(questions) - 1
			questionIndex[questionID] = idx
		}

		questions[idx].Options = append(questions[idx].Options, option)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return questions, nil
}

func (r *AssessmentRepository) CreateStartedAttempt(ctx context.Context, attempt *model.QuizAttempt) error {
	query := `
		insert into quiz_attempts (
			user_id,
			quiz_id,
			total_questions,
			correct_answers,
			wrong_answers,
			score_percent,
			passed,
			duration_seconds,
			xp_for_score,
			status,
			started_at
		)
		values ($1, $2, $3, 0, 0, 0, false, 0, 0, $4, now())
		returning id, started_at
	`

	return r.db.QueryRow(
		ctx,
		query,
		attempt.UserID,
		attempt.QuizID,
		attempt.TotalQuestions,
		attempt.Status,
	).Scan(&attempt.ID, &attempt.StartedAt)
}

func (r *AssessmentRepository) CreateAttemptQuestions(ctx context.Context, attemptID int64, questions []dto.QuestionResponse) error {
	query := `
		insert into quiz_attempt_questions (
			attempt_id,
			question_id,
			order_index
		)
		values ($1, $2, $3)
	`

	for i, question := range questions {
		orderIndex := question.OrderIndex
		if orderIndex <= 0 {
			orderIndex = i + 1
		}

		if _, err := r.db.Exec(ctx, query, attemptID, question.ID, orderIndex); err != nil {
			return err
		}
	}

	return nil
}

func (r *AssessmentRepository) GetAttemptCheckData(ctx context.Context, userID, attemptID int64) (*model.AttemptCheckData, error) {
	attemptQuery := `
	select
		qa.id,
		qa.user_id,
		qa.quiz_id,
		coalesce(q.quiz_type, 'subtopic_quiz') as quiz_type,
		q.topic_code,
		q.subtopic_code,
		q.passing_score,
		qa.status
	from quiz_attempts qa
	join quizzes q
		on q.id = qa.quiz_id
	where qa.id = $1
	  and qa.user_id = $2
`

	var data model.AttemptCheckData

	if err := r.db.QueryRow(ctx, attemptQuery, attemptID, userID).Scan(
		&data.AttemptID,
		&data.UserID,
		&data.QuizID,
		&data.QuizType,
		&data.TopicCode,
		&data.SubtopicCode,
		&data.PassingScore,
		&data.Status,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, assessmentErrors.ErrAttemptNotFound
		}
		return nil, err
	}

	questionsQuery := `
		select
			qq.id,
			qq.question_type,
			qqo.id,
			qqo.question_id,
			qqo.is_correct
		from quiz_attempt_questions qaq
		join quiz_questions qq
			on qq.id = qaq.question_id
		join quiz_question_options qqo
			on qqo.question_id = qq.id
		where qaq.attempt_id = $1
		order by qaq.order_index, qqo.order_index
	`

	rows, err := r.db.Query(ctx, questionsQuery, attemptID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	questionIndex := make(map[int64]int)

	for rows.Next() {
		var questionID int64
		var questionType string
		var option model.OptionCheckData

		if err := rows.Scan(
			&questionID,
			&questionType,
			&option.ID,
			&option.QuestionID,
			&option.IsCorrect,
		); err != nil {
			return nil, err
		}

		idx, ok := questionIndex[questionID]
		if !ok {
			data.Questions = append(data.Questions, model.QuestionCheckData{
				ID:           questionID,
				QuestionType: questionType,
				Options:      make([]model.OptionCheckData, 0),
			})
			idx = len(data.Questions) - 1
			questionIndex[questionID] = idx
		}

		data.Questions[idx].Options = append(data.Questions[idx].Options, option)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return &data, nil
}

func (r *AssessmentRepository) CreateAttemptAnswers(ctx context.Context, answers []model.QuizAttemptAnswer) error {
	query := `
		insert into quiz_attempt_answers (
			attempt_id,
			question_id,
			selected_option_id,
			is_correct,
			is_selected_option_correct,
			is_question_correct
		)
		values ($1, $2, $3, $4, $5, $6)
	`

	for _, answer := range answers {
		if _, err := r.db.Exec(
			ctx,
			query,
			answer.AttemptID,
			answer.QuestionID,
			answer.SelectedOptionID,
			answer.IsCorrect,
			answer.IsSelectedOptionCorrect,
			answer.IsQuestionCorrect,
		); err != nil {
			return err
		}
	}

	return nil
}

func (r *AssessmentRepository) CompleteAttempt(ctx context.Context, attempt *model.QuizAttempt) error {
	query := `
		update quiz_attempts
		set
			total_questions = $3,
			correct_answers = $4,
			wrong_answers = $5,
			score_percent = $6,
			passed = $7,
			duration_seconds = $8,
			xp_for_score = $9,
			status = 'completed',
			completed_at = now(),
			submitted_at = now()
		where id = $1
		  and user_id = $2
		  and status = 'in_progress'
	`

	tag, err := r.db.Exec(
		ctx,
		query,
		attempt.ID,
		attempt.UserID,
		attempt.TotalQuestions,
		attempt.CorrectAnswers,
		attempt.WrongAnswers,
		attempt.ScorePercent,
		attempt.Passed,
		attempt.DurationSeconds,
		attempt.XPForScore,
	)
	if err != nil {
		return err
	}

	if tag.RowsAffected() == 0 {
		return assessmentErrors.ErrAttemptNotInProgress
	}

	return nil
}

func (r *AssessmentRepository) GetLatestAttemptByQuizID(ctx context.Context, userID, quizID int64) (*dto.AttemptSummaryResponse, error) {
	query := `
		select
			id,
			quiz_id,
			score_percent,
			total_questions,
			correct_answers,
			wrong_answers,
			passed,
			xp_for_score,
			coalesce(completed_at, submitted_at) as submitted_at
		from quiz_attempts
		where user_id = $1
		  and quiz_id = $2
		  and status = 'completed'
		order by coalesce(completed_at, submitted_at) desc, id desc
		limit 1
	`

	var attempt dto.AttemptSummaryResponse

	if err := r.db.QueryRow(ctx, query, userID, quizID).Scan(
		&attempt.AttemptID,
		&attempt.QuizID,
		&attempt.ScorePercent,
		&attempt.TotalQuestions,
		&attempt.CorrectAnswers,
		&attempt.WrongAnswers,
		&attempt.Passed,
		&attempt.XPForScore,
		&attempt.SubmittedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, assessmentErrors.ErrAttemptNotFound
		}
		return nil, err
	}

	return &attempt, nil
}

func (r *AssessmentRepository) GetAttemptByID(ctx context.Context, userID, attemptID int64) (*dto.AttemptDetailResponse, error) {
	query := `
		select
			id,
			quiz_id,
			score_percent,
			total_questions,
			correct_answers,
			wrong_answers,
			passed,
			xp_for_score,
			coalesce(completed_at, submitted_at) as submitted_at
		from quiz_attempts
		where id = $1
		  and user_id = $2
		  and status = 'completed'
	`

	var attempt dto.AttemptDetailResponse

	if err := r.db.QueryRow(ctx, query, attemptID, userID).Scan(
		&attempt.AttemptID,
		&attempt.QuizID,
		&attempt.ScorePercent,
		&attempt.TotalQuestions,
		&attempt.CorrectAnswers,
		&attempt.WrongAnswers,
		&attempt.Passed,
		&attempt.XPForScore,
		&attempt.SubmittedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, assessmentErrors.ErrAttemptNotFound
		}
		return nil, err
	}

	return &attempt, nil
}

func (r *AssessmentRepository) GetAttemptAnswers(ctx context.Context, attemptID int64, languageCode string) ([]dto.AttemptAnswerDetails, error) {
	query := `
		select
			qq.id as question_id,
			qqt.question_text,
			qq.question_type,
			qaq.order_index,
			qqo.id as option_id,
			qqot.option_text,
			qqo.is_correct as option_is_correct,
			coalesce(qaa.selected_option_id is not null, false) as is_selected,
			coalesce(qaa.is_selected_option_correct, false) as is_selected_option_correct,
			coalesce(qaa.is_question_correct, false) as is_question_correct
		from quiz_attempt_questions qaq
		join quiz_questions qq
			on qq.id = qaq.question_id
		join quiz_question_translations qqt
			on qqt.question_id = qq.id
		   and qqt.language_code = $2
		join quiz_question_options qqo
			on qqo.question_id = qq.id
		join quiz_question_option_translations qqot
			on qqot.option_id = qqo.id
		   and qqot.language_code = $2
		left join quiz_attempt_answers qaa
			on qaa.attempt_id = qaq.attempt_id
		   and qaa.question_id = qq.id
		   and qaa.selected_option_id = qqo.id
		where qaq.attempt_id = $1
		order by qaq.order_index, qqo.order_index
	`

	rows, err := r.db.Query(ctx, query, attemptID, languageCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	answers := make([]dto.AttemptAnswerDetails, 0)
	questionIndex := make(map[int64]int)

	for rows.Next() {
		var questionID int64
		var questionText string
		var questionType string
		var orderIndex int
		var optionID int64
		var optionText string
		var optionIsCorrect bool
		var isSelected bool
		var isSelectedOptionCorrect bool
		var isQuestionCorrect bool

		if err := rows.Scan(
			&questionID,
			&questionText,
			&questionType,
			&orderIndex,
			&optionID,
			&optionText,
			&optionIsCorrect,
			&isSelected,
			&isSelectedOptionCorrect,
			&isQuestionCorrect,
		); err != nil {
			return nil, err
		}

		idx, ok := questionIndex[questionID]
		if !ok {
			answers = append(answers, dto.AttemptAnswerDetails{
				QuestionID:        questionID,
				QuestionText:      questionText,
				QuestionType:      questionType,
				OrderIndex:        orderIndex,
				SelectedOptions:   make([]dto.SelectedOptionResult, 0),
				CorrectOptions:    make([]dto.CorrectOptionResult, 0),
				IsQuestionCorrect: isQuestionCorrect,
			})
			idx = len(answers) - 1
			questionIndex[questionID] = idx
		}

		if optionIsCorrect {
			answers[idx].CorrectOptions = append(answers[idx].CorrectOptions, dto.CorrectOptionResult{
				OptionID: optionID,
				Text:     optionText,
			})
		}

		if isSelected {
			answers[idx].SelectedOptions = append(answers[idx].SelectedOptions, dto.SelectedOptionResult{
				OptionID:  optionID,
				Text:      optionText,
				IsCorrect: isSelectedOptionCorrect,
			})
			answers[idx].IsQuestionCorrect = isQuestionCorrect
		}
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return answers, nil
}

func (r *AssessmentRepository) getQuestionsWithOptions(ctx context.Context, quizID int64, languageCode string) ([]dto.QuestionResponse, error) {
	query := `
		select
			qq.id,
			qq.question_type,
			qq.order_index,
			qqt.question_text,
			qqo.id,
			qqo.order_index,
			qqot.option_text,
			qqo.is_correct
		from quiz_questions qq
		join quiz_question_translations qqt
			on qqt.question_id = qq.id
		   and qqt.language_code = $2
		join quiz_question_options qqo
			on qqo.question_id = qq.id
		join quiz_question_option_translations qqot
			on qqot.option_id = qqo.id
		   and qqot.language_code = $2
		where qq.quiz_id = $1
		order by qq.order_index, qqo.order_index
	`

	rows, err := r.db.Query(ctx, query, quizID, languageCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	questions := make([]dto.QuestionResponse, 0)
	questionIndex := make(map[int64]int)

	for rows.Next() {
		var question dto.QuestionResponse
		var option dto.OptionResponse

		if err := rows.Scan(
			&question.ID,
			&question.QuestionType,
			&question.OrderIndex,
			&question.QuestionText,
			&option.ID,
			&option.OrderIndex,
			&option.Text,
			&option.IsCorrect,
		); err != nil {
			return nil, err
		}

		idx, ok := questionIndex[question.ID]
		if !ok {
			question.Options = make([]dto.OptionResponse, 0)
			questions = append(questions, question)
			idx = len(questions) - 1
			questionIndex[question.ID] = idx
		}

		questions[idx].Options = append(questions[idx].Options, option)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return questions, nil
}

func (r *AssessmentRepository) ExpireAttemptIfNeeded(ctx context.Context, userID, attemptID int64) (bool, error) {
	query := `
		update quiz_attempts
		set status = 'expired'
		where user_id = $1
		  and id = $2
		  and status = 'in_progress'
		  and started_at < now() - interval '30 minutes'
	`

	tag, err := r.db.Exec(ctx, query, userID, attemptID)
	if err != nil {
		return false, err
	}

	return tag.RowsAffected() > 0, nil
}
