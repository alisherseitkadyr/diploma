package errors

import "errors"

var (
	ErrTopicNotFound       = errors.New("TOPIC_NOT_FOUND")
	ErrLessonNotFound      = errors.New("LESSON_NOT_FOUND")
	ErrInvalidLanguageCode = errors.New("INVALID_LANGUAGE_CODE")
	ErrSubtopicNotFound    = errors.New("SUBTOPIC_NOT_FOUND")
)
