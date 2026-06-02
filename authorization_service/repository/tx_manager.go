package repository

import "context"

type TxManager interface {
	WithinTransaction(
		ctx context.Context,
		fn func(
			userRepo UserRepository,
			refreshTokenRepo RefreshTokenRepository,
			oauthAccountRepo OAuthAccountRepository,
			userLoginSecurityRepo UserLoginSecurityRepository,
		) error,
	) error
}
