package model

import "time"

const (
	QuizTypeSubtopicQuiz   = "subtopic_quiz"
	QuizTypeTopicFinalQuiz = "topic_final_quiz"
)

const (
	QuestionTypeSingleChoice   = "single_choice"
	QuestionTypeMultipleChoice = "multiple_choice"
	QuestionTypeTrueFalse      = "true_false"
)

const (
	AttemptStatusInProgress = "in_progress"
	AttemptStatusCompleted  = "completed"
	AttemptStatusExpired    = "expired"
	AttemptStatusAbandoned  = "abandoned"
)

type QuizStartMeta struct {
	ID           int64
	QuizType     string
	Title        string
	TopicCode    *string
	TopicLevel   string
	PassingScore int
}

type SubtopicQuizInfo struct {
	SubtopicID   int64
	SubtopicCode string
	QuizID       int64
}

type QuizAttempt struct {
	ID              int64
	UserID          int64
	QuizID          int64
	TotalQuestions  int
	CorrectAnswers  int
	WrongAnswers    int
	ScorePercent    int
	Passed          bool
	XPForScore      int
	DurationSeconds int
	Status          string
	StartedAt       time.Time
	CompletedAt     *time.Time
	SubmittedAt     time.Time
}

type QuizAttemptQuestion struct {
	AttemptID  int64
	QuestionID int64
	OrderIndex int
}

type AttemptCheckData struct {
	AttemptID    int64
	UserID       int64
	QuizID       int64
	QuizType     string
	TopicCode    *string
	SubtopicCode *string
	PassingScore int
	Status       string
	Questions    []QuestionCheckData
}

type QuestionCheckData struct {
	ID           int64
	QuestionType string
	Options      []OptionCheckData
}

type OptionCheckData struct {
	ID         int64
	QuestionID int64
	IsCorrect  bool
}

type QuizAttemptAnswer struct {
	AttemptID               int64
	QuestionID              int64
	SelectedOptionID        int64
	IsCorrect               bool
	IsSelectedOptionCorrect bool
	IsQuestionCorrect       bool
}
