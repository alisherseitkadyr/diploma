package repository

import (
	"context"

	"diplomaBackend/authorization_service/model"
)

type OAuthAccountRepository interface {
	Create(ctx context.Context, account *model.OAuthAccount) error
	GetByProviderAndProviderUserID(ctx context.Context, provider, providerUserID string) (*model.OAuthAccount, error)
}
