package postgres

import (
	"context"
	"errors"
	"time"

	authErrors "diplomaBackend/authorization_service/errors"
	"diplomaBackend/authorization_service/model"
	storagePostgres "diplomaBackend/internal/storage/postgres"

	"github.com/jackc/pgx/v5"
)

type UserLoginSecurityRepository struct {
	db storagePostgres.DBTX
}

func NewUserLoginSecurityRepository(db storagePostgres.DBTX) *UserLoginSecurityRepository {
	return &UserLoginSecurityRepository{db: db}
}

func (r *UserLoginSecurityRepository) EnsureExists(ctx context.Context, userID int64) error {
	query := `
		INSERT INTO user_login_security (user_id, failed_attempts, locked_until)
		VALUES ($1, 0, NULL)
		ON CONFLICT (user_id) DO NOTHING
	`

	_, err := r.db.Exec(ctx, query, userID)
	return err
}

func (r *UserLoginSecurityRepository) GetByUserID(ctx context.Context, userID int64) (*model.UserLoginSecurity, error) {
	query := `
		SELECT user_id, failed_attempts, locked_until, created_at, updated_at
		FROM user_login_security
		WHERE user_id = $1
	`

	var security model.UserLoginSecurity

	err := r.db.QueryRow(ctx, query, userID).Scan(
		&security.UserID,
		&security.FailedAttempts,
		&security.LockedUntil,
		&security.CreatedAt,
		&security.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, authErrors.ErrUserLoginSecurityNotFound
		}
		return nil, err
	}

	return &security, nil
}

func (r *UserLoginSecurityRepository) IncrementFailedAttempts(ctx context.Context, userID int64) (*model.UserLoginSecurity, error) {
	query := `
		UPDATE user_login_security
		SET failed_attempts = failed_attempts + 1
		WHERE user_id = $1
		RETURNING user_id, failed_attempts, locked_until, created_at, updated_at
	`

	var security model.UserLoginSecurity

	err := r.db.QueryRow(ctx, query, userID).Scan(
		&security.UserID,
		&security.FailedAttempts,
		&security.LockedUntil,
		&security.CreatedAt,
		&security.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, authErrors.ErrUserLoginSecurityNotFound
		}
		return nil, err
	}

	return &security, nil
}

func (r *UserLoginSecurityRepository) LockUntil(ctx context.Context, userID int64, until time.Time) error {
	query := `
		UPDATE user_login_security
		SET locked_until = $2
		WHERE user_id = $1
	`

	_, err := r.db.Exec(ctx, query, userID, until)
	return err
}

func (r *UserLoginSecurityRepository) Reset(ctx context.Context, userID int64) error {
	query := `
		UPDATE user_login_security
		SET failed_attempts = 0,
		    locked_until = NULL
		WHERE user_id = $1
	`

	_, err := r.db.Exec(ctx, query, userID)
	return err
}
