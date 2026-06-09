package dto

import "encoding/json"

type TopicResponse struct {
	ID          int64  `json:"id"`
	Code        string `json:"code"`
	Level       string `json:"level"`
	OrderIndex  int    `json:"orderIndex"`
	Title       string `json:"title"`
	Description string `json:"description,omitempty"`
	IconPath    string `json:"icon_path,omitempty"`
	XpReward    int    `json:"xp"`
}

type SubtopicResponse struct {
	ID               int64  `json:"id"`
	Code             string `json:"code"`
	OrderIndex       int    `json:"orderIndex"`
	EstimatedMinutes *int   `json:"estimatedMinutes,omitempty"`
	Title            string `json:"title"`
	Description      string `json:"description,omitempty"`
	QuizID           *int64 `json:"quizId,omitempty"`
}

type TopicFinalQuizResponse struct {
	QuizID           int64  `json:"quizId"`
	TopicCode        string `json:"topicCode"`
	QuizType         string `json:"quizType"`
	Title            string `json:"title"`
	PassingScore     int    `json:"passingScore"`
	TimeLimitSeconds *int   `json:"timeLimitSeconds,omitempty"`
}

type TopicSubtopicsResponse struct {
	Subtopics []SubtopicResponse      `json:"subtopics"`
	FinalQuiz *TopicFinalQuizResponse `json:"finalQuiz,omitempty"`
}

type LessonStepResponse struct {
	ID                 int64           `json:"id"`
	StepType           string          `json:"stepType"`
	OrderIndex         int             `json:"orderIndex"`
	Title              *string         `json:"title,omitempty"`
	Content            json.RawMessage `json:"content"`
	InteractiveType    *string         `json:"interactiveType,omitempty"`
	InteractiveContent json.RawMessage `json:"interactiveContent,omitempty"`
}

type LessonResponse struct {
	LessonID      int64                `json:"lessonId"`
	TopicCode     string               `json:"topicCode"`
	TopicTitle    string               `json:"topicTitle"`
	TopicLevel    string               `json:"topicLevel"`
	SubtopicCode  string               `json:"subtopicCode"`
	SubtopicTitle string               `json:"subtopicTitle"`
	Steps         []LessonStepResponse `json:"steps"`
}

// ── Tip ───────────────────────────────────────────────────────

type TipResponse struct {
	ID          int64  `json:"id"`
	SectionCode string `json:"sectionCode"`
	Title       string `json:"title"`
	Body        string `json:"body"`
	IconKey     string `json:"iconKey"`
	ThemeKey    string `json:"themeKey"`
}

// ── Explore view (sections + topics + progress) ───────────────

type ExploreTopicResponse struct {
	ID               int64  `json:"id"`
	Code             string `json:"code"`
	Title            string `json:"title"`
	Description      string `json:"description,omitempty"`
	Level            string `json:"level"`
	OrderIndex       int    `json:"orderIndex"`
	EstimatedMinutes int    `json:"estimatedMinutes"`
	LessonsDone      int    `json:"lessonsDone"`
	LessonsTotal     int    `json:"lessonsTotal"`
	XpReward         int    `json:"xpReward"`
	IconPath         string `json:"icon_path,omitempty"`
}

type ExploreSectionResponse struct {
	ID           int64                  `json:"id"`
	Code         string                 `json:"code"`
	OrderIndex   int                    `json:"orderIndex"`
	Icon         string                 `json:"icon,omitempty"`
	Title        string                 `json:"title"`
	Description  string                 `json:"description,omitempty"`
	Topics       []ExploreTopicResponse `json:"topics"`
	LessonsDone  int                    `json:"lessonsDone"`
	LessonsTotal int                    `json:"lessonsTotal"`
}

type ExploreViewResponse struct {
	Sections []ExploreSectionResponse `json:"sections"`
}
