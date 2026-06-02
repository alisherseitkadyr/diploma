package auth

import (
	"context"
	"diplomaBackend/authorization_service/dto"
	"diplomaBackend/internal/logger"
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	authErrors "diplomaBackend/authorization_service/errors"
	"diplomaBackend/authorization_service/model"
	"diplomaBackend/authorization_service/repository"
	"diplomaBackend/authorization_service/service"
	"diplomaBackend/authorization_service/validation"
)

type Service struct {
	userRepo              repository.UserRepository
	refreshTokenRepo      repository.RefreshTokenRepository
	oauthAccountRepo      repository.OAuthAccountRepository
	userLoginSecurityRepo repository.UserLoginSecurityRepository
	passwordService       service.PasswordService
	jwtService            service.JWTService
	googleVerifier        service.GoogleVerifier
	txManager             repository.TxManager
	refreshTTL            time.Duration
}

func NewService(
	userRepo repository.UserRepository,
	refreshTokenRepo repository.RefreshTokenRepository,
	oauthAccountRepo repository.OAuthAccountRepository,
	userLoginSecurityRepo repository.UserLoginSecurityRepository,
	passwordService service.PasswordService,
	jwtService service.JWTService,
	googleVerifier service.GoogleVerifier,
	txManager repository.TxManager,
	refreshTTL time.Duration,
) *Service {
	return &Service{
		userRepo:              userRepo,
		refreshTokenRepo:      refreshTokenRepo,
		oauthAccountRepo:      oauthAccountRepo,
		userLoginSecurityRepo: userLoginSecurityRepo,
		passwordService:       passwordService,
		jwtService:            jwtService,
		googleVerifier:        googleVerifier,
		txManager:             txManager,
		refreshTTL:            refreshTTL,
	}
}

func (s *Service) Register(ctx context.Context, input dto.RegisterInput) (*dto.AuthResponse, error) {
	input.Email = validation.NormalizeEmail(input.Email)
	input.Username = validation.NormalizeUsername(input.Username)

	if err := validation.ValidateRegisterInput(input); err != nil {
		return nil, err
	}

	_, err := s.userRepo.GetByEmail(ctx, input.Email)
	if err == nil {
		return nil, authErrors.ErrEmailAlreadyExists
	}
	if !errors.Is(err, authErrors.ErrUserNotFound) {
		return nil, err
	}

	passwordHash, err := s.passwordService.Hash(input.Password)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		Email:        input.Email,
		Username:     input.Username,
		PasswordHash: passwordHash,
		IsActive:     true,
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}

	return s.issueTokens(ctx, user)
}

func (s *Service) Login(ctx context.Context, input dto.LoginInput) (*dto.AuthResponse, error) {
	input.Email = validation.NormalizeEmail(input.Email)

	if err := validation.ValidateLoginInput(input); err != nil {
		return nil, err
	}

	user, err := s.userRepo.GetByEmail(ctx, input.Email)
	if err != nil {
		if errors.Is(err, authErrors.ErrUserNotFound) {
			return nil, authErrors.ErrInvalidCredentials
		}
		return nil, err
	}

	if !user.IsActive {
		logger.Warn("login denied: user_id=%d reason=inactive_user", user.ID)
		return nil, authErrors.ErrInactiveUser
	}

	if user.PasswordHash == "" {
		return nil, authErrors.ErrInvalidCredentials
	}

	if err := s.userLoginSecurityRepo.EnsureExists(ctx, user.ID); err != nil {
		logger.Error("login failed: could not ensure login security row: user_id=%d err=%v", user.ID, err)
		return nil, err
	}

	security, err := s.userLoginSecurityRepo.GetByUserID(ctx, user.ID)
	if err != nil {
		logger.Error("login failed: could not get login security row: user_id=%d err=%v", user.ID, err)
		return nil, err
	}

	now := time.Now().UTC()
	if security.LockedUntil != nil && now.Before(*security.LockedUntil) {
		logger.Warn("login denied: user_id=%d reason=locked locked_until=%s", user.ID, security.LockedUntil.Format(time.RFC3339))
		return nil, authErrors.ErrTooManyLoginAttempts
	}

	if err := s.passwordService.Compare(user.PasswordHash, input.Password); err != nil {
		logger.Warn("login failed: user_id=%d reason=invalid_password", user.ID)
		errTx := s.txManager.WithinTransaction(ctx, func(
			userRepo repository.UserRepository,
			refreshTokenRepo repository.RefreshTokenRepository,
			oauthAccountRepo repository.OAuthAccountRepository,
			userLoginSecurityRepo repository.UserLoginSecurityRepository,
		) error {
			if err := userLoginSecurityRepo.EnsureExists(ctx, user.ID); err != nil {
				return err
			}
			security, err := userLoginSecurityRepo.IncrementFailedAttempts(ctx, user.ID)
			if err != nil {
				return err
			}

			if security.FailedAttempts >= 5 {
				lockedUntil := time.Now().UTC().Add(20 * time.Minute)
				if err := userLoginSecurityRepo.LockUntil(ctx, user.ID, lockedUntil); err != nil {
					return err
				}
				logger.Warn("login blocked: user_id=%d failed_attempts=%d locked_until=%s", user.ID, security.FailedAttempts, lockedUntil.Format(time.RFC3339))
			}

			return nil
		})
		if errTx != nil {
			logger.Error("login failed: transaction error while registering failed attempt: user_id=%d err=%v", user.ID, errTx)
			return nil, errTx
		}

		return nil, authErrors.ErrInvalidCredentials
	}

	if err := s.userLoginSecurityRepo.Reset(ctx, user.ID); err != nil {
		return nil, err
	}

	return s.issueTokens(ctx, user)
}

func (s *Service) GoogleLogin(ctx context.Context, input dto.GoogleLoginInput) (*dto.AuthResponse, error) {
	googleUser, err := s.googleVerifier.VerifyIDToken(ctx, input.IDToken)
	if err != nil {
		return nil, err
	}

	if !googleUser.EmailVerified {
		return nil, authErrors.ErrGoogleEmailNotVerified
	}

	account, err := s.oauthAccountRepo.GetByProviderAndProviderUserID(ctx, "google", googleUser.Sub)
	if err == nil {
		user, err := s.userRepo.GetByID(ctx, account.UserID)
		if err != nil {
			return nil, err
		}

		if !user.IsActive {
			return nil, authErrors.ErrInactiveUser
		}

		return s.issueTokens(ctx, user)
	}

	if !errors.Is(err, authErrors.ErrOAuthAccountNotFound) {
		return nil, err
	}

	normalizedEmail := validation.NormalizeEmail(googleUser.Email)

	existingUser, err := s.userRepo.GetByEmail(ctx, normalizedEmail)
	if err == nil && existingUser != nil {
		return nil, authErrors.ErrGoogleEmailAlreadyExists
	}
	if err != nil && !errors.Is(err, authErrors.ErrUserNotFound) {
		return nil, err
	}

	username := buildGoogleUsername(normalizedEmail, googleUser.Name)

	var createdUser *model.User

	err = s.txManager.WithinTransaction(ctx, func(
		userRepo repository.UserRepository,
		refreshTokenRepo repository.RefreshTokenRepository,
		oauthAccountRepo repository.OAuthAccountRepository,
		userLoginSecurityRepo repository.UserLoginSecurityRepository,
	) error {
		_ = refreshTokenRepo

		user := &model.User{
			Email:        normalizedEmail,
			Username:     username,
			PasswordHash: "",
			IsActive:     true,
		}

		if err := userRepo.Create(ctx, user); err != nil {
			existingAccount, getErr := oauthAccountRepo.GetByProviderAndProviderUserID(
				ctx,
				"google",
				googleUser.Sub,
			)
			if getErr != nil {
				return err
			}

			userFromAccount, getUserErr := userRepo.GetByID(ctx, existingAccount.UserID)
			if getUserErr != nil {
				return getUserErr
			}

			user = userFromAccount
		}

		newAccount := &model.OAuthAccount{
			UserID:         user.ID,
			Provider:       "google",
			ProviderUserID: googleUser.Sub,
		}

		if err := oauthAccountRepo.Create(ctx, newAccount); err != nil {
			existingAccount, getErr := oauthAccountRepo.GetByProviderAndProviderUserID(
				ctx,
				"google",
				googleUser.Sub,
			)
			if getErr != nil {
				return err
			}

			userFromAccount, getUserErr := userRepo.GetByID(ctx, existingAccount.UserID)
			if getUserErr != nil {
				return getUserErr
			}

			user = userFromAccount
		}

		createdUser = user
		return nil
	})

	if err != nil {
		return nil, err
	}

	return s.issueTokens(ctx, createdUser)
}

func (s *Service) Refresh(ctx context.Context, refreshToken string) (*dto.AuthResponse, error) {
	tokenHash := s.jwtService.HashRefreshToken(refreshToken)

	storedToken, err := s.refreshTokenRepo.GetByTokenHash(ctx, tokenHash)
	if err != nil {
		if errors.Is(err, authErrors.ErrRefreshTokenNotFound) {
			logger.Warn("refresh token rejected: reason=not_found")
			return nil, authErrors.ErrInvalidRefreshToken
		}
		logger.Error("refresh token failed: could not get token by hash: err=%v", err)
		return nil, err
	}

	if storedToken.RevokedAt != nil {
		logger.Warn("refresh token rejected: user_id=%d reason=revoked", storedToken.UserID)
		return nil, authErrors.ErrRefreshTokenRevoked
	}

	if time.Now().UTC().After(storedToken.ExpiresAt) {
		logger.Warn("refresh token rejected: user_id=%d reason=expired expires_at=%s", storedToken.UserID, storedToken.ExpiresAt.Format(time.RFC3339))
		return nil, authErrors.ErrRefreshTokenExpired
	}

	user, err := s.userRepo.GetByID(ctx, storedToken.UserID)
	if err != nil {
		return nil, err
	}

	if !user.IsActive {
		logger.Warn("refresh token denied: user_id=%d reason=inactive_user", user.ID)
		return nil, authErrors.ErrInactiveUser
	}

	if err := s.refreshTokenRepo.RevokeByTokenHash(ctx, tokenHash); err != nil {

		logger.Error("refresh token failed: could not revoke old token: user_id=%d err=%v", user.ID, err)
		return nil, err
	}

	return s.issueTokens(ctx, user)
}

func (s *Service) Logout(ctx context.Context, refreshToken string) error {
	tokenHash := s.jwtService.HashRefreshToken(refreshToken)

	storedToken, err := s.refreshTokenRepo.GetByTokenHash(ctx, tokenHash)
	if err != nil {
		if errors.Is(err, authErrors.ErrRefreshTokenNotFound) {
			logger.Warn("logout rejected: refresh token reason=not_found")
			return authErrors.ErrInvalidRefreshToken
		}
		logger.Error("logout failed: could not get refresh token by hash: err=%v", err)
		return err
	}

	if storedToken.RevokedAt != nil {

		logger.Warn("logout rejected: user_id=%d refresh token reason=revoked", storedToken.UserID)
		return authErrors.ErrRefreshTokenRevoked
	}

	if time.Now().UTC().After(storedToken.ExpiresAt) {

		logger.Warn("logout rejected: user_id=%d refresh token reason=expired expires_at=%s", storedToken.UserID, storedToken.ExpiresAt.Format(time.RFC3339))
		return authErrors.ErrRefreshTokenExpired
	}

	if err := s.refreshTokenRepo.RevokeByTokenHash(ctx, tokenHash); err != nil {

		logger.Error("logout failed: could not revoke refresh token: user_id=%d err=%v", storedToken.UserID, err)
		return err
	}

	return nil
}

func (s *Service) Me(ctx context.Context, userID int64) (*dto.UserResponse, error) {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	return &dto.UserResponse{
		ID:       user.ID,
		Email:    user.Email,
		Username: user.Username,
		IsActive: user.IsActive,
	}, nil
}

func (s *Service) ChangeUsername(ctx context.Context, userID int64, input dto.ChangeUsernameInput) (*dto.UserResponse, error) {
	newUsername := validation.NormalizeUsername(input.NewUsername)

	if err := validation.ValidateUsername(newUsername); err != nil {
		return nil, err
	}

	var updatedUser *model.User

	err := s.txManager.WithinTransaction(ctx, func(
		userRepo repository.UserRepository,
		refreshTokenRepo repository.RefreshTokenRepository,
		oauthAccountRepo repository.OAuthAccountRepository,
		userLoginSecurityRepo repository.UserLoginSecurityRepository,
	) error {
		_ = refreshTokenRepo
		_ = oauthAccountRepo

		user, err := userRepo.GetByID(ctx, userID)
		if err != nil {
			return err
		}

		if user.Username == newUsername {
			return authErrors.ErrUsernameSameAsCurrent
		}

		if err := userRepo.UpdateUsername(ctx, userID, newUsername); err != nil {
			return err
		}

		user.Username = newUsername
		updatedUser = user
		return nil
	})
	if err != nil {
		return nil, err
	}

	return &dto.UserResponse{
		ID:       updatedUser.ID,
		Email:    updatedUser.Email,
		Username: updatedUser.Username,
		IsActive: updatedUser.IsActive,
	}, nil
}

func (s *Service) ChangePassword(ctx context.Context, userID int64, input dto.ChangePasswordInput) error {
	if strings.TrimSpace(input.RefreshToken) == "" {
		return authErrors.ErrInvalidRefreshToken
	}

	if strings.TrimSpace(input.CurrentPassword) == "" {
		return authErrors.ErrInvalidCredentials
	}

	if err := validation.ValidatePassword(input.NewPassword); err != nil {
		return err
	}

	currentTokenHash := s.jwtService.HashRefreshToken(input.RefreshToken)

	return s.txManager.WithinTransaction(ctx, func(
		userRepo repository.UserRepository,
		refreshTokenRepo repository.RefreshTokenRepository,
		oauthAccountRepo repository.OAuthAccountRepository,
		userLoginSecurityRepo repository.UserLoginSecurityRepository,
	) error {
		_ = oauthAccountRepo

		user, err := userRepo.GetByID(ctx, userID)
		if err != nil {
			return err
		}

		if user.PasswordHash == "" {
			return authErrors.ErrInvalidCredentials
		}

		if err := s.passwordService.Compare(user.PasswordHash, input.CurrentPassword); err != nil {
			return authErrors.ErrInvalidCredentials
		}

		if input.CurrentPassword == input.NewPassword {
			return authErrors.ErrPasswordSameAsCurrent
		}

		currentToken, err := refreshTokenRepo.GetByTokenHash(ctx, currentTokenHash)
		if err != nil {
			if errors.Is(err, authErrors.ErrRefreshTokenNotFound) {
				return authErrors.ErrInvalidRefreshToken
			}
			return err
		}

		if currentToken.UserID != userID {
			return authErrors.ErrInvalidRefreshToken
		}

		if currentToken.RevokedAt != nil {
			return authErrors.ErrRefreshTokenRevoked
		}

		if time.Now().UTC().After(currentToken.ExpiresAt) {
			return authErrors.ErrRefreshTokenExpired
		}

		newPasswordHash, err := s.passwordService.Hash(input.NewPassword)
		if err != nil {
			return err
		}

		if err := userRepo.UpdatePasswordHash(ctx, userID, newPasswordHash); err != nil {
			return err
		}

		if err := refreshTokenRepo.RevokeAllByUserIDExceptTokenHash(ctx, userID, currentTokenHash); err != nil {
			return err
		}

		return nil
	})
}

func (s *Service) issueTokens(ctx context.Context, user *model.User) (*dto.AuthResponse, error) {
	accessToken, err := s.jwtService.GenerateAccessToken(user.ID, user.Email, user.Username)
	if err != nil {
		return nil, err
	}

	refreshToken, err := s.jwtService.GenerateRefreshToken()
	if err != nil {
		return nil, err
	}

	refreshTokenModel := &model.RefreshToken{
		UserID:    user.ID,
		TokenHash: s.jwtService.HashRefreshToken(refreshToken),
		ExpiresAt: time.Now().UTC().Add(s.refreshTTL),
	}

	if err := s.refreshTokenRepo.Create(ctx, refreshTokenModel); err != nil {
		return nil, err
	}

	return &dto.AuthResponse{
		User: dto.UserResponse{
			ID:       user.ID,
			Email:    user.Email,
			Username: user.Username,
			IsActive: user.IsActive,
		},
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func buildGoogleUsername(email, name string) string {
	username := validation.NormalizeUsername(name)

	if isValidGoogleUsername(username) {
		return username
	}

	base := strings.Split(email, "@")[0]
	base = validation.NormalizeUsername(base)

	if isValidGoogleUsername(base) {
		return base
	}

	return "google_user"
}

func isValidGoogleUsername(username string) bool {
	if username == "" {
		return false
	}

	length := utf8.RuneCountInString(username)
	if length < 2 || length > 20 {
		return false
	}

	if err := validation.ValidateUsername(username); err != nil {
		return false
	}

	return true
}

func (s *Service) DeleteAccount(ctx context.Context, userID int64) error {
	if err := s.userRepo.DeleteByID(ctx, userID); err != nil {
		logger.Error("auth service: failed to delete account: user_id=%d err=%v", userID, err)
		return err
	}
	return nil
}
