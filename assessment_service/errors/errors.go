package errors

import "errors"

var (
	ErrQuizNotFound            = errors.New("QUIZ_NOT_FOUND")
	ErrAttemptNotFound         = errors.New("ATTEMPT_NOT_FOUND")
	ErrInvalidLanguageCode     = errors.New("INVALID_LANGUAGE_CODE")
	ErrInvalidQuizID           = errors.New("INVALID_QUIZ_ID")
	ErrInvalidAttemptID        = errors.New("INVALID_ATTEMPT_ID")
	ErrInvalidQuestionID       = errors.New("INVALID_QUESTION_ID")
	ErrInvalidOptionID         = errors.New("INVALID_OPTION_ID")
	ErrIncompleteQuizAttempt   = errors.New("INCOMPLETE_QUIZ_ATTEMPT")
	ErrDuplicateQuestion       = errors.New("DUPLICATE_QUESTION_IN_ATTEMPT")
	ErrEmptySelectedOptions    = errors.New("EMPTY_SELECTED_OPTIONS")
	ErrInvalidSelectedCount    = errors.New("INVALID_SELECTED_OPTIONS_COUNT")
	ErrAttemptAlreadyCompleted = errors.New("ATTEMPT_ALREADY_COMPLETED")
	ErrAttemptNotInProgress    = errors.New("ATTEMPT_NOT_IN_PROGRESS")
	ErrInvalidAttemptQuestion  = errors.New("INVALID_ATTEMPT_QUESTION")
	ErrNotEnoughQuizQuestions  = errors.New("NOT_ENOUGH_QUIZ_QUESTIONS")
	ErrAttemptExpired          = errors.New("ATTEMPT_EXPIRED")
)
