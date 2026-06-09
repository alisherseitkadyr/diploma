package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
)

var supportedSeedLanguages = []string{"en", "ru", "kk"}

type jsonSeed struct {
	Section   string             `json:"section"`
	Topic     jsonSeedTopic      `json:"topic"`
	Subtopic  jsonSeedSubtopic   `json:"subtopic"`
	Subtopics []jsonSeedSubtopic `json:"subtopics"`
	Lesson    jsonSeedLesson     `json:"lesson"`
	Quiz      jsonSeedQuiz       `json:"quiz"`
	FinalQuiz jsonSeedQuiz       `json:"finalQuiz"`
	Tips      []jsonSeedTip      `json:"tips"`
}

type jsonSeedTip struct {
	Section  string          `json:"section"`
	Title    localizedString `json:"title"`
	Body     localizedString `json:"body"`
	IconKey  string          `json:"iconKey"`
	ThemeKey string          `json:"themeKey"`
	Weight   int             `json:"weight"`
	Status   string          `json:"status"`
}

type jsonSeedTopic struct {
	Code           string          `json:"code"`
	Title          localizedString `json:"title"`
	Description    localizedString `json:"description"`
	Level          string          `json:"level"`
	OrderIndex     int             `json:"orderIndex"`
	PrerequisiteID *int64          `json:"prerequisite_id"`
	IconPath       string          `json:"icon_path"`
}

type jsonSeedSubtopic struct {
	Code             string          `json:"code"`
	Title            localizedString `json:"title"`
	Description      localizedString `json:"description"`
	EstimatedMinutes int             `json:"estimatedMinutes"`
	OrderIndex       int             `json:"orderIndex"`
	QuizID           int64           `json:"quizId"`
	Lesson           jsonSeedLesson  `json:"lesson"`
	Quiz             jsonSeedQuiz    `json:"quiz"`
}

type jsonSeedLesson struct {
	Steps []jsonSeedLessonStep `json:"steps"`
}

type jsonSeedLessonStep struct {
	ID                 string          `json:"id"`
	Order              int             `json:"order"`
	StepType           string          `json:"stepType"`
	Title              localizedString `json:"title"`
	Body               localizedString `json:"body"`
	Example            localizedString `json:"example"`
	Tip                localizedString `json:"tip"`
	Content            localizedJSON   `json:"content"`
	InteractiveType    string          `json:"interactiveType"`
	InteractiveContent localizedJSON   `json:"interactiveContent"`
}

type jsonSeedQuiz struct {
	QuizID           int64                  `json:"quiz_id"`
	QuizType         string                 `json:"quiz_type"`
	Title            localizedString        `json:"title"`
	PassingScore     int                    `json:"passing_score"`
	TimeLimitSeconds *int                   `json:"time_limit_seconds"`
	Questions        []jsonSeedQuizQuestion `json:"questions"`
}

type jsonSeedQuizQuestion struct {
	ID           int                  `json:"id"`
	QuestionType string               `json:"question_type"`
	OrderIndex   int                  `json:"order_index"`
	QuestionText localizedString      `json:"question_text"`
	Answers      []jsonSeedQuizAnswer `json:"answers"`
}

type jsonSeedQuizAnswer struct {
	ID         int             `json:"id"`
	OrderIndex int             `json:"order_index"`
	AnswerText localizedString `json:"answer_text"`
	IsCorrect  bool            `json:"is_correct"`
}

type localizedString struct {
	values map[string]string
}

func (s *localizedString) UnmarshalJSON(data []byte) error {
	trimmed := bytes.TrimSpace(data)
	if len(trimmed) == 0 || bytes.Equal(trimmed, []byte("null")) {
		return nil
	}

	var single string
	if err := json.Unmarshal(trimmed, &single); err == nil {
		s.values = map[string]string{
			"en": single,
			"ru": single,
			"kk": single,
		}
		return nil
	}

	var perLang map[string]string
	if err := json.Unmarshal(trimmed, &perLang); err != nil {
		return err
	}

	s.values = make(map[string]string, len(perLang))
	for lang, value := range perLang {
		s.values[normalizeLanguage(lang)] = value
	}

	return nil
}

func (s localizedString) ForLang(lang string) string {
	lang = normalizeLanguage(lang)
	if value, ok := s.values[lang]; ok {
		return value
	}
	if value, ok := s.values["en"]; ok {
		return value
	}
	for _, value := range s.values {
		return value
	}
	return ""
}

func (s localizedString) Empty() bool {
	for _, value := range s.values {
		if strings.TrimSpace(value) != "" {
			return false
		}
	}
	return true
}

type localizedJSON struct {
	raw json.RawMessage
}

func (j *localizedJSON) UnmarshalJSON(data []byte) error {
	trimmed := bytes.TrimSpace(data)
	if len(trimmed) == 0 || bytes.Equal(trimmed, []byte("null")) {
		return nil
	}
	if !json.Valid(trimmed) {
		return errors.New("invalid json")
	}
	j.raw = append(j.raw[:0], trimmed...)
	return nil
}

func (j localizedJSON) HasValue() bool {
	return len(bytes.TrimSpace(j.raw)) > 0
}

func (j localizedJSON) ForLang(lang string) (json.RawMessage, bool, error) {
	if !j.HasValue() {
		return nil, false, nil
	}

	var obj map[string]json.RawMessage
	if err := json.Unmarshal(j.raw, &obj); err == nil && hasLanguageKey(obj) {
		if raw, ok := obj[normalizeLanguage(lang)]; ok {
			return raw, true, nil
		}
		if normalizeLanguage(lang) == "kk" {
			if raw, ok := obj["kz"]; ok {
				return raw, true, nil
			}
		}
		if raw, ok := obj["en"]; ok {
			return raw, true, nil
		}
		for _, raw := range obj {
			return raw, true, nil
		}
	}

	return j.raw, true, nil
}

func runJSONSeed(ctx context.Context, tx pgx.Tx, data []byte) error {
	var seed jsonSeed
	if err := json.Unmarshal(data, &seed); err != nil {
		return fmt.Errorf("decode json seed: %w", err)
	}

	// Tip-only seed: skip topic/subtopic pipeline entirely.
	if len(seed.Tips) > 0 {
		return seedTips(ctx, tx, seed.Tips)
	}

	if err := seed.validate(); err != nil {
		return err
	}

	topicID, err := seedTopic(ctx, tx, seed)
	if err != nil {
		return err
	}

	for _, subtopic := range seed.normalizedSubtopics() {
		subtopicID, err := seedSubtopic(ctx, tx, seed, topicID, subtopic)
		if err != nil {
			return err
		}

		if err := seedLesson(ctx, tx, subtopic, subtopicID); err != nil {
			return err
		}

		if err := seedSubtopicQuiz(ctx, tx, subtopic); err != nil {
			return err
		}
	}

	if seed.FinalQuiz.hasContent() {
		if err := seedTopicFinalQuiz(ctx, tx, seed.Topic.Code, seed.FinalQuiz); err != nil {
			return err
		}
	}

	return nil
}

func seedTips(ctx context.Context, tx pgx.Tx, tips []jsonSeedTip) error {
	for _, t := range tips {
		sectionCode := strings.TrimSpace(t.Section)
		if sectionCode == "" {
			return fmt.Errorf("tip seed: section is required (title: %q)", t.Title.ForLang("en"))
		}

		sectionID, err := lookupSectionID(ctx, tx, sectionCode)
		if err != nil {
			return fmt.Errorf("tip seed: %w", err)
		}

		weight := t.Weight
		if weight <= 0 {
			weight = 1
		}
		status := strings.TrimSpace(t.Status)
		if status == "" {
			status = "published"
		}

		var tipID int64
		if err := tx.QueryRow(ctx, `
			insert into tips (section_id, weight, status)
			values ($1, $2, $3)
			returning id
		`, sectionID, weight, status).Scan(&tipID); err != nil {
			return fmt.Errorf("insert tip %q: %w", t.Title.ForLang("en"), err)
		}

		for _, lang := range supportedSeedLanguages {
			if _, err := tx.Exec(ctx, `
				insert into tip_translations (tip_id, language_code, title, body, icon_key, theme_key)
				values ($1, $2, $3, $4, $5, $6)
				on conflict (tip_id, language_code) do update set
					title     = excluded.title,
					body      = excluded.body,
					icon_key  = excluded.icon_key,
					theme_key = excluded.theme_key
			`, tipID, lang,
				t.Title.ForLang(lang),
				t.Body.ForLang(lang),
				t.IconKey,
				t.ThemeKey,
			); err != nil {
				return fmt.Errorf("insert tip translation %q/%s: %w", t.Title.ForLang("en"), lang, err)
			}
		}
	}
	return nil
}

func (s jsonSeed) validate() error {
	if strings.TrimSpace(s.Topic.Code) == "" {
		return errors.New("json seed: topic.code is required")
	}
	if s.Topic.Title.Empty() {
		return errors.New("json seed: topic.title is required")
	}

	subtopics := s.normalizedSubtopics()
	if len(subtopics) == 0 {
		return errors.New("json seed: subtopics must not be empty")
	}

	for _, subtopic := range subtopics {
		if strings.TrimSpace(subtopic.Code) == "" {
			return errors.New("json seed: subtopic.code is required")
		}
		if subtopic.Title.Empty() {
			return fmt.Errorf("json seed: subtopic %q title is required", subtopic.Code)
		}
		if len(subtopic.Lesson.Steps) == 0 {
			return fmt.Errorf("json seed: subtopic %q lesson.steps must not be empty", subtopic.Code)
		}
		if len(subtopic.Quiz.Questions) == 0 {
			return fmt.Errorf("json seed: subtopic %q quiz.questions must not be empty", subtopic.Code)
		}
	}

	return nil
}

func (s jsonSeed) normalizedSubtopics() []jsonSeedSubtopic {
	if len(s.Subtopics) > 0 {
		return s.Subtopics
	}
	if strings.TrimSpace(s.Subtopic.Code) == "" {
		return nil
	}

	subtopic := s.Subtopic
	if len(subtopic.Lesson.Steps) == 0 {
		subtopic.Lesson = s.Lesson
	}
	if len(subtopic.Quiz.Questions) == 0 {
		subtopic.Quiz = s.Quiz
	}

	return []jsonSeedSubtopic{subtopic}
}

func seedTopic(ctx context.Context, tx pgx.Tx, seed jsonSeed) (int64, error) {
	level := strings.TrimSpace(seed.Topic.Level)
	if level == "" {
		level = "beginner"
	}

	orderIndex := seed.Topic.OrderIndex
	if orderIndex == 0 {
		orderIndex = 1
	}

	var sectionID any
	sectionCode := strings.TrimSpace(seed.Section)
	if sectionCode == "" {
		sectionCode = "financial_foundations"
	}
	if sectionCode != "" {
		id, err := lookupSectionID(ctx, tx, sectionCode)
		if err != nil {
			return 0, err
		}
		sectionID = id
	}

	if _, err := tx.Exec(ctx, `
		update topics
		set order_index = 100000 + id::int,
			updated_at = now()
		where level = $1
		  and order_index = $2
		  and code <> $3
	`, level, orderIndex, seed.Topic.Code); err != nil {
		return 0, fmt.Errorf("move conflicting topic order: %w", err)
	}

	var topicID int64
	if err := tx.QueryRow(ctx, `
		insert into topics (code, level, order_index, is_active, section_id, icon_path)
		values ($1, $2, $3, true, $4, nullif($5, ''))
		on conflict (code) do update set
			level = excluded.level,
			order_index = excluded.order_index,
			is_active = excluded.is_active,
			section_id = coalesce(excluded.section_id, topics.section_id),
			icon_path = coalesce(excluded.icon_path, topics.icon_path),
			updated_at = now()
		returning id
	`, seed.Topic.Code, level, orderIndex, sectionID, seed.Topic.IconPath).Scan(&topicID); err != nil {
		return 0, fmt.Errorf("upsert topic %q: %w", seed.Topic.Code, err)
	}

	for _, lang := range supportedSeedLanguages {
		if _, err := tx.Exec(ctx, `
			insert into topic_translations (topic_id, language_code, title, description)
			values ($1, $2, $3, $4)
			on conflict (topic_id, language_code) do update set
				title = excluded.title,
				description = excluded.description
		`, topicID, lang, seed.Topic.Title.ForLang(lang), seed.Topic.Description.ForLang(lang)); err != nil {
			return 0, fmt.Errorf("upsert topic translation %q/%s: %w", seed.Topic.Code, lang, err)
		}
	}

	return topicID, nil
}

func lookupSectionID(ctx context.Context, tx pgx.Tx, sectionCode string) (int64, error) {
	var sectionID int64
	if err := tx.QueryRow(ctx, `
		select id
		from sections
		where code = $1
		  and is_active = true
	`, sectionCode).Scan(&sectionID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, fmt.Errorf("section %q not found; run 000_sections first", sectionCode)
		}
		return 0, fmt.Errorf("lookup section %q: %w", sectionCode, err)
	}
	return sectionID, nil
}

func seedSubtopic(ctx context.Context, tx pgx.Tx, seed jsonSeed, topicID int64, subtopic jsonSeedSubtopic) (int64, error) {
	if _, err := tx.Exec(ctx, `
		update subtopics
		set order_index = 100000 + id::int,
			updated_at = now()
		where topic_id = $1
		  and order_index = $2
		  and code <> $3
	`, topicID, subtopic.OrderIndex, subtopic.Code); err != nil {
		return 0, fmt.Errorf("move conflicting subtopic order: %w", err)
	}

	var estimatedMinutes any
	if subtopic.EstimatedMinutes > 0 {
		estimatedMinutes = subtopic.EstimatedMinutes
	}

	var subtopicID int64
	if err := tx.QueryRow(ctx, `
		insert into subtopics (topic_id, code, order_index, estimated_minutes, is_active)
		values ($1, $2, $3, $4, true)
		on conflict (code) do update set
			topic_id = excluded.topic_id,
			order_index = excluded.order_index,
			estimated_minutes = excluded.estimated_minutes,
			is_active = excluded.is_active,
			updated_at = now()
		returning id
	`, topicID, subtopic.Code, subtopic.OrderIndex, estimatedMinutes).Scan(&subtopicID); err != nil {
		return 0, fmt.Errorf("upsert subtopic %q: %w", subtopic.Code, err)
	}

	for _, lang := range supportedSeedLanguages {
		if _, err := tx.Exec(ctx, `
			insert into subtopic_translations (subtopic_id, language_code, title, description)
			values ($1, $2, $3, $4)
			on conflict (subtopic_id, language_code) do update set
				title = excluded.title,
				description = excluded.description
		`, subtopicID, lang, subtopic.Title.ForLang(lang), subtopic.Description.ForLang(lang)); err != nil {
			return 0, fmt.Errorf("upsert subtopic translation %q/%s: %w", subtopic.Code, lang, err)
		}
	}

	return subtopicID, nil
}

func seedLesson(ctx context.Context, tx pgx.Tx, subtopic jsonSeedSubtopic, subtopicID int64) error {
	var lessonID int64
	if err := tx.QueryRow(ctx, `
		insert into lessons (subtopic_id, is_published)
		values ($1, true)
		on conflict (subtopic_id) do update set
			is_published = excluded.is_published,
			updated_at = now()
		returning id
	`, subtopicID).Scan(&lessonID); err != nil {
		return fmt.Errorf("upsert lesson for subtopic %q: %w", subtopic.Code, err)
	}

	for i, step := range subtopic.Lesson.Steps {
		if err := seedLessonStep(ctx, tx, lessonID, i, step); err != nil {
			return fmt.Errorf("subtopic %q: %w", subtopic.Code, err)
		}
	}

	return nil
}

func seedLessonStep(ctx context.Context, tx pgx.Tx, lessonID int64, fallbackOrder int, step jsonSeedLessonStep) error {
	orderIndex := step.Order
	if orderIndex <= 0 {
		orderIndex = fallbackOrder + 1
	}

	stepType := strings.TrimSpace(step.StepType)
	if stepType == "" {
		stepType = "explanation"
	}

	var interactiveType any
	if step.InteractiveType != "" {
		interactiveType = step.InteractiveType
	}

	var stepID int64
	if err := tx.QueryRow(ctx, `
		insert into lesson_steps (lesson_id, step_type, order_index, interactive_type)
		values ($1, $2, $3, $4)
		on conflict (lesson_id, order_index) do update set
			step_type = excluded.step_type,
			interactive_type = excluded.interactive_type,
			updated_at = now()
		returning id
	`, lessonID, stepType, orderIndex, interactiveType).Scan(&stepID); err != nil {
		return fmt.Errorf("upsert lesson step %d: %w", orderIndex, err)
	}

	for _, lang := range supportedSeedLanguages {
		content, err := lessonStepContent(step, lang)
		if err != nil {
			return fmt.Errorf("build lesson step %d content/%s: %w", orderIndex, lang, err)
		}

		var interactiveContent any
		if raw, ok, err := step.InteractiveContent.ForLang(lang); err != nil {
			return fmt.Errorf("lesson step %d interactiveContent/%s: %w", orderIndex, lang, err)
		} else if ok {
			interactiveContent = string(raw)
		}

		if _, err := tx.Exec(ctx, `
			insert into lesson_step_translations (
				lesson_step_id,
				language_code,
				title,
				content,
				interactive_content
			)
			values ($1, $2, $3, $4::jsonb, $5::jsonb)
			on conflict (lesson_step_id, language_code) do update set
				title = excluded.title,
				content = excluded.content,
				interactive_content = excluded.interactive_content
		`, stepID, lang, step.Title.ForLang(lang), content, interactiveContent); err != nil {
			return fmt.Errorf("upsert lesson step %d translation/%s: %w", orderIndex, lang, err)
		}
	}

	return nil
}

func lessonStepContent(step jsonSeedLessonStep, lang string) (string, error) {
	if raw, ok, err := step.Content.ForLang(lang); err != nil {
		return "", err
	} else if ok {
		return string(raw), nil
	}

	blocks := make([]map[string]string, 0, 3)
	if text := strings.TrimSpace(step.Body.ForLang(lang)); text != "" {
		blocks = append(blocks, map[string]string{
			"type": "paragraph",
			"text": text,
		})
	}
	if text := strings.TrimSpace(step.Example.ForLang(lang)); text != "" {
		blocks = append(blocks, map[string]string{
			"type": "example",
			"text": "Example: " + text,
		})
	}
	if text := strings.TrimSpace(step.Tip.ForLang(lang)); text != "" {
		blocks = append(blocks, map[string]string{
			"type": "tip",
			"text": "Tip: " + text,
		})
	}

	data, err := json.Marshal(map[string]any{"blocks": blocks})
	if err != nil {
		return "", err
	}
	return string(data), nil
}

func seedSubtopicQuiz(ctx context.Context, tx pgx.Tx, subtopic jsonSeedSubtopic) error {
	return seedQuiz(ctx, tx, quizTarget{
		Quiz:          subtopic.Quiz,
		QuizType:      "subtopic_quiz",
		SubtopicCode:  subtopic.Code,
		FallbackTitle: subtopic.Title,
	})
}

func seedTopicFinalQuiz(ctx context.Context, tx pgx.Tx, topicCode string, quiz jsonSeedQuiz) error {
	return seedQuiz(ctx, tx, quizTarget{
		Quiz:          quiz,
		QuizType:      "topic_final_quiz",
		TopicCode:     topicCode,
		FallbackTitle: localizedString{values: map[string]string{"en": "Final Quiz", "ru": "Итоговый квиз", "kk": "Қорытынды тест"}},
	})
}

type quizTarget struct {
	Quiz          jsonSeedQuiz
	QuizType      string
	SubtopicCode  string
	TopicCode     string
	FallbackTitle localizedString
}

func seedQuiz(ctx context.Context, tx pgx.Tx, target quizTarget) error {
	quizType := normalizeQuizType(target.Quiz.QuizType)
	if quizType == "" {
		quizType = target.QuizType
	}
	if quizType != target.QuizType {
		return fmt.Errorf("json seed: unsupported quiz_type %q for %s", target.Quiz.QuizType, target.QuizType)
	}

	passingScore := target.Quiz.PassingScore
	if passingScore == 0 {
		passingScore = 70
	}

	var timeLimitSeconds any
	if target.Quiz.TimeLimitSeconds != nil {
		timeLimitSeconds = *target.Quiz.TimeLimitSeconds
	}

	var quizID int64
	if quizType == "subtopic_quiz" {
		if err := tx.QueryRow(ctx, `
			insert into quizzes (
				subtopic_code,
				passing_score,
				time_limit_seconds,
				quiz_type,
				is_active
			)
			values ($1, $2, $3, 'subtopic_quiz', true)
			on conflict (subtopic_code) where quiz_type = 'subtopic_quiz' do update set
				passing_score = excluded.passing_score,
				time_limit_seconds = excluded.time_limit_seconds,
				is_active = excluded.is_active,
				updated_at = now()
			returning id
		`, target.SubtopicCode, passingScore, timeLimitSeconds).Scan(&quizID); err != nil {
			return fmt.Errorf("upsert quiz for subtopic %q: %w", target.SubtopicCode, err)
		}
	} else {
		if err := tx.QueryRow(ctx, `
			insert into quizzes (
				topic_code,
				passing_score,
				time_limit_seconds,
				quiz_type,
				is_active
			)
			values ($1, $2, $3, 'topic_final_quiz', true)
			on conflict (topic_code) where quiz_type = 'topic_final_quiz' do update set
				passing_score = excluded.passing_score,
				time_limit_seconds = excluded.time_limit_seconds,
				is_active = excluded.is_active,
				updated_at = now()
			returning id
		`, target.TopicCode, passingScore, timeLimitSeconds).Scan(&quizID); err != nil {
			return fmt.Errorf("upsert final quiz for topic %q: %w", target.TopicCode, err)
		}
	}

	for _, lang := range supportedSeedLanguages {
		title := target.Quiz.Title.ForLang(lang)
		if strings.TrimSpace(title) == "" {
			title = target.FallbackTitle.ForLang(lang)
		}
		if _, err := tx.Exec(ctx, `
			insert into quiz_translations (quiz_id, language_code, title)
			values ($1, $2, $3)
			on conflict (quiz_id, language_code) do update set
				title = excluded.title
		`, quizID, lang, title); err != nil {
			return fmt.Errorf("upsert quiz translation %d/%s: %w", quizID, lang, err)
		}
	}

	questionOffset := zeroBasedQuestionOffset(target.Quiz.Questions)
	for i, question := range target.Quiz.Questions {
		if err := seedQuizQuestion(ctx, tx, quizID, i, question, questionOffset); err != nil {
			return err
		}
	}

	return nil
}

func (q jsonSeedQuiz) hasContent() bool {
	return !q.Title.Empty() || len(q.Questions) > 0 || q.QuizID != 0
}

func zeroBasedQuestionOffset(questions []jsonSeedQuizQuestion) int {
	for _, question := range questions {
		if question.OrderIndex == 0 {
			return 1
		}
	}
	return 0
}

func zeroBasedAnswerOffset(answers []jsonSeedQuizAnswer) int {
	for _, answer := range answers {
		if answer.OrderIndex == 0 {
			return 1
		}
	}
	return 0
}

func seedQuizQuestion(ctx context.Context, tx pgx.Tx, quizID int64, fallbackOrder int, question jsonSeedQuizQuestion, orderOffset int) error {
	orderIndex := question.OrderIndex + orderOffset
	if orderIndex <= 0 {
		orderIndex = fallbackOrder + 1
	}

	questionType := strings.TrimSpace(question.QuestionType)
	if questionType == "" {
		questionType = "single_choice"
	}

	var questionID int64
	if err := tx.QueryRow(ctx, `
		insert into quiz_questions (quiz_id, question_type, order_index, points)
		values ($1, $2, $3, 1)
		on conflict (quiz_id, order_index) do update set
			question_type = excluded.question_type,
			updated_at = now()
		returning id
	`, quizID, questionType, orderIndex).Scan(&questionID); err != nil {
		return fmt.Errorf("upsert quiz question %d: %w", orderIndex, err)
	}

	for _, lang := range supportedSeedLanguages {
		if _, err := tx.Exec(ctx, `
			insert into quiz_question_translations (question_id, language_code, question_text)
			values ($1, $2, $3)
			on conflict (question_id, language_code) do update set
				question_text = excluded.question_text
		`, questionID, lang, question.QuestionText.ForLang(lang)); err != nil {
			return fmt.Errorf("upsert question %d translation/%s: %w", orderIndex, lang, err)
		}
	}

	answerOffset := zeroBasedAnswerOffset(question.Answers)
	for i, answer := range question.Answers {
		if err := seedQuizAnswer(ctx, tx, questionID, orderIndex, i, answer, answerOffset); err != nil {
			return err
		}
	}

	return nil
}

func seedQuizAnswer(ctx context.Context, tx pgx.Tx, questionID int64, questionOrder int, fallbackOrder int, answer jsonSeedQuizAnswer, orderOffset int) error {
	orderIndex := answer.OrderIndex + orderOffset
	if orderIndex <= 0 {
		orderIndex = fallbackOrder + 1
	}

	var optionID int64
	if err := tx.QueryRow(ctx, `
		insert into quiz_question_options (question_id, is_correct, order_index)
		values ($1, $2, $3)
		on conflict (question_id, order_index) do update set
			is_correct = excluded.is_correct,
			updated_at = now()
		returning id
	`, questionID, answer.IsCorrect, orderIndex).Scan(&optionID); err != nil {
		return fmt.Errorf("upsert question %d answer %d: %w", questionOrder, orderIndex, err)
	}

	for _, lang := range supportedSeedLanguages {
		if _, err := tx.Exec(ctx, `
			insert into quiz_question_option_translations (option_id, language_code, option_text)
			values ($1, $2, $3)
			on conflict (option_id, language_code) do update set
				option_text = excluded.option_text
		`, optionID, lang, answer.AnswerText.ForLang(lang)); err != nil {
			return fmt.Errorf("upsert answer %d translation/%s: %w", orderIndex, lang, err)
		}
	}

	return nil
}

func normalizeLanguage(lang string) string {
	switch strings.ToLower(strings.TrimSpace(lang)) {
	case "kz":
		return "kk"
	default:
		return strings.ToLower(strings.TrimSpace(lang))
	}
}

func normalizeQuizType(quizType string) string {
	switch strings.TrimSpace(quizType) {
	case "final_quiz":
		return "topic_final_quiz"
	default:
		return strings.TrimSpace(quizType)
	}
}

func hasLanguageKey(obj map[string]json.RawMessage) bool {
	for key := range obj {
		switch normalizeLanguage(key) {
		case "en", "ru", "kk":
			return true
		}
	}
	return false
}
