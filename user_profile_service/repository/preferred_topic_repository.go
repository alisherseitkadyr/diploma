package repository

import (
	"context"
	"diplomaBackend/user_profile_service/model"
)

type PreferredTopicRepository interface {
	GetByUserID(ctx context.Context, userID int64) ([]model.UserPreferredTopic, error)
	ReplaceByUserID(ctx context.Context, userID int64, topicCodes []string) error
}
