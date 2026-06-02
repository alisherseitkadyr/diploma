package repository

import "context"

type TxManager interface {
	WithinTransaction(ctx context.Context, fn func(assessmentRepo AssessmentRepository) error) error
}
