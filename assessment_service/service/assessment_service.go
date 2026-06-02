package service

import (
	"context"

	"diplomaBackend/assessment_service/dto"
)

type AssessmentService interface {
	GetQuizByID(ctx context.Context, quizID int64, languageCode string) (*dto.QuizResponse, error)
	StartQuiz(ctx context.Context, userID, quizID int64, languageCode string) (*dto.StartQuizResponse, error)
	SubmitAttempt(ctx context.Context, input SubmitQuizInput) (*dto.SubmitQuizResponse, error)
	GetLatestAttemptByQuizID(ctx context.Context, userID, quizID int64) (*dto.LatestAttemptResponse, error)
	GetAttemptByID(ctx context.Context, userID, attemptID int64, languageCode string) (*dto.AttemptDetailResponse, error)
}
