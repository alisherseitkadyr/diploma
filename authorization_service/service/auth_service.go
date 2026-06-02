package service

import (
	"context"
	"diplomaBackend/authorization_service/dto"
)

type AuthService interface {
	Register(ctx context.Context, input dto.RegisterInput) (*dto.AuthResponse, error)
	Login(ctx context.Context, input dto.LoginInput) (*dto.AuthResponse, error)
	GoogleLogin(ctx context.Context, input dto.GoogleLoginInput) (*dto.AuthResponse, error)
	Refresh(ctx context.Context, refreshToken string) (*dto.AuthResponse, error)
	Logout(ctx context.Context, refreshToken string) error
	Me(ctx context.Context, userID int64) (*dto.UserResponse, error)
	ChangePassword(ctx context.Context, userID int64, input dto.ChangePasswordInput) error
	ChangeUsername(ctx context.Context, userID int64, input dto.ChangeUsernameInput) (*dto.UserResponse, error)
	DeleteAccount(ctx context.Context, userID int64) error
}
