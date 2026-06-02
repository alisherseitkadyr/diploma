package repository

import (
	"context"

	"diplomaBackend/authorization_service/model"
)

type RefreshTokenRepository interface {
	Create(ctx context.Context, token *model.RefreshToken) error
	GetByTokenHash(ctx context.Context, tokenHash string) (*model.RefreshToken, error)
	RevokeByTokenHash(ctx context.Context, tokenHash string) error
	RevokeAllByUserID(ctx context.Context, userID int64) error
	RevokeAllByUserIDExceptTokenHash(ctx context.Context, userID int64, currentTokenHash string) error
}
