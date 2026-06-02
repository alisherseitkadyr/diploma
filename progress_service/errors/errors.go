package errors

import "errors"

var (
	ErrInvalidUserID         = errors.New("INVALID_USER_ID")
	ErrInvalidQuizCode       = errors.New("INVALID_QUIZ_CODE")
	ErrInvalidMaxScorePoints = errors.New("INVALID_MAX_SCORE_POINTS")
	ErrInvalidScorePoints    = errors.New("INVALID_SCORE_POINTS")
	ErrInvalidScorePercent   = errors.New("INVALID_SCORE_PERCENT")

	ErrUserProgressNotFound  = errors.New("USER_PROGRESS_NOT_FOUND")
	ErrLearningStatsNotFound = errors.New("LEARNING_STATS_NOT_FOUND")
)
