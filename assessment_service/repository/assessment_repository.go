package repository

import (
	"context"

	"diplomaBackend/assessment_service/dto"
	"diplomaBackend/assessment_service/model"
)

type AssessmentRepository interface {
	GetQuizByID(ctx context.Context, quizID int64, languageCode string) (*dto.QuizResponse, error)
	GetQuizStartMeta(ctx context.Context, quizID int64, languageCode string) (*model.QuizStartMeta, error)
	GetRandomQuestionsByQuizID(ctx context.Context, quizID int64, languageCode string, limit int) ([]dto.QuestionResponse, error)
	GetSubtopicQuizInfoByTopicCode(ctx context.Context, topicCode string) ([]model.SubtopicQuizInfo, error)
	CreateStartedAttempt(ctx context.Context, attempt *model.QuizAttempt) error
	CreateAttemptQuestions(ctx context.Context, attemptID int64, questions []dto.QuestionResponse) error
	GetAttemptCheckData(ctx context.Context, userID, attemptID int64) (*model.AttemptCheckData, error)
	CompleteAttempt(ctx context.Context, attempt *model.QuizAttempt) error
	CreateAttemptAnswers(ctx context.Context, answers []model.QuizAttemptAnswer) error
	GetLatestAttemptByQuizID(ctx context.Context, userID, quizID int64) (*dto.AttemptSummaryResponse, error)
	GetAttemptByID(ctx context.Context, userID, attemptID int64) (*dto.AttemptDetailResponse, error)
	GetAttemptAnswers(ctx context.Context, attemptID int64, languageCode string) ([]dto.AttemptAnswerDetails, error)
	ExpireAttemptIfNeeded(ctx context.Context, userID, attemptID int64) (bool, error)
}
