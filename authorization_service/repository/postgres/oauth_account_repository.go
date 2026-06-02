package postgres

import (
	"context"
	postgres2 "diplomaBackend/internal/storage/postgres"
	"errors"

	authErrors "diplomaBackend/authorization_service/errors"
	"diplomaBackend/authorization_service/model"

	"github.com/jackc/pgx/v5"
)

type OAuthAccountRepository struct {
	db postgres2.DBTX
}

func NewOAuthAccountRepository(db postgres2.DBTX) *OAuthAccountRepository {
	return &OAuthAccountRepository{db: db}
}

func (r *OAuthAccountRepository) Create(ctx context.Context, account *model.OAuthAccount) error {
	query := `
		INSERT INTO oauth_accounts (user_id, provider, provider_user_id)
		VALUES ($1, $2, $3)
		RETURNING id, created_at
	`

	err := r.db.QueryRow(ctx, query,
		account.UserID,
		account.Provider,
		account.ProviderUserID,
	).Scan(&account.ID, &account.CreatedAt)
	if err != nil {
		return err
	}

	return nil
}

func (r *OAuthAccountRepository) GetByProviderAndProviderUserID(
	ctx context.Context,
	provider, providerUserID string,
) (*model.OAuthAccount, error) {
	query := `
		SELECT id, user_id, provider, provider_user_id, created_at
		FROM oauth_accounts
		WHERE provider = $1 AND provider_user_id = $2
	`

	var account model.OAuthAccount
	err := r.db.QueryRow(ctx, query, provider, providerUserID).Scan(
		&account.ID,
		&account.UserID,
		&account.Provider,
		&account.ProviderUserID,
		&account.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, authErrors.ErrOAuthAccountNotFound
		}
		return nil, err
	}

	return &account, nil
}
