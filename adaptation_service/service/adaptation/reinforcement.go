package adaptation

import (
	"context"

	"diplomaBackend/adaptation_service/dto"
	adaptationErrors "diplomaBackend/adaptation_service/errors"
	"diplomaBackend/adaptation_service/model"
	"diplomaBackend/adaptation_service/repository"
	"diplomaBackend/adaptation_service/service"
	"diplomaBackend/internal/logger"
	"diplomaBackend/internal/mlclient"
)

type Service struct {
	adaptationRepo repository.AdaptationRepository
	mlClient       mlclient.Client
}

const (
	quizTypeSubtopicQuiz   = "subtopic_quiz"
	quizTypeTopicFinalQuiz = "topic_final_quiz"

	subtopicPassedThreshold      = 70.0
	topicFinalPassedThreshold    = 75.0
	topicAvgLast3PassedThreshold = 70.0
)

func NewService(
	adaptationRepo repository.AdaptationRepository,
	mlClient mlclient.Client,
) service.AdaptationService {
	return &Service{
		adaptationRepo: adaptationRepo,
		mlClient:       mlClient,
	}
}

func (s *Service) ProcessQuizResult(ctx context.Context, input service.ProcessQuizResultInput) (*dto.ReinforcementResponse, error) {
	if input.UserID <= 0 {
		return nil, adaptationErrors.ErrInvalidUserID
	}

	if input.AttemptID <= 0 {
		return nil, adaptationErrors.ErrInvalidAttemptID
	}
	features, err := s.adaptationRepo.GetReinforcementFeatures(ctx, input.UserID, input.AttemptID)
	if err != nil {
		return nil, err
	}

	result := fallbackReinforcement(features)

	if err := s.savePrediction(ctx, input, features, result); err != nil {
		logger.Error(
			"adaptation service: failed to save reinforcement prediction: user_id=%d attempt_id=%d err=%v",
			input.UserID,
			input.AttemptID,
			err,
		)
	}

	return result, nil
}

func isStrongResult(features *model.ReinforcementFeatures) bool {
	if features == nil {
		return false
	}

	switch features.QuizType {
	case quizTypeTopicFinalQuiz:
		return features.QuizScore >= topicFinalPassedThreshold &&
			features.AvgLast3Scores >= topicAvgLast3PassedThreshold

	case quizTypeSubtopicQuiz:
		return features.QuizScore >= subtopicPassedThreshold

	default:
		return features.QuizScore >= subtopicPassedThreshold
	}
}

func fallbackReinforcement(features *model.ReinforcementFeatures) *dto.ReinforcementResponse {
	needs := !isStrongResult(features)

	prediction := 0
	if needs {
		prediction = 1
	}

	return &dto.ReinforcementResponse{
		NeedsReinforcement: needs,
		Prediction:         prediction,
		Probability:        0,
		Confidence:         0,
		DecisionSource:     "fallback_rule",
		ModelName:          "rule_based",
	}
}

func (s *Service) savePrediction(
	ctx context.Context,
	input service.ProcessQuizResultInput,
	features *model.ReinforcementFeatures,
	result *dto.ReinforcementResponse,
) error {
	if result == nil {
		return nil
	}

	return s.adaptationRepo.SaveReinforcementPrediction(ctx, &model.ReinforcementPrediction{
		UserID:    input.UserID,
		QuizID:    input.QuizID,
		AttemptID: input.AttemptID,

		QuizType:     features.QuizType,
		TopicCode:    features.TopicCode,
		SubtopicCode: features.SubtopicCode,

		ScorePercent:   features.QuizScore,
		AvgLast3Scores: features.AvgLast3Scores,

		NeedsReinforcement: result.NeedsReinforcement,
		Prediction:         result.Prediction,
		Probability:        result.Probability,
		Confidence:         result.Confidence,

		DecisionSource: result.DecisionSource,
		ModelName:      result.ModelName,
		ModelVersion:   "",
	})
}
