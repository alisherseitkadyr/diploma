package repository

import (
	"context"
	"diplomaBackend/user_profile_service/model"
)

type SettingsRepository interface {
	GetByUserID(ctx context.Context, userID int64) (*model.UserSettings, error)
	Create(ctx context.Context, settings *model.UserSettings) error
	Update(ctx context.Context, settings *model.UserSettings) error
}
