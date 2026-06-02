package postgres

import (
	"context"
	postgres2 "diplomaBackend/internal/storage/postgres"
	"errors"
	"fmt"
	"time"

	authErrors "diplomaBackend/authorization_service/errors"
	"diplomaBackend/authorization_service/model"

	"github.com/jackc/pgx/v5"
)

type RefreshTokenRepository struct {
	db postgres2.DBTX
}

func NewRefreshTokenRepository(db postgres2.DBTX) *RefreshTokenRepository {
	return &RefreshTokenRepository{db: db}
}

func (r *RefreshTokenRepository) Create(ctx context.Context, token *model.RefreshToken) error {
	query := `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at, revoked_at)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`

	err := r.db.QueryRow(ctx, query,
		token.UserID,
		token.TokenHash,
		token.ExpiresAt,
		token.RevokedAt,
	).Scan(&token.ID, &token.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to create refresh token: %w", err)
	}

	return nil
}

func (r *RefreshTokenRepository) GetByTokenHash(ctx context.Context, tokenHash string) (*model.RefreshToken, error) {
	query := `
		SELECT id, user_id, token_hash, expires_at, revoked_at, created_at
		FROM refresh_tokens
		WHERE token_hash = $1
	`

	var token model.RefreshToken
	err := r.db.QueryRow(ctx, query, tokenHash).Scan(
		&token.ID,
		&token.UserID,
		&token.TokenHash,
		&token.ExpiresAt,
		&token.RevokedAt,
		&token.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, authErrors.ErrRefreshTokenNotFound
		}
		return nil, err
	}

	return &token, nil
}

func (r *RefreshTokenRepository) RevokeByTokenHash(ctx context.Context, tokenHash string) error {
	query := `
		UPDATE refresh_tokens
		SET revoked_at = $2
		WHERE token_hash = $1 AND revoked_at IS NULL
	`

	cmdTag, err := r.db.Exec(ctx, query, tokenHash, time.Now().UTC())
	if err != nil {
		return err
	}

	if cmdTag.RowsAffected() == 0 {
		return authErrors.ErrInvalidRefreshToken
	}
	return nil
}

func (r *RefreshTokenRepository) RevokeAllByUserID(ctx context.Context, userID int64) error {
	query := `
		UPDATE refresh_tokens
		SET revoked_at = $2
		WHERE user_id = $1 AND revoked_at IS NULL
	`

	_, err := r.db.Exec(ctx, query, userID, time.Now().UTC())
	return err
}

func (r *RefreshTokenRepository) RevokeAllByUserIDExceptTokenHash(ctx context.Context, userID int64, currentTokenHash string) error {
	query := `
		UPDATE refresh_tokens
		SET revoked_at = $3
		WHERE user_id = $1
		  AND token_hash <> $2
		  AND revoked_at IS NULL
	`

	_, err := r.db.Exec(ctx, query, userID, currentTokenHash, time.Now().UTC())
	return err
}
