package repository

import (
	"context"

	"diplomaBackend/adaptation_service/model"
)

type AdaptationRepository interface {
	GetReinforcementFeatures(ctx context.Context, userID, attemptID int64) (*model.ReinforcementFeatures, error)
	SaveReinforcementPrediction(ctx context.Context, prediction *model.ReinforcementPrediction) error
	GetRecommendationUserData(ctx context.Context, userID int64) (*model.RecommendationUserData, error)
	ListLearningMapSubtopics(ctx context.Context, languageCode string) ([]model.CandidateSubtopic, error)
	GetUserSubtopicProgressMap(ctx context.Context, userID int64) (map[string]model.UserSubtopicProgress, error)
	GetLatestActiveReinforcement(ctx context.Context, userID int64) (*model.ActiveReinforcement, error)
}
