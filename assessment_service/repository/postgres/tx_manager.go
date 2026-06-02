package postgres

import (
	"context"
	"log"

	"diplomaBackend/assessment_service/repository"

	"github.com/jackc/pgx/v5/pgxpool"
)

type TxManager struct {
	pool *pgxpool.Pool
}

func NewTxManager(pool *pgxpool.Pool) *TxManager {
	return &TxManager{pool: pool}
}

func (m *TxManager) WithinTransaction(ctx context.Context, fn func(assessmentRepo repository.AssessmentRepository) error) error {
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

	assessmentRepo := NewAssessmentRepository(tx)

	err = fn(assessmentRepo)
	if err != nil {
		return err
	}

	err = tx.Commit(ctx)
	if err != nil {
		return err
	}

	return nil
}
