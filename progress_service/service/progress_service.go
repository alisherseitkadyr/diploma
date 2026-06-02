package service

import (
	"context"

	"diplomaBackend/progress_service/dto"
)

type ProgressService interface {
	ProcessQuizResult(ctx context.Context, input ProcessQuizResultInput) error
	GetProgressOverview(ctx context.Context, userID int64) (*dto.ProgressOverviewResponse, error)
}
