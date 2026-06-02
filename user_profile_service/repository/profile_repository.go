package repository

import (
	"context"
	"diplomaBackend/user_profile_service/model"
)

type ProfileRepository interface {
	GetByUserID(ctx context.Context, userID int64) (*model.UserLearningProfile, error)
	Create(ctx context.Context, profile *model.UserLearningProfile) error
	Update(ctx context.Context, profile *model.UserLearningProfile) error
	UpdatePreferredLanguage(ctx context.Context, userID int64, languageCode string) error
}
