package service

import (
	"context"
	"diplomaBackend/user_profile_service/dto"
)

type UserProfileService interface {
	GetProfileByUserID(ctx context.Context, userID int64) (*dto.ProfileResponse, error)
	UpsertProfile(ctx context.Context, input UpsertProfileInput) (*dto.ProfileResponse, error)
	GetQuestionnaireOptions(ctx context.Context) (*dto.QuestionnaireOptionsResponse, error)

	GetSettingsByUserID(ctx context.Context, userID int64) (*dto.SettingsResponse, error)
	UpdateSettings(ctx context.Context, input UpdateSettingsInput) (*dto.SettingsResponse, error)
}
