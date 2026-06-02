package repository

import (
	"context"
	"diplomaBackend/authorization_service/model"
	"time"
)

type UserLoginSecurityRepository interface {
	EnsureExists(ctx context.Context, userID int64) error
	GetByUserID(ctx context.Context, userID int64) (*model.UserLoginSecurity, error)
	IncrementFailedAttempts(ctx context.Context, userID int64) (*model.UserLoginSecurity, error)
	LockUntil(ctx context.Context, userID int64, until time.Time) error
	Reset(ctx context.Context, userID int64) error
}
