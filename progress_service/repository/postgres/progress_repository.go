package postgres

import (
	"context"
	"errors"

	storagePostgres "diplomaBackend/internal/storage/postgres"
	"diplomaBackend/progress_service/dto"
	progressErrors "diplomaBackend/progress_service/errors"
	"diplomaBackend/progress_service/model"

	"github.com/jackc/pgx/v5"
)

type ProgressRepository struct {
	db storagePostgres.DBTX
}

func NewProgressRepository(db storagePostgres.DBTX) *ProgressRepository {
	return &ProgressRepository{db: db}
}

func (r *ProgressRepository) EnsureUserProgress(ctx context.Context, userID int64) error {
	query := `
		insert into user_progress (
			user_id,
			total_xp,
			progress_level,
			last_activity_at
		)
		values ($1, 0, 'beginner', null)
		on conflict (user_id) do nothing
	`

	_, err := r.db.Exec(ctx, query, userID)
	return err
}

func (r *ProgressRepository) GetQuizProgress(ctx context.Context, userID int64, quizCode string) (*model.UserQuizProgress, error) {
	query := `
		select
			id,
			user_id,
			quiz_code,
			quiz_type,
			topic_code,
			subtopic_code,
			best_score_points,
			max_score_points,
			best_score_percent,
			earned_xp,
			attempts_count,
			first_attempt_at,
			best_attempt_at,
			last_attempt_at,
			created_at,
			updated_at
		from user_quiz_progress
		where user_id = $1
		  and quiz_code = $2
	`

	var progress model.UserQuizProgress

	err := r.db.QueryRow(ctx, query, userID, quizCode).Scan(
		&progress.ID,
		&progress.UserID,
		&progress.QuizCode,
		&progress.QuizType,
		&progress.TopicCode,
		&progress.SubtopicCode,
		&progress.BestScorePoints,
		&progress.MaxScorePoints,
		&progress.BestScorePercent,
		&progress.EarnedXP,
		&progress.AttemptsCount,
		&progress.FirstAttemptAt,
		&progress.BestAttemptAt,
		&progress.LastAttemptAt,
		&progress.CreatedAt,
		&progress.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}

		return nil, err
	}

	return &progress, nil
}

func (r *ProgressRepository) CreateQuizProgress(ctx context.Context, progress *model.UserQuizProgress) error {
	query := `
		insert into user_quiz_progress (
			user_id,
			quiz_code,
			quiz_type,
			topic_code,
			subtopic_code,
			best_score_points,
			max_score_points,
			best_score_percent,
			earned_xp,
			attempts_count,
			first_attempt_at,
			best_attempt_at,
			last_attempt_at
		)
		values (
			$1, $2, $3, $4, $5,
			$6, $7, $8, $9, 1,
			now(), now(), now()
		)
	`

	_, err := r.db.Exec(
		ctx,
		query,
		progress.UserID,
		progress.QuizCode,
		progress.QuizType,
		progress.TopicCode,
		progress.SubtopicCode,
		progress.BestScorePoints,
		progress.MaxScorePoints,
		progress.BestScorePercent,
		progress.EarnedXP,
	)

	return err
}

func (r *ProgressRepository) UpdateQuizProgressAttemptOnly(ctx context.Context, userID int64, quizCode string, completedAt string) error {
	query := `
		update user_quiz_progress
		set
			attempts_count = attempts_count + 1,
			last_attempt_at = $3::timestamptz
		where user_id = $1
		  and quiz_code = $2
	`

	_, err := r.db.Exec(ctx, query, userID, quizCode, completedAt)
	return err
}

func (r *ProgressRepository) UpdateQuizProgressBest(ctx context.Context, progress *model.UserQuizProgress, completedAt string) error {
	query := `
		update user_quiz_progress
		set
			topic_code = $3,
			subtopic_code = $4,
			best_score_points = $5,
			max_score_points = $6,
			best_score_percent = $7,
			earned_xp = $8,
			attempts_count = attempts_count + 1,
			best_attempt_at = $9::timestamptz,
			last_attempt_at = $9::timestamptz
		where user_id = $1
		  and quiz_code = $2
	`

	_, err := r.db.Exec(
		ctx,
		query,
		progress.UserID,
		progress.QuizCode,
		progress.TopicCode,
		progress.SubtopicCode,
		progress.BestScorePoints,
		progress.MaxScorePoints,
		progress.BestScorePercent,
		progress.EarnedXP,
		completedAt,
	)

	return err
}

func (r *ProgressRepository) AddXP(ctx context.Context, userID int64, xpDelta int) error {
	if xpDelta <= 0 {
		return nil
	}

	query := `
		update user_progress
		set
			total_xp = total_xp + $2,
			progress_level = case
				when total_xp + $2 >= 260 then 'advanced_learner'
				when total_xp + $2 >= 150 then 'practitioner'
				when total_xp + $2 >= 60 then 'amateur'
				else 'beginner'
			end,
			last_activity_at = now()
		where user_id = $1
	`

	_, err := r.db.Exec(ctx, query, userID, xpDelta)
	return err
}

func (r *ProgressRepository) RecalculateLearningStats(ctx context.Context, userID int64) error {
	query := `
		with quiz_progress_stats as (
			select
				$1::bigint as user_id,
				coalesce(sum(attempts_count), 0)::int as total_quiz_attempts,
				count(*)::int as completed_quizzes_count,
				count(*) filter (where quiz_type = 'subtopic_quiz')::int as completed_subtopic_quizzes_count,
				count(*) filter (where quiz_type = 'topic_final_quiz')::int as completed_topic_final_quizzes_count,
				count(*) filter (where quiz_type = 'subtopic_quiz' and best_score_percent >= 70)::int as completed_subtopics_count,
				count(*) filter (
					where quiz_type = 'topic_final_quiz'
					  and best_score_percent >= 75
				)::int as completed_topics_count,
				coalesce(avg(best_score_percent), 0)::numeric(5,2) as average_best_score_percent,
				count(*) filter (where best_score_percent = 100)::int as max_score_quizzes_count,
				max(last_attempt_at) as last_quiz_completed_at
			from user_quiz_progress
			where user_id = $1
		),
		all_attempts_stats as (
			select
				coalesce(avg(qa.score_percent), 0)::numeric(5,2) as average_all_attempts_score_percent
			from quiz_attempts qa
			where qa.user_id = $1
			  and qa.status = 'completed'
		),
		best_topic as (
			select topic_code
			from user_quiz_progress
			where user_id = $1
			  and topic_code is not null
			group by topic_code
			order by avg(best_score_percent) desc, topic_code
			limit 1
		),
		weakest_topic as (
			select topic_code
			from user_quiz_progress
			where user_id = $1
			  and topic_code is not null
			group by topic_code
			order by avg(best_score_percent) asc, topic_code
			limit 1
		)
		insert into user_learning_stats (
			user_id,
			total_quiz_attempts,
			completed_quizzes_count,
			completed_subtopic_quizzes_count,
			completed_topic_final_quizzes_count,
			completed_subtopics_count,
			completed_topics_count,
			average_best_score_percent,
			average_all_attempts_score_percent,
			max_score_quizzes_count,
			best_topic_code,
			weakest_topic_code,
			last_quiz_completed_at
		)
		select
			qps.user_id,
			qps.total_quiz_attempts,
			qps.completed_quizzes_count,
			qps.completed_subtopic_quizzes_count,
			qps.completed_topic_final_quizzes_count,
			qps.completed_subtopics_count,
			qps.completed_topics_count,
			qps.average_best_score_percent,
			aas.average_all_attempts_score_percent,
			qps.max_score_quizzes_count,
			(select topic_code from best_topic),
			(select topic_code from weakest_topic),
			qps.last_quiz_completed_at
		from quiz_progress_stats qps
		cross join all_attempts_stats aas
		on conflict (user_id) do update
		set
			total_quiz_attempts = excluded.total_quiz_attempts,
			completed_quizzes_count = excluded.completed_quizzes_count,
			completed_subtopic_quizzes_count = excluded.completed_subtopic_quizzes_count,
			completed_topic_final_quizzes_count = excluded.completed_topic_final_quizzes_count,
			completed_subtopics_count = excluded.completed_subtopics_count,
			completed_topics_count = excluded.completed_topics_count,
			average_best_score_percent = excluded.average_best_score_percent,
			average_all_attempts_score_percent = excluded.average_all_attempts_score_percent,
			max_score_quizzes_count = excluded.max_score_quizzes_count,
			best_topic_code = excluded.best_topic_code,
			weakest_topic_code = excluded.weakest_topic_code,
			last_quiz_completed_at = excluded.last_quiz_completed_at
	`

	_, err := r.db.Exec(ctx, query, userID)
	return err
}

func (r *ProgressRepository) GetUserProgress(ctx context.Context, userID int64) (*model.UserProgress, error) {
	query := `
		select
			user_id,
			total_xp,
			progress_level,
			last_activity_at,
			created_at,
			updated_at
		from user_progress
		where user_id = $1
	`

	var progress model.UserProgress

	err := r.db.QueryRow(ctx, query, userID).Scan(
		&progress.UserID,
		&progress.TotalXP,
		&progress.ProgressLevel,
		&progress.LastActivityAt,
		&progress.CreatedAt,
		&progress.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, progressErrors.ErrUserProgressNotFound
		}

		return nil, err
	}

	return &progress, nil
}

func (r *ProgressRepository) GetCompletedTopicCodes(ctx context.Context, userID int64) ([]string, error) {
	query := `
		select uqp.topic_code
		from user_quiz_progress uqp
		join topics t on t.code = uqp.topic_code and t.is_active = true
		where uqp.user_id = $1
		  and uqp.quiz_type = 'topic_final_quiz'
		  and uqp.best_score_percent >= 75
		  and uqp.topic_code is not null
		  and not exists (
		      select 1
		      from subtopics s
		      where s.topic_id = t.id
		        and s.is_active = true
		        and not exists (
		            select 1
		            from user_subtopic_readings usr
		            where usr.user_id = $1
		              and usr.subtopic_id = s.id
		        )
		  )
		order by uqp.topic_code
	`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return []string{}, err
	}
	defer rows.Close()

	var codes []string
	for rows.Next() {
		var code string
		if err := rows.Scan(&code); err != nil {
			return []string{}, err
		}
		codes = append(codes, code)
	}
	if codes == nil {
		codes = []string{}
	}

	return codes, rows.Err()
}

func (r *ProgressRepository) GetTopicSubtopicProgress(ctx context.Context, userID int64) (map[string]dto.TopicProgressDetail, error) {
	query := `
		with subtopic_counts as (
		    select
		        t.code as topic_code,
		        count(s.id)::int as total_subtopics,
		        count(usr.subtopic_id)::int as subtopics_read
		    from topics t
		    join subtopics s on s.topic_id = t.id and s.is_active = true
		    left join user_subtopic_readings usr
		        on usr.subtopic_id = s.id and usr.user_id = $1
		    where t.is_active = true
		    group by t.code
		),
		quiz_status as (
		    select topic_code, (best_score_percent >= 75) as quiz_passed
		    from user_quiz_progress
		    where user_id = $1
		      and quiz_type = 'topic_final_quiz'
		      and topic_code is not null
		)
		select
		    sc.topic_code,
		    sc.total_subtopics,
		    sc.subtopics_read,
		    coalesce(qs.quiz_passed, false) as quiz_passed
		from subtopic_counts sc
		left join quiz_status qs on qs.topic_code = sc.topic_code
	`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return map[string]dto.TopicProgressDetail{}, err
	}
	defer rows.Close()

	result := make(map[string]dto.TopicProgressDetail)
	for rows.Next() {
		var code string
		var d dto.TopicProgressDetail
		if err := rows.Scan(&code, &d.TotalSubtopics, &d.SubtopicsRead, &d.QuizPassed); err != nil {
			return map[string]dto.TopicProgressDetail{}, err
		}
		d.IsComplete = d.SubtopicsRead == d.TotalSubtopics && d.QuizPassed
		result[code] = d
	}

	return result, rows.Err()
}

func (r *ProgressRepository) GetLearningStats(ctx context.Context, userID int64) (*model.UserLearningStats, error) {
	query := `
		select
			user_id,
			total_quiz_attempts,
			completed_quizzes_count,
			completed_subtopic_quizzes_count,
			completed_topic_final_quizzes_count,
			completed_subtopics_count,
			completed_topics_count,
			average_best_score_percent,
			average_all_attempts_score_percent,
			max_score_quizzes_count,
			best_topic_code,
			weakest_topic_code,
			last_quiz_completed_at,
			created_at,
			updated_at
		from user_learning_stats
		where user_id = $1
	`

	var stats model.UserLearningStats

	err := r.db.QueryRow(ctx, query, userID).Scan(
		&stats.UserID,
		&stats.TotalQuizAttempts,
		&stats.CompletedQuizzesCount,
		&stats.CompletedSubtopicQuizzesCount,
		&stats.CompletedTopicFinalQuizzesCount,
		&stats.CompletedSubtopicsCount,
		&stats.CompletedTopicsCount,
		&stats.AverageBestScorePercent,
		&stats.AverageAllAttemptsScorePercent,
		&stats.MaxScoreQuizzesCount,
		&stats.BestTopicCode,
		&stats.WeakestTopicCode,
		&stats.LastQuizCompletedAt,
		&stats.CreatedAt,
		&stats.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, progressErrors.ErrLearningStatsNotFound
		}

		return nil, err
	}

	return &stats, nil
}
