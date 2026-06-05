package adaptation

import (
	"context"
	"sort"

	"diplomaBackend/adaptation_service/dto"
	adaptationErrors "diplomaBackend/adaptation_service/errors"
	"diplomaBackend/adaptation_service/model"
	"diplomaBackend/internal/logger"
	"diplomaBackend/internal/mlclient"
)

func (s *Service) GetRepetitionReview(ctx context.Context, userID int64) (*dto.RepetitionReviewResponse, error) {
	if userID <= 0 {
		return nil, adaptationErrors.ErrInvalidUserID
	}

	userData, err := s.adaptationRepo.GetRecommendationUserData(ctx, userID)
	if err != nil {
		return nil, err
	}

	candidates, err := s.adaptationRepo.GetRepetitionCandidates(ctx, userID)
	if err != nil {
		return nil, err
	}

	if len(candidates) == 0 {
		return &dto.RepetitionReviewResponse{Items: []dto.RepetitionItemResponse{}}, nil
	}

	if s.mlClient == nil {
		return fallbackRepetitionReview(candidates), nil
	}

	req := buildRepetitionRankRequest(userData, candidates)

	res, err := s.mlClient.RankRepetition(ctx, req)
	if err != nil {
		logger.Error("adaptation service: repetition ML call failed: user_id=%d err=%v", userID, err)
		return fallbackRepetitionReview(candidates), nil
	}

	items := make([]dto.RepetitionItemResponse, 0, len(res.Items))
	for _, item := range res.Items {
		items = append(items, dto.RepetitionItemResponse{
			ConceptCode:                item.ConceptCode,
			TopicCode:                  item.TopicCode,
			RecallProbability:          item.RecallProbability,
			PriorityScore:              item.PriorityScore,
			ReviewAction:               item.ReviewAction,
			RecommendedReviewDelayDays: item.RecommendedReviewDelayDays,
		})
	}

	return &dto.RepetitionReviewResponse{
		Items:        items,
		ModelName:    res.ModelName,
		ModelVersion: res.ModelVersion,
	}, nil
}

func buildRepetitionRankRequest(userData *model.RecommendationUserData, candidates []model.RepetitionCandidate) mlclient.RepetitionRankRequest {
	userSkillIndex := userData.AverageBestScorePercent
	if userSkillIndex == 0 && userData.CompletedSubtopicsCount == 0 {
		userSkillIndex = 25.0
	}

	items := make([]mlclient.RepetitionRankItem, 0, len(candidates))
	for _, c := range candidates {
		diffIndex := topicDifficultyIndex(c.TopicLevel, c.TopicOrderIndex)
		recallSuccessRate := c.BestScorePercent / 100.0
		if recallSuccessRate > 1.0 {
			recallSuccessRate = 1.0
		}

		topicCode := c.TopicCode
		items = append(items, mlclient.RepetitionRankItem{
			ConceptCode:            c.SubtopicCode,
			TopicCode:              &topicCode,
			UserSkillIndex:         userSkillIndex,
			ConceptDifficultyIndex: diffIndex,
			DaysSinceLastReview:    c.DaysSinceLastReview,
			ReviewCount:            c.AttemptsCount,
			RecallSuccessRate:      recallSuccessRate,
			LastRecallCorrect:      1,
			AverageLatencySeconds:  30.0,
		})
	}

	return mlclient.RepetitionRankRequest{Items: items}
}

func fallbackRepetitionReview(candidates []model.RepetitionCandidate) *dto.RepetitionReviewResponse {
	sorted := make([]model.RepetitionCandidate, len(candidates))
	copy(sorted, candidates)
	sort.SliceStable(sorted, func(i, j int) bool {
		return sorted[i].DaysSinceLastReview > sorted[j].DaysSinceLastReview
	})

	items := make([]dto.RepetitionItemResponse, 0, len(sorted))
	for _, c := range sorted {
		action, delayDays := fallbackReviewAction(c.DaysSinceLastReview)
		topicCode := c.TopicCode
		items = append(items, dto.RepetitionItemResponse{
			ConceptCode:                c.SubtopicCode,
			TopicCode:                  &topicCode,
			RecallProbability:          0,
			PriorityScore:              0,
			ReviewAction:               action,
			RecommendedReviewDelayDays: delayDays,
		})
	}

	return &dto.RepetitionReviewResponse{Items: items, ModelName: "fallback_rule"}
}

func fallbackReviewAction(daysSinceLastReview float64) (string, int) {
	if daysSinceLastReview >= 7 {
		return "review_now", 0
	}
	if daysSinceLastReview >= 3 {
		return "review_soon", 1
	}
	return "not_urgent", 3
}
