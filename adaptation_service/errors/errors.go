package errors

import "errors"

var (
	ErrInvalidUserID                 = errors.New("INVALID_USER_ID")
	ErrInvalidAttemptID              = errors.New("INVALID_ATTEMPT_ID")
	ErrReinforcementFeaturesNotFound = errors.New("REINFORCEMENT_FEATURES_NOT_FOUND")
	ErrRecommendationDataNotFound    = errors.New("RECOMMENDATION_DATA_NOT_FOUND")
	ErrTopicNotFound                 = errors.New("TOPIC_NOT_FOUND")
)
