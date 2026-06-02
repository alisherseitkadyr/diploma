package postgres

import (
	"context"
	"diplomaBackend/authorization_service/validation"
	postgres2 "diplomaBackend/internal/storage/postgres"
	"errors"

	authErrors "diplomaBackend/authorization_service/errors"
	"diplomaBackend/authorization_service/model"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type UserRepository struct {
	db postgres2.DBTX
}

func NewUserRepository(db postgres2.DBTX) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(ctx context.Context, user *model.User) error {
	user.Email = validation.NormalizeEmail(user.Email)
	user.Username = validation.NormalizeUsername(user.Username)

	query := `
		INSERT INTO users (email, username, password_hash, is_active)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, updated_at
	`

	err := r.db.QueryRow(ctx, query,
		user.Email,
		user.Username,
		user.PasswordHash,
		user.IsActive,
	).Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) {
			if pgErr.Code == "23505" {
				return authErrors.ErrEmailAlreadyExists
			}
		}
		return err
	}

	return nil
}

func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*model.User, error) {
	email = validation.NormalizeEmail(email)

	query := `
		SELECT id, email, username, password_hash, is_active, created_at, updated_at
		FROM users
		WHERE email = $1
	`

	var user model.User
	err := r.db.QueryRow(ctx, query, email).Scan(
		&user.ID,
		&user.Email,
		&user.Username,
		&user.PasswordHash,
		&user.IsActive,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, authErrors.ErrUserNotFound
		}
		return nil, err
	}

	return &user, nil
}

func (r *UserRepository) GetByUsername(ctx context.Context, username string) (*model.User, error) {
	username = validation.NormalizeUsername(username)

	query := `
		SELECT id, email, username, password_hash, is_active, created_at, updated_at
		FROM users
		WHERE username = $1
		ORDER BY id
		LIMIT 1
	`

	var user model.User
	err := r.db.QueryRow(ctx, query, username).Scan(
		&user.ID,
		&user.Email,
		&user.Username,
		&user.PasswordHash,
		&user.IsActive,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, authErrors.ErrUserNotFound
		}
		return nil, err
	}

	return &user, nil
}

func (r *UserRepository) GetByID(ctx context.Context, id int64) (*model.User, error) {
	query := `
		SELECT id, email, username, password_hash, is_active, created_at, updated_at
		FROM users
		WHERE id = $1
	`

	var user model.User
	err := r.db.QueryRow(ctx, query, id).Scan(
		&user.ID,
		&user.Email,
		&user.Username,
		&user.PasswordHash,
		&user.IsActive,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, authErrors.ErrUserNotFound
		}
		return nil, err
	}

	return &user, nil
}

func (r *UserRepository) UpdateUsername(ctx context.Context, userID int64, username string) error {
	username = validation.NormalizeUsername(username)

	query := `
		UPDATE users
		SET username = $2, updated_at = NOW()
		WHERE id = $1
	`

	cmdTag, err := r.db.Exec(ctx, query, userID, username)
	if err != nil {
		return err
	}

	if cmdTag.RowsAffected() == 0 {
		return authErrors.ErrUserNotFound
	}

	return nil
}

func (r *UserRepository) UpdatePasswordHash(ctx context.Context, userID int64, passwordHash string) error {
	query := `
		UPDATE users
		SET password_hash = $2, updated_at = NOW()
		WHERE id = $1
	`

	cmdTag, err := r.db.Exec(ctx, query, userID, passwordHash)
	if err != nil {
		return err
	}

	if cmdTag.RowsAffected() == 0 {
		return authErrors.ErrUserNotFound
	}

	return nil
}

func (r *UserRepository) DeleteByID(ctx context.Context, userID int64) error {
	_, err := r.db.Exec(ctx, `DELETE FROM users WHERE id = $1`, userID)
	return err
}
