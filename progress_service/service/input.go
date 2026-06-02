package service

import "time"

type ProcessQuizResultInput struct {
	UserID int64

	QuizCode string
	QuizType string

	TopicCode    *string
	SubtopicCode *string

	ScorePoints    int
	MaxScorePoints int
	ScorePercent   float64

	CompletedAt time.Time
}
