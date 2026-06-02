package postgres

import (
	"context"
	"diplomaBackend/user_profile_service/repository"
	"log"

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
	fn func(
		profileRepo repository.ProfileRepository,
		preferredTopicRepo repository.PreferredTopicRepository,
		settingsRepo repository.SettingsRepository,
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

	profileRepo := NewProfileRepository(tx)
	preferredTopicRepo := NewPreferredTopicRepository(tx)
	settingsRepo := NewSettingsRepository(tx)

	err = fn(profileRepo, preferredTopicRepo, settingsRepo)
	if err != nil {
		return err
	}
	err = tx.Commit(ctx)
	if err != nil {
		return err
	}

	return nil
}
