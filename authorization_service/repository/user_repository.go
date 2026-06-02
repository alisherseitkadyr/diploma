package repository

import (
	"context"

	"diplomaBackend/authorization_service/model"
)

type UserRepository interface {
	Create(ctx context.Context, user *model.User) error
	GetByEmail(ctx context.Context, email string) (*model.User, error)
	GetByUsername(ctx context.Context, username string) (*model.User, error)
	GetByID(ctx context.Context, id int64) (*model.User, error)
	UpdateUsername(ctx context.Context, userID int64, username string) error
	UpdatePasswordHash(ctx context.Context, userID int64, passwordHash string) error
	DeleteByID(ctx context.Context, userID int64) error
}
