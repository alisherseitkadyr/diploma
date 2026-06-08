package postgres

import (
	"context"
	"errors"

	"diplomaBackend/content_service/dto"
	contentErrors "diplomaBackend/content_service/errors"
	storagePostgres "diplomaBackend/internal/storage/postgres"

	"github.com/jackc/pgx/v5"
)

type ContentRepository struct {
	db storagePostgres.DBTX
}

func NewContentRepository(db storagePostgres.DBTX) *ContentRepository {
	return &ContentRepository{db: db}
}

func (r *ContentRepository) ListTopics(ctx context.Context, languageCode string) ([]dto.TopicResponse, error) {
	query := `
		select
			t.id,
			t.code,
			t.level,
			t.order_index,
			tt.title,
			tt.description
		from topics t
		join topic_translations tt
			on tt.topic_id = t.id
		   and tt.language_code = $1
		where t.is_active = true
		order by
			case t.level
				when 'beginner' then 1
				when 'intermediate' then 2
				when 'advanced' then 3
			end,
			t.order_index
	`

	rows, err := r.db.Query(ctx, query, languageCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	topics := make([]dto.TopicResponse, 0)

	for rows.Next() {
		var item dto.TopicResponse
		var description *string

		if err := rows.Scan(
			&item.ID,
			&item.Code,
			&item.Level,
			&item.OrderIndex,
			&item.Title,
			&description,
		); err != nil {
			return nil, err
		}

		if description != nil {
			item.Description = *description
		}

		topics = append(topics, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return topics, nil
}

func (r *ContentRepository) ListSubtopicsByTopicCode(ctx context.Context, topicCode, languageCode string) ([]dto.SubtopicResponse, error) {
	query := `
	select
		s.id,
		s.code,
		s.order_index,
		s.estimated_minutes,
		st.title,
		st.description,
		q.id as quiz_id
	from subtopics s
	join topics t
		on t.id = s.topic_id
	join subtopic_translations st
		on st.subtopic_id = s.id
	   and st.language_code = $2
	left join quizzes q
		on q.subtopic_code = s.code
	   and q.quiz_type = 'subtopic_quiz'
	   and q.is_active = true
	where t.code = $1
	  and t.is_active = true
	  and s.is_active = true
	order by s.order_index
`

	rows, err := r.db.Query(ctx, query, topicCode, languageCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	subtopics := make([]dto.SubtopicResponse, 0)

	for rows.Next() {
		var item dto.SubtopicResponse
		var description *string

		if err := rows.Scan(
			&item.ID,
			&item.Code,
			&item.OrderIndex,
			&item.EstimatedMinutes,
			&item.Title,
			&description,
			&item.QuizID,
		); err != nil {
			return nil, err
		}

		if description != nil {
			item.Description = *description
		}

		subtopics = append(subtopics, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if len(subtopics) == 0 {
		existsQuery := `
			select 1
			from topics
			where code = $1
			  and is_active = true
		`

		var exists int
		if err := r.db.QueryRow(ctx, existsQuery, topicCode).Scan(&exists); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return nil, contentErrors.ErrTopicNotFound
			}
			return nil, err
		}
	}

	return subtopics, nil
}

func (r *ContentRepository) GetTopicFinalQuizByTopicCode(ctx context.Context, topicCode, languageCode string) (*dto.TopicFinalQuizResponse, error) {
	query := `
		select
			q.id,
			q.topic_code,
			q.quiz_type,
			qt.title,
			q.passing_score,
			q.time_limit_seconds
		from quizzes q
		join quiz_translations qt
			on qt.quiz_id = q.id
		   and qt.language_code = $2
		where q.topic_code = $1
		  and q.quiz_type = 'topic_final_quiz'
		  and q.is_active = true
	`

	var item dto.TopicFinalQuizResponse

	if err := r.db.QueryRow(ctx, query, topicCode, languageCode).Scan(
		&item.QuizID,
		&item.TopicCode,
		&item.QuizType,
		&item.Title,
		&item.PassingScore,
		&item.TimeLimitSeconds,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	return &item, nil
}

func (r *ContentRepository) GetLessonBySubtopicCode(ctx context.Context, subtopicCode, languageCode string) (*dto.LessonResponse, error) {
	lessonQuery := `
		select
			l.id,
			t.code,
			tt.title,
			t.level,
			s.code,
			st.title
		from lessons l
		join subtopics s
			on s.id = l.subtopic_id
		join topics t
			on t.id = s.topic_id
		join topic_translations tt
			on tt.topic_id = t.id
		   and tt.language_code = $2
		join subtopic_translations st
			on st.subtopic_id = s.id
		   and st.language_code = $2
		where s.code = $1
		  and t.is_active = true
		  and s.is_active = true
		  and l.is_published = true
	`

	var lesson dto.LessonResponse

	if err := r.db.QueryRow(ctx, lessonQuery, subtopicCode, languageCode).Scan(
		&lesson.LessonID,
		&lesson.TopicCode,
		&lesson.TopicTitle,
		&lesson.TopicLevel,
		&lesson.SubtopicCode,
		&lesson.SubtopicTitle,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, contentErrors.ErrLessonNotFound
		}
		return nil, err
	}

	stepsQuery := `
		select
			ls.id,
			ls.step_type,
			ls.order_index,
			lst.title,
			lst.content,
			ls.interactive_type,
			lst.interactive_content
		from lesson_steps ls
		join lesson_step_translations lst
			on lst.lesson_step_id = ls.id
		   and lst.language_code = $2
		where ls.lesson_id = $1
		order by ls.order_index
	`

	rows, err := r.db.Query(ctx, stepsQuery, lesson.LessonID, languageCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var steps []dto.LessonStepResponse

	for rows.Next() {
		var step dto.LessonStepResponse
		var title *string
		var content []byte
		var interactiveType *string
		var interactiveContent []byte

		if err := rows.Scan(
			&step.ID,
			&step.StepType,
			&step.OrderIndex,
			&title,
			&content,
			&interactiveType,
			&interactiveContent,
		); err != nil {
			return nil, err
		}

		step.Title = title
		step.Content = content
		step.InteractiveType = interactiveType

		if interactiveContent != nil {
			step.InteractiveContent = interactiveContent
		}

		steps = append(steps, step)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	lesson.Steps = steps

	return &lesson, nil
}

func (r *ContentRepository) MarkSubtopicRead(ctx context.Context, userID int64, subtopicCode string) error {
	query := `
		insert into user_subtopic_readings (user_id, subtopic_id)
		select $1, id from subtopics where code = $2
		on conflict (user_id, subtopic_id) do nothing
	`
	_, err := r.db.Exec(ctx, query, userID, subtopicCode)
	return err
}

func (r *ContentRepository) GetRandomTip(ctx context.Context, languageCode string) (*dto.TipResponse, error) {
	query := `
		select
			t.id,
			s.code,
			tt.title,
			tt.body,
			tt.icon_key,
			tt.theme_key
		from tips t
		join tip_translations tt
			on tt.tip_id = t.id
		   and tt.language_code = $1
		join sections s
			on s.id = t.section_id
		where t.status = 'published'
		order by random()
		limit 1
	`

	var tip dto.TipResponse
	if err := r.db.QueryRow(ctx, query, languageCode).Scan(
		&tip.ID,
		&tip.SectionCode,
		&tip.Title,
		&tip.Body,
		&tip.IconKey,
		&tip.ThemeKey,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, contentErrors.ErrNoTipsFound
		}
		return nil, err
	}

	return &tip, nil
}

func (r *ContentRepository) GetExploreView(ctx context.Context, userID int64, languageCode string) (*dto.ExploreViewResponse, error) {
	const query = `
		with subtopic_counts as (
			select
				s.topic_id,
				count(s.id)::int                          as total,
				count(usr.subtopic_id)::int               as done,
				coalesce(sum(s.estimated_minutes), 0)::int as estimated_minutes
			from subtopics s
			left join user_subtopic_readings usr
				on usr.subtopic_id = s.id and usr.user_id = $2
			where s.is_active = true
			group by s.topic_id
		)
		select
			sec.id,
			sec.code,
			sec.order_index,
			coalesce(sec.icon, ''),
			coalesce(st.title, sec.code),
			coalesce(st.description, ''),
			t.id,
			t.code,
			t.level,
			t.order_index,
			tt.title,
			coalesce(tt.description, ''),
			coalesce(sc.estimated_minutes, 0),
			case t.level
				when 'beginner'     then 50
				when 'intermediate' then 75
				when 'advanced'     then 100
				else 0
			end,
			coalesce(sc.total, 0),
			coalesce(sc.done,  0)
		from sections sec
		left join section_translations st
			on st.section_id = sec.id and st.language_code = $1
		left join topics t
			on t.section_id = sec.id and t.is_active = true
		left join topic_translations tt
			on tt.topic_id = t.id and tt.language_code = $1
		left join subtopic_counts sc
			on sc.topic_id = t.id
		where sec.is_active = true
		order by sec.order_index, t.order_index
	`

	rows, err := r.db.Query(ctx, query, languageCode, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var (
		sectionIDs []int64
		sectionMap = make(map[int64]*dto.ExploreSectionResponse)
	)

	for rows.Next() {
		var (
			secID    int64
			secCode  string
			secOrder int
			secIcon  string
			secTitle string
			secDesc  string

			topicID    *int64
			topicCode  *string
			topicLevel *string
			topicOrder *int
			topicTitle *string
			topicDesc  string
			estMins    int
			xpReward   int
			lesTotal   int
			lesDone    int
		)

		if err := rows.Scan(
			&secID, &secCode, &secOrder, &secIcon, &secTitle, &secDesc,
			&topicID, &topicCode, &topicLevel, &topicOrder, &topicTitle,
			&topicDesc, &estMins, &xpReward, &lesTotal, &lesDone,
		); err != nil {
			return nil, err
		}

		sec, ok := sectionMap[secID]
		if !ok {
			sec = &dto.ExploreSectionResponse{
				ID:          secID,
				Code:        secCode,
				OrderIndex:  secOrder,
				Icon:        secIcon,
				Title:       secTitle,
				Description: secDesc,
				Topics:      make([]dto.ExploreTopicResponse, 0),
			}
			sectionMap[secID] = sec
			sectionIDs = append(sectionIDs, secID)
		}

		if topicID != nil {
			title := ""
			if topicTitle != nil {
				title = *topicTitle
			}
			sec.Topics = append(sec.Topics, dto.ExploreTopicResponse{
				ID:               *topicID,
				Code:             *topicCode,
				Title:            title,
				Description:      topicDesc,
				Level:            *topicLevel,
				OrderIndex:       *topicOrder,
				EstimatedMinutes: estMins,
				XpReward:         xpReward,
				LessonsTotal:     lesTotal,
				LessonsDone:      lesDone,
			})
			sec.LessonsDone += lesDone
			sec.LessonsTotal += lesTotal
		}
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	sections := make([]dto.ExploreSectionResponse, 0, len(sectionIDs))
	for _, id := range sectionIDs {
		sections = append(sections, *sectionMap[id])
	}

	return &dto.ExploreViewResponse{Sections: sections}, nil
}
