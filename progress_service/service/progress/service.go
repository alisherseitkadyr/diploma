package progress

import (
	"context"
	"time"

	"diplomaBackend/internal/logger"
	"diplomaBackend/progress_service/dto"
	progressErrors "diplomaBackend/progress_service/errors"
	"diplomaBackend/progress_service/model"
	"diplomaBackend/progress_service/repository"
	progressService "diplomaBackend/progress_service/service"
)

type Service struct {
	repo repository.ProgressRepository
}

func NewService(repo repository.ProgressRepository) progressService.ProgressService {
	return &Service{
		repo: repo,
	}
}

func (s *Service) ProcessQuizResult(ctx context.Context, input progressService.ProcessQuizResultInput) error {
	if input.UserID <= 0 {
		return progressErrors.ErrInvalidUserID
	}

	if input.QuizCode == "" {
		return progressErrors.ErrInvalidQuizCode
	}

	if input.MaxScorePoints <= 0 {
		return progressErrors.ErrInvalidMaxScorePoints
	}

	if input.ScorePoints < 0 || input.ScorePoints > input.MaxScorePoints {
		return progressErrors.ErrInvalidScorePoints
	}

	if input.ScorePercent < 0 || input.ScorePercent > 100 {
		return progressErrors.ErrInvalidScorePercent
	}

	if input.CompletedAt.IsZero() {
		input.CompletedAt = time.Now()
	}

	newEarnedXP := CalculateQuizXP(input.QuizType, input.ScorePercent)

	if err := s.repo.EnsureUserProgress(ctx, input.UserID); err != nil {
		logger.Error("progress service: failed to ensure user progress: user_id=%d err=%v", input.UserID, err)
		return err
	}

	current, err := s.repo.GetQuizProgress(ctx, input.UserID, input.QuizCode)
	if err != nil {
		logger.Error("progress service: failed to get quiz progress: user_id=%d quiz_code=%s err=%v", input.UserID, input.QuizCode, err)
		return err
	}

	completedAt := input.CompletedAt.Format(time.RFC3339Nano)

	if current == nil {
		quizProgress := &model.UserQuizProgress{
			UserID:           input.UserID,
			QuizCode:         input.QuizCode,
			QuizType:         input.QuizType,
			TopicCode:        input.TopicCode,
			SubtopicCode:     input.SubtopicCode,
			BestScorePoints:  input.ScorePoints,
			MaxScorePoints:   input.MaxScorePoints,
			BestScorePercent: input.ScorePercent,
			EarnedXP:         newEarnedXP,
			AttemptsCount:    1,
		}

		if err := s.repo.CreateQuizProgress(ctx, quizProgress); err != nil {
			logger.Error("progress service: failed to create quiz progress: user_id=%d quiz_code=%s err=%v", input.UserID, input.QuizCode, err)
			return err
		}

		if newEarnedXP > 0 {
			if err := s.repo.AddXP(ctx, input.UserID, newEarnedXP); err != nil {
				logger.Error("progress service: failed to add xp: user_id=%d xp_delta=%d err=%v", input.UserID, newEarnedXP, err)
				return err
			}
		}

		return s.recalculateStats(ctx, input.UserID)
	}

	xpDelta := 0
	if newEarnedXP > current.EarnedXP {
		xpDelta = newEarnedXP - current.EarnedXP
	}

	if input.ScorePercent > current.BestScorePercent {
		updated := &model.UserQuizProgress{
			UserID:           input.UserID,
			QuizCode:         input.QuizCode,
			QuizType:         input.QuizType,
			TopicCode:        input.TopicCode,
			SubtopicCode:     input.SubtopicCode,
			BestScorePoints:  input.ScorePoints,
			MaxScorePoints:   input.MaxScorePoints,
			BestScorePercent: input.ScorePercent,
			EarnedXP:         maxInt(current.EarnedXP, newEarnedXP),
		}

		if err := s.repo.UpdateQuizProgressBest(ctx, updated, completedAt); err != nil {
			logger.Error("progress service: failed to update best quiz progress: user_id=%d quiz_code=%s err=%v", input.UserID, input.QuizCode, err)
			return err
		}
	} else {
		if err := s.repo.UpdateQuizProgressAttemptOnly(ctx, input.UserID, input.QuizCode, completedAt); err != nil {
			logger.Error("progress service: failed to update quiz attempt count: user_id=%d quiz_code=%s err=%v", input.UserID, input.QuizCode, err)
			return err
		}
	}

	if xpDelta > 0 {
		if err := s.repo.AddXP(ctx, input.UserID, xpDelta); err != nil {
			logger.Error("progress service: failed to add xp delta: user_id=%d xp_delta=%d err=%v", input.UserID, xpDelta, err)
			return err
		}
	}

	return s.recalculateStats(ctx, input.UserID)
}

func (s *Service) GetProgressOverview(ctx context.Context, userID int64) (*dto.ProgressOverviewResponse, error) {
	if userID <= 0 {
		return nil, progressErrors.ErrInvalidUserID
	}
	if err := s.repo.EnsureUserProgress(ctx, userID); err != nil {
		return nil, err
	}

	if err := s.repo.RecalculateLearningStats(ctx, userID); err != nil {
		return nil, err
	}

	userProgress, err := s.repo.GetUserProgress(ctx, userID)
	if err != nil {
		return nil, err
	}

	stats, err := s.repo.GetLearningStats(ctx, userID)
	if err != nil {
		return nil, err
	}

	completedTopics, err := s.repo.GetCompletedTopicCodes(ctx, userID)
	if err != nil {
		return nil, err
	}

	topicProgress, err := s.repo.GetTopicSubtopicProgress(ctx, userID)
	if err != nil {
		return nil, err
	}

	return &dto.ProgressOverviewResponse{
		CompletedTopics: completedTopics,
		Progress: dto.ProgressResponse{
			TotalXP:        userProgress.TotalXP,
			ProgressLevel:  userProgress.ProgressLevel,
			LastActivityAt: userProgress.LastActivityAt,
			Topics:         topicProgress,
		},
		Stats: dto.LearningStatsResponse{
			TotalQuizAttempts:               stats.TotalQuizAttempts,
			CompletedQuizzesCount:           stats.CompletedQuizzesCount,
			CompletedSubtopicQuizzesCount:   stats.CompletedSubtopicQuizzesCount,
			CompletedTopicFinalQuizzesCount: stats.CompletedTopicFinalQuizzesCount,
			CompletedSubtopicsCount:         stats.CompletedSubtopicsCount,
			CompletedTopicsCount:            stats.CompletedTopicsCount,
			AverageBestScorePercent:         stats.AverageBestScorePercent,
			AverageAllAttemptsScorePercent:  stats.AverageAllAttemptsScorePercent,
			MaxScoreQuizzesCount:            stats.MaxScoreQuizzesCount,
			BestTopicCode:                   stats.BestTopicCode,
			WeakestTopicCode:                stats.WeakestTopicCode,
			LastQuizCompletedAt:             stats.LastQuizCompletedAt,
		},
	}, nil
}

func (s *Service) recalculateStats(ctx context.Context, userID int64) error {
	if err := s.repo.RecalculateLearningStats(ctx, userID); err != nil {
		logger.Error("progress service: failed to recalculate learning stats: user_id=%d err=%v", userID, err)
		return err
	}

	return nil
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}

	return b
}
