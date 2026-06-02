package postgres

import (
	"context"
	"log"

	"diplomaBackend/authorization_service/repository"

	"github.com/jackc/pgx/v5/pgxpool"
)

type TxManager struct {
	pool *pgxpool.Pool
}

func NewTxManager(pool *pgxpool.Pool) *TxManager {
	return &TxManager{pool: pool}
}

func (m *TxManager) WithinTransaction(
	ctx context.Context,
	fn func(userRepo repository.UserRepository, refreshTokenRepo repository.RefreshTokenRepository,
		oauthAccountRepo repository.OAuthAccountRepository, userLoginSecurityRepo repository.UserLoginSecurityRepository,
	) error,
) error {
	tx, err := m.pool.Begin(ctx)
	if err != nil {
		return err
	}

	defer func() {
		if err != nil {
			log.Println("rollback because of error:", err)
		}
		_ = tx.Rollback(ctx)
	}()

	userRepo := NewUserRepository(tx)
	refreshTokenRepo := NewRefreshTokenRepository(tx)
	oauthAccountRepo := NewOAuthAccountRepository(tx)
	userLoginSecurityRepo := NewUserLoginSecurityRepository(tx)

	err = fn(userRepo, refreshTokenRepo, oauthAccountRepo, userLoginSecurityRepo)
	if err != nil {
		return err
	}

	err = tx.Commit(ctx)
	if err != nil {
		return err
	}

	return nil
}
