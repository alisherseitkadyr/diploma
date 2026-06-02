package postgres

import (
	"context"
	"diplomaBackend/internal/storage/postgres"
	profileErrors "diplomaBackend/user_profile_service/errors"
	"diplomaBackend/user_profile_service/model"
	"errors"

	"github.com/jackc/pgx/v5"
)

type SettingsRepository struct {
	db postgres.DBTX
}

func NewSettingsRepository(db postgres.DBTX) *SettingsRepository {
	return &SettingsRepository{db: db}
}

func (r *SettingsRepository) GetByUserID(ctx context.Context, userID int64) (*model.UserSettings, error) {
	query := `
		SELECT id, user_id, language_code, theme, notifications_enabled,
		       reminder_time, created_at, updated_at
		FROM user_settings
		WHERE user_id = $1
	`

	var settings model.UserSettings

	err := r.db.QueryRow(ctx, query, userID).Scan(
		&settings.ID,
		&settings.UserID,
		&settings.LanguageCode,
		&settings.Theme,
		&settings.NotificationsEnabled,
		&settings.ReminderTime,
		&settings.CreatedAt,
		&settings.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, profileErrors.ErrSettingsNotFound
		}
		return nil, err
	}

	return &settings, nil
}

func (r *SettingsRepository) Create(ctx context.Context, settings *model.UserSettings) error {
	query := `
		INSERT INTO user_settings (
			user_id,
			language_code,
			theme,
			notifications_enabled,
			reminder_time
		)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at
	`

	return r.db.QueryRow(
		ctx,
		query,
		settings.UserID,
		settings.LanguageCode,
		settings.Theme,
		settings.NotificationsEnabled,
		settings.ReminderTime,
	).Scan(&settings.ID, &settings.CreatedAt, &settings.UpdatedAt)
}

func (r *SettingsRepository) Update(ctx context.Context, settings *model.UserSettings) error {
	query := `
		UPDATE user_settings
		SET language_code = $2,
		    theme = $3,
		    notifications_enabled = $4,
		    reminder_time = $5
		WHERE user_id = $1
		RETURNING updated_at
	`

	err := r.db.QueryRow(
		ctx,
		query,
		settings.UserID,
		settings.LanguageCode,
		settings.Theme,
		settings.NotificationsEnabled,
		settings.ReminderTime,
	).Scan(&settings.UpdatedAt)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return profileErrors.ErrSettingsNotFound
		}
		return err
	}

	return nil
}
