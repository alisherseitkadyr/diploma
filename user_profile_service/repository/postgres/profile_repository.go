package postgres

import (
	"context"
	"diplomaBackend/internal/storage/postgres"
	profileErrors "diplomaBackend/user_profile_service/errors"
	"diplomaBackend/user_profile_service/model"
	"errors"

	"github.com/jackc/pgx/v5"
)

type ProfileRepository struct {
	db postgres.DBTX
}

func NewProfileRepository(db postgres.DBTX) *ProfileRepository {
	return &ProfileRepository{db: db}
}

func (r *ProfileRepository) GetByUserID(ctx context.Context, userID int64) (*model.UserLearningProfile, error) {
	query := `
		SELECT id, user_id, financial_literacy_level, practical_experience,
		       learning_goal, preferred_language, time_commitment,
		       onboarding_completed, created_at, updated_at
		FROM user_learning_profiles
		WHERE user_id = $1
	`

	var profile model.UserLearningProfile

	err := r.db.QueryRow(ctx, query, userID).Scan(
		&profile.ID,
		&profile.UserID,
		&profile.FinancialLiteracyLevel,
		&profile.PracticalExperience,
		&profile.LearningGoal,
		&profile.PreferredLanguage,
		&profile.TimeCommitment,
		&profile.OnboardingCompleted,
		&profile.CreatedAt,
		&profile.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, profileErrors.ErrProfileNotFound
		}
		return nil, err
	}

	return &profile, nil
}

func (r *ProfileRepository) Create(ctx context.Context, profile *model.UserLearningProfile) error {
	query := `
		INSERT INTO user_learning_profiles (
			user_id,
			financial_literacy_level,
			practical_experience,
			learning_goal,
			preferred_language,
			time_commitment,
			onboarding_completed
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`

	return r.db.QueryRow(
		ctx,
		query,
		profile.UserID,
		profile.FinancialLiteracyLevel,
		profile.PracticalExperience,
		profile.LearningGoal,
		profile.PreferredLanguage,
		profile.TimeCommitment,
		profile.OnboardingCompleted,
	).Scan(&profile.ID, &profile.CreatedAt, &profile.UpdatedAt)
}

func (r *ProfileRepository) Update(ctx context.Context, profile *model.UserLearningProfile) error {
	query := `
		UPDATE user_learning_profiles
		SET financial_literacy_level = $2,
		    practical_experience = $3,
		    learning_goal = $4,
		    preferred_language = $5,
		    time_commitment = $6,
		    onboarding_completed = $7
		WHERE user_id = $1
		RETURNING updated_at
	`

	return r.db.QueryRow(
		ctx,
		query,
		profile.UserID,
		profile.FinancialLiteracyLevel,
		profile.PracticalExperience,
		profile.LearningGoal,
		profile.PreferredLanguage,
		profile.TimeCommitment,
		profile.OnboardingCompleted,
	).Scan(&profile.UpdatedAt)
}

func (r *ProfileRepository) UpdatePreferredLanguage(ctx context.Context, userID int64, languageCode string) error {
	query := `
		UPDATE user_learning_profiles
		SET preferred_language = $2
		WHERE user_id = $1
	`

	cmdTag, err := r.db.Exec(ctx, query, userID, languageCode)
	if err != nil {
		return err
	}

	if cmdTag.RowsAffected() == 0 {
		return profileErrors.ErrProfileNotFound
	}

	return err
}
