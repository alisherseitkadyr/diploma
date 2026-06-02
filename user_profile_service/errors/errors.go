package errors

import "errors"

var (
	ErrProfileNotFound  = errors.New("PROFILE_NOT_FOUND")
	ErrSettingsNotFound = errors.New("SETTINGS_NOT_FOUND")

	ErrInvalidFinancialLiteracyLevel = errors.New("INVALID_FINANCIAL_LITERACY_LEVEL")
	ErrInvalidPracticalExperience    = errors.New("INVALID_PRACTICAL_EXPERIENCE")
	ErrInvalidLearningGoal           = errors.New("INVALID_LEARNING_GOAL")
	ErrInvalidPreferredLanguage      = errors.New("INVALID_PREFERRED_LANGUAGE")
	ErrInvalidTimeCommitment         = errors.New("INVALID_TIME_COMMITMENT")
	ErrInvalidPreferredTopic         = errors.New("INVALID_PREFERRED_TOPIC")

	ErrInvalidTheme            = errors.New("INVALID_THEME")
	ErrInvalidReminderTime     = errors.New("INVALID_REMINDER_TIME")
	ErrPreferredTopicsRequired = errors.New("PREFERRED_TOPICS_REQUIRED")
	ErrProfileAlreadyCompleted = errors.New("PROFILE_ALREADY_COMPLETED")
)
