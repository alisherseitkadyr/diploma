package postgres

import (
	"context"
	"errors"

	adaptationErrors "diplomaBackend/adaptation_service/errors"
	"diplomaBackend/adaptation_service/model"
	storagePostgres "diplomaBackend/internal/storage/postgres"

	"github.com/jackc/pgx/v5"
)

type AdaptationRepository struct {
	db storagePostgres.DBTX
}

func NewAdaptationRepository(db storagePostgres.DBTX) *AdaptationRepository {
	return &AdaptationRepository{db: db}
}

func (r *AdaptationRepository) GetReinforcementFeatures(ctx context.Context, userID, attemptID int64) (*model.ReinforcementFeatures, error) {
	query := `
		with current_attempt as (
			select
				qa.id as attempt_id,
				qa.user_id,
				qa.quiz_id,
				qa.score_percent::numeric as quiz_score,
				coalesce(q.quiz_type, 'subtopic_quiz') as quiz_type,
				coalesce(q.topic_code, t_from_subtopic.code) as topic_code,
				q.subtopic_code,
				topic.level as topic_level,
				coalesce(s.order_index, 5) as subtopic_order
			from quiz_attempts qa
			join quizzes q
				on q.id = qa.quiz_id
			left join subtopics s
				on s.code = q.subtopic_code
			left join topics t_from_subtopic
				on t_from_subtopic.id = s.topic_id
			join topics topic
				on topic.code = coalesce(q.topic_code, t_from_subtopic.code)
			where qa.id = $2
			  and qa.user_id = $1
			  and qa.status = 'completed'
		),
		last_3_scores as (
			select
				coalesce(avg(x.score_percent), (select quiz_score from current_attempt))::numeric as avg_last_3_scores
			from (
				select qa.score_percent
				from quiz_attempts qa
				join quizzes q
					on q.id = qa.quiz_id
				left join subtopics s
					on s.code = q.subtopic_code
				left join topics t_from_subtopic
					on t_from_subtopic.id = s.topic_id
				where qa.user_id = $1
				  and qa.status = 'completed'
				  and coalesce(q.topic_code, t_from_subtopic.code) = (select topic_code from current_attempt)
				order by coalesce(qa.completed_at, qa.submitted_at) desc, qa.id desc
				limit 3
			) x
		),
		previous_fails as (
			select
				count(*)::int as previous_fails_same_topic
			from quiz_attempts qa
			join quizzes q
				on q.id = qa.quiz_id
			left join subtopics s
				on s.code = q.subtopic_code
			left join topics t_from_subtopic
				on t_from_subtopic.id = s.topic_id
			where qa.user_id = $1
			  and qa.id <> $2
			  and qa.status = 'completed'
			  and (
	(coalesce(q.quiz_type, 'subtopic_quiz') = 'subtopic_quiz' and qa.score_percent < 70)
	or
	(q.quiz_type = 'topic_final_quiz' and qa.score_percent < 75)
)
			  and coalesce(q.topic_code, t_from_subtopic.code) = (select topic_code from current_attempt)
		),
		preferred_match as (
			select
				case
					when exists (
						select 1
						from user_preferred_topics upt
						where upt.user_id = $1
						  and upt.topic_code = preferred_topic_code((select topic_code from current_attempt))
					)
					then 1
					else 0
				end as preferred_topic_match
		)
		select
			ulp.financial_literacy_level,
			ulp.learning_goal,
			ca.topic_code,
			coalesce(ca.subtopic_code, 'topic_final') as subtopic_code,
			ca.topic_level,
			ca.quiz_type,
			ca.quiz_score,
			l3.avg_last_3_scores,
			pf.previous_fails_same_topic,
			ca.subtopic_order,
			pm.preferred_topic_match,
			1 as completed_interactive
		from current_attempt ca
		join user_learning_profiles ulp
			on ulp.user_id = ca.user_id
		cross join last_3_scores l3
		cross join previous_fails pf
		cross join preferred_match pm
	`

	var features model.ReinforcementFeatures

	err := r.db.QueryRow(ctx, query, userID, attemptID).Scan(
		&features.UserLevel,
		&features.LearningGoal,
		&features.TopicCode,
		&features.SubtopicCode,
		&features.TopicLevel,
		&features.QuizType,
		&features.QuizScore,
		&features.AvgLast3Scores,
		&features.PreviousFailsSameTopic,
		&features.SubtopicOrder,
		&features.PreferredTopicMatch,
		&features.CompletedInteractive,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, adaptationErrors.ErrReinforcementFeaturesNotFound
		}

		return nil, err
	}

	return &features, nil
}

func (r *AdaptationRepository) SaveReinforcementPrediction(ctx context.Context, prediction *model.ReinforcementPrediction) error {
	query := `
		insert into user_reinforcement_predictions (
			user_id,
			quiz_id,
			attempt_id,
			quiz_type,
			topic_code,
			subtopic_code,
			score_percent,
			avg_last_3_scores,
			needs_reinforcement,
			prediction,
			probability,
			confidence,
			decision_source,
			model_name,
			model_version
		)
		values (
			$1, $2, $3, $4, $5,
			nullif($6, ''),
			$7, $8, $9, $10,
			$11, $12, $13, $14, $15
		)
		on conflict (attempt_id) do update set
			needs_reinforcement = excluded.needs_reinforcement,
			prediction = excluded.prediction,
			probability = excluded.probability,
			confidence = excluded.confidence,
			decision_source = excluded.decision_source,
			model_name = excluded.model_name,
			model_version = excluded.model_version
	`

	_, err := r.db.Exec(
		ctx,
		query,
		prediction.UserID,
		prediction.QuizID,
		prediction.AttemptID,
		prediction.QuizType,
		prediction.TopicCode,
		prediction.SubtopicCode,
		prediction.ScorePercent,
		prediction.AvgLast3Scores,
		prediction.NeedsReinforcement,
		prediction.Prediction,
		prediction.Probability,
		prediction.Confidence,
		prediction.DecisionSource,
		prediction.ModelName,
		prediction.ModelVersion,
	)

	return err
}

func (r *AdaptationRepository) GetRecommendationUserData(ctx context.Context, userID int64) (*model.RecommendationUserData, error) {
	query := `
		select
			ulp.user_id,
			ulp.financial_literacy_level,
			ulp.practical_experience,
			ulp.learning_goal,
			ulp.time_commitment,
			coalesce(array(
				select upt.topic_code
				from user_preferred_topics upt
				where upt.user_id = ulp.user_id
				order by upt.topic_code
			), array[]::varchar[]) as preferred_topics,
			coalesce(uls.completed_subtopics_count, 0)::int,
			coalesce(uls.completed_topics_count, 0)::int,
			coalesce(uls.average_best_score_percent, 0)::numeric,
			coalesce(uls.average_all_attempts_score_percent, 0)::numeric,
			coalesce((
				select qa.score_percent::numeric
				from quiz_attempts qa
				where qa.user_id = ulp.user_id
				  and qa.status = 'completed'
				order by coalesce(qa.submitted_at, qa.created_at) desc, qa.id desc
				limit 1
			), -1)::numeric as last_quiz_score,
			coalesce((
				select count(*)
				from user_quiz_progress uqp
				where uqp.user_id = ulp.user_id
				  and (
					(uqp.quiz_type = 'subtopic_quiz' and uqp.best_score_percent < 70)
					or
					(uqp.quiz_type = 'topic_final_quiz' and uqp.best_score_percent < 75)
				  )
			), 0)::int as failed_quiz_count,
			coalesce(floor(extract(epoch from (now() - coalesce(up.last_activity_at, uls.last_quiz_completed_at, now()))) / 86400), 0)::int as days_since_last_activity
		from user_learning_profiles ulp
		left join user_learning_stats uls
			on uls.user_id = ulp.user_id
		left join user_progress up
			on up.user_id = ulp.user_id
		where ulp.user_id = $1
		  and ulp.onboarding_completed = true
	`

	var data model.RecommendationUserData

	err := r.db.QueryRow(ctx, query, userID).Scan(
		&data.UserID,
		&data.FinancialLiteracyLevel,
		&data.PracticalExperience,
		&data.LearningGoal,
		&data.TimeCommitment,
		&data.PreferredTopics,
		&data.CompletedSubtopicsCount,
		&data.CompletedTopicsCount,
		&data.AverageBestScorePercent,
		&data.AverageAllAttemptsScorePercent,
		&data.LastQuizScore,
		&data.FailedQuizCount,
		&data.DaysSinceLastActivity,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, adaptationErrors.ErrRecommendationDataNotFound
		}
		return nil, err
	}

	return &data, nil
}

func (r *AdaptationRepository) ListLearningMapSubtopics(ctx context.Context, languageCode string) ([]model.CandidateSubtopic, error) {
	query := `
		select
			t.code as topic_code,
			tt.title as topic_title,
			t.level as topic_level,
			t.order_index as topic_order_index,
			s.code as subtopic_code,
			st.title as subtopic_title,
			s.order_index as subtopic_order_index,
			s.estimated_minutes
		from topics t
		join topic_translations tt
			on tt.topic_id = t.id
		   and tt.language_code = $1
		join subtopics s
			on s.topic_id = t.id
		join subtopic_translations st
			on st.subtopic_id = s.id
		   and st.language_code = $1
		join lessons l
			on l.subtopic_id = s.id
		   and l.is_published = true
		where t.is_active = true
		  and s.is_active = true
		order by
			case t.level
				when 'beginner' then 1
				when 'intermediate' then 2
				when 'advanced' then 3
				else 4
			end,
			t.order_index,
			s.order_index
	`

	rows, err := r.db.Query(ctx, query, languageCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]model.CandidateSubtopic, 0)

	for rows.Next() {
		var item model.CandidateSubtopic

		if err := rows.Scan(
			&item.TopicCode,
			&item.TopicTitle,
			&item.TopicLevel,
			&item.TopicOrderIndex,
			&item.SubtopicCode,
			&item.SubtopicTitle,
			&item.SubtopicOrderIndex,
			&item.EstimatedMinutes,
		); err != nil {
			return nil, err
		}

		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *AdaptationRepository) GetUserSubtopicProgressMap(ctx context.Context, userID int64) (map[string]model.UserSubtopicProgress, error) {
	query := `
		select
			coalesce(topic_code, '') as topic_code,
			subtopic_code,
			best_score_percent::numeric,
			attempts_count,
			last_attempt_at
		from user_quiz_progress
		where user_id = $1
		  and quiz_type = 'subtopic_quiz'
		  and subtopic_code is not null
	`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	progressMap := make(map[string]model.UserSubtopicProgress)

	for rows.Next() {
		var item model.UserSubtopicProgress

		if err := rows.Scan(
			&item.TopicCode,
			&item.SubtopicCode,
			&item.BestScorePercent,
			&item.AttemptsCount,
			&item.LastAttemptAt,
		); err != nil {
			return nil, err
		}

		progressMap[item.SubtopicCode] = item
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return progressMap, nil
}

func (r *AdaptationRepository) GetLatestActiveReinforcement(ctx context.Context, userID int64) (*model.ActiveReinforcement, error) {
	query := `
		select
			topic_code,
			coalesce(subtopic_code, ''),
			quiz_type,
			score_percent::numeric,
			created_at
		from user_reinforcement_predictions
		where user_id = $1
		  and needs_reinforcement = true
		order by created_at desc, id desc
		limit 1
	`

	var item model.ActiveReinforcement

	err := r.db.QueryRow(ctx, query, userID).Scan(
		&item.TopicCode,
		&item.SubtopicCode,
		&item.QuizType,
		&item.ScorePercent,
		&item.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	return &item, nil
}
