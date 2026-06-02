package repository

import (
	"context"

	"diplomaBackend/progress_service/dto"
	"diplomaBackend/progress_service/model"
)

type ProgressRepository interface {
	EnsureUserProgress(ctx context.Context, userID int64) error

	GetQuizProgress(ctx context.Context, userID int64, quizCode string) (*model.UserQuizProgress, error)
	CreateQuizProgress(ctx context.Context, progress *model.UserQuizProgress) error
	UpdateQuizProgressAttemptOnly(ctx context.Context, userID int64, quizCode string, completedAt string) error
	UpdateQuizProgressBest(ctx context.Context, progress *model.UserQuizProgress, completedAt string) error

	AddXP(ctx context.Context, userID int64, xpDelta int) error

	RecalculateLearningStats(ctx context.Context, userID int64) error

	GetUserProgress(ctx context.Context, userID int64) (*model.UserProgress, error)
	GetLearningStats(ctx context.Context, userID int64) (*model.UserLearningStats, error)
	GetCompletedTopicCodes(ctx context.Context, userID int64) ([]string, error)
	GetTopicSubtopicProgress(ctx context.Context, userID int64) (map[string]dto.TopicProgressDetail, error)
}
