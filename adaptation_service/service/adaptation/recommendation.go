package adaptation

import (
	"context"
	"errors"
	"sort"

	"diplomaBackend/adaptation_service/dto"
	adaptationErrors "diplomaBackend/adaptation_service/errors"
	"diplomaBackend/adaptation_service/model"
	"diplomaBackend/internal/logger"
	"diplomaBackend/internal/mlclient"
)

const (
	homeStateHasRecommendations = "HAS_RECOMMENDATIONS"
	homeStateAllCompleted       = "ALL_COMPLETED"

	actionTypeNeedsReinforcement = "NEEDS_REINFORCEMENT"
	actionTypeNextLesson         = "NEXT_LESSON"

	statusCompleted          = "COMPLETED"
	statusNeedsReinforcement = "NEEDS_REINFORCEMENT"
	statusRecommended        = "RECOMMENDED"
	statusInProgress         = "IN_PROGRESS"
	statusAvailable          = "AVAILABLE"

	reasonNeedsReinforcement = "NEEDS_REINFORCEMENT"
	reasonNextBestLesson     = "NEXT_BEST_LESSON"
	reasonNextLogicalStep    = "NEXT_LOGICAL_STEP"
	reasonMatchesInterest    = "MATCHES_USER_INTEREST"
	reasonMatchesLevel       = "MATCHES_USER_LEVEL"

	topRecommendationsLimit = 3
	totalSubtopicsCount     = 25
)

type rankedCandidate struct {
	Candidate model.CandidateSubtopic
	Score     float64
	Reason    string
}

type personalizationData struct {
	UserData      *model.RecommendationUserData
	Subtopics     []model.CandidateSubtopic
	ProgressMap   map[string]model.UserSubtopicProgress
	Reinforcement *model.ActiveReinforcement
	Recommended   []rankedCandidate
}

func (s *Service) GetHomeRecommendations(ctx context.Context, userID int64, languageCode string) (*dto.HomeRecommendationsResponse, error) {
	if userID <= 0 {
		return nil, adaptationErrors.ErrInvalidUserID
	}

	data, err := s.buildPersonalizationData(ctx, userID, languageCode)
	if err != nil {
		return nil, err
	}

	if data.Reinforcement == nil && len(data.Recommended) == 0 {
		return &dto.HomeRecommendationsResponse{
			State:       homeStateAllCompleted,
			Recommended: []dto.RecommendedSubtopicResponse{},
		}, nil
	}

	recommended := toRecommendedResponses(data.Recommended)

	res := &dto.HomeRecommendationsResponse{
		State:       homeStateHasRecommendations,
		Recommended: recommended,
	}

	if data.Reinforcement != nil {
		reinforcementSubtopic := findSubtopicByCode(data.Subtopics, data.Reinforcement.SubtopicCode)
		if reinforcementSubtopic != nil {
			res.ContinueLearning = &dto.RecommendationActionResponse{
				Type:         actionTypeNeedsReinforcement,
				TopicCode:    reinforcementSubtopic.TopicCode,
				SubtopicCode: reinforcementSubtopic.SubtopicCode,
				Title:        reinforcementSubtopic.SubtopicTitle,
				ReasonType:   reasonNeedsReinforcement,
				Score:        nil,
			}
		}

		if len(data.Recommended) > 0 {
			res.NextRecommended = rankedToAction(data.Recommended[0])
		}

		return res, nil
	}

	if len(data.Recommended) > 0 {
		res.ContinueLearning = rankedToAction(data.Recommended[0])
	}

	return res, nil
}

func (s *Service) GetLearningMap(ctx context.Context, userID int64, languageCode string) (*dto.LearningMapResponse, error) {
	if userID <= 0 {
		return nil, adaptationErrors.ErrInvalidUserID
	}

	data, err := s.buildPersonalizationData(ctx, userID, languageCode)
	if err != nil {
		return nil, err
	}

	recommendedSet := rankedSet(data.Recommended)
	topicMap := make(map[string]*dto.LearningMapTopicResponse)
	topicOrder := make([]string, 0)

	for _, subtopic := range data.Subtopics {
		status := resolveSubtopicStatus(subtopic, data.ProgressMap, data.Reinforcement, recommendedSet)

		topic, ok := topicMap[subtopic.TopicCode]
		if !ok {
			topic = &dto.LearningMapTopicResponse{
				Code:       subtopic.TopicCode,
				Title:      subtopic.TopicTitle,
				Level:      subtopic.TopicLevel,
				OrderIndex: subtopic.TopicOrderIndex,
				Status:     statusAvailable,
			}
			topicMap[subtopic.TopicCode] = topic
			topicOrder = append(topicOrder, subtopic.TopicCode)
		}

		topic.TotalSubtopics++

		switch status {
		case statusCompleted:
			topic.CompletedSubtopics++
		case statusRecommended:
			topic.RecommendedSubtopics++
		case statusNeedsReinforcement:
			topic.NeedsReinforcementSubtopics++
		}
	}

	res := &dto.LearningMapResponse{
		Topics: make([]dto.LearningMapTopicResponse, 0, len(topicOrder)),
	}

	for _, topicCode := range topicOrder {
		topic := topicMap[topicCode]
		topic.Status = resolveTopicStatus(
			topic.TotalSubtopics,
			topic.CompletedSubtopics,
			topic.RecommendedSubtopics,
			topic.NeedsReinforcementSubtopics,
		)
		res.Topics = append(res.Topics, *topic)
	}

	return res, nil
}

func (s *Service) GetTopicLearningMap(ctx context.Context, userID int64, topicCode, languageCode string) (*dto.TopicLearningMapResponse, error) {
	if userID <= 0 {
		return nil, adaptationErrors.ErrInvalidUserID
	}

	if topicCode == "" {
		return nil, adaptationErrors.ErrTopicNotFound
	}

	data, err := s.buildPersonalizationData(ctx, userID, languageCode)
	if err != nil {
		return nil, err
	}

	recommendedSet := rankedSet(data.Recommended)

	topicSubtopics := make([]model.CandidateSubtopic, 0)
	for _, subtopic := range data.Subtopics {
		if subtopic.TopicCode == topicCode {
			topicSubtopics = append(topicSubtopics, subtopic)
		}
	}

	if len(topicSubtopics) == 0 {
		return nil, adaptationErrors.ErrTopicNotFound
	}

	sort.SliceStable(topicSubtopics, func(i, j int) bool {
		return topicSubtopics[i].SubtopicOrderIndex < topicSubtopics[j].SubtopicOrderIndex
	})

	first := topicSubtopics[0]

	topic := dto.TopicLearningMapTopicResponse{
		Code:           first.TopicCode,
		Title:          first.TopicTitle,
		Level:          first.TopicLevel,
		OrderIndex:     first.TopicOrderIndex,
		TotalSubtopics: len(topicSubtopics),
		Subtopics:      make([]dto.TopicLearningMapSubtopicResponse, 0, len(topicSubtopics)),
	}

	recommendedCount := 0
	needsReinforcementCount := 0

	for _, subtopic := range topicSubtopics {
		status := resolveSubtopicStatus(subtopic, data.ProgressMap, data.Reinforcement, recommendedSet)

		if status == statusCompleted {
			topic.CompletedSubtopics++
		}

		if status == statusRecommended {
			recommendedCount++
		}

		if status == statusNeedsReinforcement {
			needsReinforcementCount++
		}

		topic.Subtopics = append(topic.Subtopics, dto.TopicLearningMapSubtopicResponse{
			Code:             subtopic.SubtopicCode,
			Title:            subtopic.SubtopicTitle,
			OrderIndex:       subtopic.SubtopicOrderIndex,
			EstimatedMinutes: subtopic.EstimatedMinutes,
			Status:           status,
		})
	}

	topic.Status = resolveTopicStatus(
		topic.TotalSubtopics,
		topic.CompletedSubtopics,
		recommendedCount,
		needsReinforcementCount,
	)

	return &dto.TopicLearningMapResponse{
		Topic: topic,
	}, nil
}

func (s *Service) buildPersonalizationData(ctx context.Context, userID int64, languageCode string) (*personalizationData, error) {
	userData, err := s.adaptationRepo.GetRecommendationUserData(ctx, userID)
	if err != nil {
		return nil, err
	}

	subtopics, err := s.adaptationRepo.ListLearningMapSubtopics(ctx, languageCode)
	if err != nil {
		logger.Error("adaptation service: failed to list learning map subtopics: user_id=%d lang=%s err=%v", userID, languageCode, err)
		return nil, err
	}

	progressMap, err := s.adaptationRepo.GetUserSubtopicProgressMap(ctx, userID)
	if err != nil {
		logger.Error("adaptation service: failed to get user subtopic progress: user_id=%d err=%v", userID, err)
		return nil, err
	}

	reinforcement, err := s.adaptationRepo.GetLatestActiveReinforcement(ctx, userID)
	if err != nil {
		logger.Error("adaptation service: failed to get latest reinforcement: user_id=%d err=%v", userID, err)
		return nil, err
	}

	reinforcement = clearResolvedReinforcement(reinforcement, progressMap)

	candidates := filterRankerCandidates(subtopics, progressMap, reinforcement)

	recommended, err := s.rankNextLessons(ctx, userData, candidates, progressMap, reinforcement)
	if err != nil {
		logger.Error("adaptation service: ml ranker failed, fallback will be used: user_id=%d err=%v", userID, err)
		recommended = fallbackRankNextLessons(userData, candidates, progressMap, reinforcement)
	}

	return &personalizationData{
		UserData:      userData,
		Subtopics:     subtopics,
		ProgressMap:   progressMap,
		Reinforcement: reinforcement,
		Recommended:   recommended,
	}, nil
}

func clearResolvedReinforcement(
	reinforcement *model.ActiveReinforcement,
	progressMap map[string]model.UserSubtopicProgress,
) *model.ActiveReinforcement {
	if reinforcement == nil {
		return nil
	}

	if reinforcement.QuizType == quizTypeTopicFinalQuiz {
		return reinforcement
	}

	progress, ok := progressMap[reinforcement.SubtopicCode]
	if !ok {
		return reinforcement
	}

	if progress.BestScorePercent >= subtopicPassedThreshold {
		return nil
	}

	return reinforcement
}

func filterRankerCandidates(
	subtopics []model.CandidateSubtopic,
	progressMap map[string]model.UserSubtopicProgress,
	reinforcement *model.ActiveReinforcement,
) []model.CandidateSubtopic {
	candidates := make([]model.CandidateSubtopic, 0, len(subtopics))

	for _, subtopic := range subtopics {
		if progress, ok := progressMap[subtopic.SubtopicCode]; ok {
			if progress.BestScorePercent >= subtopicPassedThreshold {
				continue
			}
		}

		if reinforcement != nil && reinforcement.SubtopicCode == subtopic.SubtopicCode {
			continue
		}

		candidates = append(candidates, subtopic)
	}

	return candidates
}

func (s *Service) rankNextLessons(
	ctx context.Context,
	userData *model.RecommendationUserData,
	candidates []model.CandidateSubtopic,
	progressMap map[string]model.UserSubtopicProgress,
	reinforcement *model.ActiveReinforcement,
) ([]rankedCandidate, error) {
	if len(candidates) == 0 {
		return []rankedCandidate{}, nil
	}

	if s.nextLessonMLClient == nil {
		return nil, errors.New("next lesson ML client is not configured")
	}

	req := mlclient.NextLessonRankRequest{
		Items: make([]mlclient.NextLessonRankItem, 0, len(candidates)),
	}

	for _, candidate := range candidates {
		req.Items = append(req.Items, buildRankItem(userData, candidate, progressMap, reinforcement))
	}

	res, err := s.nextLessonMLClient.RankNextLessons(ctx, req)
	if err != nil {
		return nil, err
	}

	scoreMap := make(map[string]float64, len(res.Items))
	for _, item := range res.Items {
		scoreMap[item.CandidateSubtopicCode] = item.Score
	}

	ranked := make([]rankedCandidate, 0, len(candidates))
	for _, candidate := range candidates {
		score, ok := scoreMap[candidate.SubtopicCode]
		if !ok {
			continue
		}

		ranked = append(ranked, rankedCandidate{
			Candidate: candidate,
			Score:     score,
			Reason:    resolveReason(userData, candidate, progressMap),
		})
	}

	sortRankedCandidates(ranked)

	if len(ranked) > topRecommendationsLimit {
		ranked = ranked[:topRecommendationsLimit]
	}

	return ranked, nil
}

func fallbackRankNextLessons(
	userData *model.RecommendationUserData,
	candidates []model.CandidateSubtopic,
	progressMap map[string]model.UserSubtopicProgress,
	reinforcement *model.ActiveReinforcement,
) []rankedCandidate {
	ranked := make([]rankedCandidate, 0, len(candidates))

	for _, candidate := range candidates {
		score := 0.0

		if isPreferredTopic(userData, candidate.TopicCode) {
			score += 3
		}

		if isLevelMatch(userData, candidate.TopicLevel) {
			score += 2
		}

		if isTimeCommitmentMatch(userData, candidate.EstimatedMinutes) {
			score += 1
		}

		if isNextSubtopicInSameTopic(candidate, progressMap) {
			score += 4
		}

		if isTopicInProgress(candidate.TopicCode, progressMap) {
			score += 1
		}

		if candidate.SubtopicOrderIndex == 1 && isPreferredTopic(userData, candidate.TopicCode) {
			score += 1
		}

		if reinforcement != nil && levelToNum(candidate.TopicLevel) > levelToNum(userData.FinancialLiteracyLevel) {
			score -= 2
		}

		score += orderBonus(candidate)

		ranked = append(ranked, rankedCandidate{
			Candidate: candidate,
			Score:     score,
			Reason:    resolveReason(userData, candidate, progressMap),
		})
	}

	sortRankedCandidates(ranked)

	if len(ranked) > topRecommendationsLimit {
		ranked = ranked[:topRecommendationsLimit]
	}

	return ranked
}

func buildRankItem(
	userData *model.RecommendationUserData,
	candidate model.CandidateSubtopic,
	progressMap map[string]model.UserSubtopicProgress,
	reinforcement *model.ActiveReinforcement,
) mlclient.NextLessonRankItem {
	progress, hasProgress := progressMap[candidate.SubtopicCode]

	lastScore := -1.0
	bestScore := -1.0
	attempts := 0

	if hasProgress {
		lastScore = progress.BestScorePercent
		bestScore = progress.BestScorePercent
		attempts = progress.AttemptsCount
	}

	needReinforcement := 0
	if reinforcement != nil {
		needReinforcement = 1
	}

	estimatedMinutes := 0
	if candidate.EstimatedMinutes != nil {
		estimatedMinutes = *candidate.EstimatedMinutes
	}

	return mlclient.NextLessonRankItem{
		CandidateSubtopicCode: candidate.SubtopicCode,

		UserLevelNum:           levelToNum(userData.FinancialLiteracyLevel),
		PracticalExperienceNum: practicalExperienceToNum(userData.PracticalExperience),
		LearningGoalNum:        learningGoalToNum(userData.LearningGoal),
		TimeCommitmentMinutes:  timeCommitmentToMinutes(userData.TimeCommitment),

		CompletedSubtopicsCount:        userData.CompletedSubtopicsCount,
		CompletionRatio:                float64(userData.CompletedSubtopicsCount) / float64(totalSubtopicsCount),
		AverageBestScorePercent:        userData.AverageBestScorePercent,
		AverageAllAttemptsScorePercent: userData.AverageAllAttemptsScorePercent,
		LastQuizScore:                  userData.LastQuizScore,
		FailedQuizCount:                userData.FailedQuizCount,
		DaysSinceLastActivity:          userData.DaysSinceLastActivity,

		CandidateLevelNum:           levelToNum(candidate.TopicLevel),
		CandidateTopicOrderIndex:    candidate.TopicOrderIndex,
		CandidateSubtopicOrderIndex: candidate.SubtopicOrderIndex,
		CandidateEstimatedMinutes:   estimatedMinutes,

		IsPreferredTopic:           boolToInt(isPreferredTopic(userData, candidate.TopicCode)),
		IsSameTopicAsLastCompleted: boolToInt(isSameTopicAsLastCompleted(candidate, progressMap)),
		IsNextSubtopicInSameTopic:  boolToInt(isNextSubtopicInSameTopic(candidate, progressMap)),
		IsFirstSubtopicInTopic:     boolToInt(candidate.SubtopicOrderIndex == 1),
		IsLevelMatch:               boolToInt(isLevelMatch(userData, candidate.TopicLevel)),
		IsTimeCommitmentMatch:      boolToInt(isTimeCommitmentMatch(userData, candidate.EstimatedMinutes)),
		IsTopicNotStarted:          boolToInt(!isTopicInProgress(candidate.TopicCode, progressMap)),
		IsTopicInProgress:          boolToInt(isTopicInProgress(candidate.TopicCode, progressMap)),

		NeedReinforcement:     needReinforcement,
		LastScoreForCandidate: lastScore,
		BestScoreForCandidate: bestScore,
		AttemptsForCandidate:  attempts,
	}
}

func resolveSubtopicStatus(
	subtopic model.CandidateSubtopic,
	progressMap map[string]model.UserSubtopicProgress,
	reinforcement *model.ActiveReinforcement,
	recommendedSet map[string]struct{},
) string {
	if progress, ok := progressMap[subtopic.SubtopicCode]; ok {
		if progress.BestScorePercent >= subtopicPassedThreshold {
			return statusCompleted
		}
	}

	if reinforcement != nil && reinforcement.SubtopicCode == subtopic.SubtopicCode {
		return statusNeedsReinforcement
	}

	if _, ok := recommendedSet[subtopic.SubtopicCode]; ok {
		return statusRecommended
	}

	return statusAvailable
}

func resolveTopicStatus(totalSubtopics, completedSubtopics, recommendedSubtopics, needsReinforcementSubtopics int) string {
	if totalSubtopics > 0 && completedSubtopics == totalSubtopics {
		return statusCompleted
	}

	if needsReinforcementSubtopics > 0 {
		return statusNeedsReinforcement
	}

	if recommendedSubtopics > 0 {
		return statusRecommended
	}

	if completedSubtopics > 0 {
		return statusInProgress
	}

	return statusAvailable
}

func toRecommendedResponses(ranked []rankedCandidate) []dto.RecommendedSubtopicResponse {
	res := make([]dto.RecommendedSubtopicResponse, 0, len(ranked))

	for i, item := range ranked {
		res = append(res, dto.RecommendedSubtopicResponse{
			TopicCode:    item.Candidate.TopicCode,
			SubtopicCode: item.Candidate.SubtopicCode,
			Title:        item.Candidate.SubtopicTitle,
			Rank:         i + 1,
			ReasonType:   item.Reason,
			Score:        item.Score,
		})
	}

	return res
}

func rankedToAction(item rankedCandidate) *dto.RecommendationActionResponse {
	score := item.Score

	return &dto.RecommendationActionResponse{
		Type:         actionTypeNextLesson,
		TopicCode:    item.Candidate.TopicCode,
		SubtopicCode: item.Candidate.SubtopicCode,
		Title:        item.Candidate.SubtopicTitle,
		ReasonType:   item.Reason,
		Score:        &score,
	}
}

func rankedSet(ranked []rankedCandidate) map[string]struct{} {
	set := make(map[string]struct{}, len(ranked))

	for _, item := range ranked {
		set[item.Candidate.SubtopicCode] = struct{}{}
	}

	return set
}

func findSubtopicByCode(subtopics []model.CandidateSubtopic, subtopicCode string) *model.CandidateSubtopic {
	for i := range subtopics {
		if subtopics[i].SubtopicCode == subtopicCode {
			return &subtopics[i]
		}
	}

	return nil
}

func sortRankedCandidates(items []rankedCandidate) {
	sort.SliceStable(items, func(i, j int) bool {
		if items[i].Score == items[j].Score {
			if items[i].Candidate.TopicOrderIndex == items[j].Candidate.TopicOrderIndex {
				return items[i].Candidate.SubtopicOrderIndex < items[j].Candidate.SubtopicOrderIndex
			}

			return items[i].Candidate.TopicOrderIndex < items[j].Candidate.TopicOrderIndex
		}

		return items[i].Score > items[j].Score
	})
}

func resolveReason(
	userData *model.RecommendationUserData,
	candidate model.CandidateSubtopic,
	progressMap map[string]model.UserSubtopicProgress,
) string {
	if isNextSubtopicInSameTopic(candidate, progressMap) {
		return reasonNextLogicalStep
	}

	if isPreferredTopic(userData, candidate.TopicCode) {
		return reasonMatchesInterest
	}

	if isLevelMatch(userData, candidate.TopicLevel) {
		return reasonMatchesLevel
	}

	return reasonNextBestLesson
}

func isPreferredTopic(userData *model.RecommendationUserData, topicCode string) bool {
	preferredCode := contentTopicToPreferredTopicCode(topicCode)

	for _, preferredTopic := range userData.PreferredTopics {
		if preferredTopic == preferredCode {
			return true
		}
	}

	return false
}

func contentTopicToPreferredTopicCode(topicCode string) string {
	switch topicCode {
	case "credit_and_debt":
		return "credits_and_debts"
	case "investments":
		return "investing"
	default:
		return topicCode
	}
}

func isLevelMatch(userData *model.RecommendationUserData, candidateLevel string) bool {
	return levelToNum(candidateLevel) <= levelToNum(userData.FinancialLiteracyLevel)+1
}

func isTimeCommitmentMatch(userData *model.RecommendationUserData, estimatedMinutes *int) bool {
	if estimatedMinutes == nil {
		return true
	}

	return *estimatedMinutes <= timeCommitmentToMinutes(userData.TimeCommitment)
}

func isTopicInProgress(topicCode string, progressMap map[string]model.UserSubtopicProgress) bool {
	for _, progress := range progressMap {
		if progress.TopicCode == topicCode && progress.BestScorePercent >= subtopicPassedThreshold {
			return true
		}
	}

	return false
}

func isSameTopicAsLastCompleted(candidate model.CandidateSubtopic, progressMap map[string]model.UserSubtopicProgress) bool {
	last := latestCompletedProgress(progressMap)
	if last == nil {
		return false
	}

	return last.TopicCode == candidate.TopicCode
}

func isNextSubtopicInSameTopic(candidate model.CandidateSubtopic, progressMap map[string]model.UserSubtopicProgress) bool {
	maxCompletedOrder := 0
	hasCompletedInTopic := false

	for _, progress := range progressMap {
		if progress.TopicCode != candidate.TopicCode {
			continue
		}

		if progress.BestScorePercent < subtopicPassedThreshold {
			continue
		}

		hasCompletedInTopic = true

		// Важно: order_index прогресса у нас нет в progressMap.
		// Поэтому fallback использует простое правило:
		// если тема уже начата, чуть повышаем следующие кандидаты внутри темы.
		// Точный next-in-order позже можно улучшить через join с subtopics.
		if maxCompletedOrder == 0 {
			maxCompletedOrder = 1
		}
	}

	return hasCompletedInTopic && candidate.SubtopicOrderIndex > maxCompletedOrder
}

func latestCompletedProgress(progressMap map[string]model.UserSubtopicProgress) *model.UserSubtopicProgress {
	var latest *model.UserSubtopicProgress

	for _, progress := range progressMap {
		if progress.BestScorePercent < subtopicPassedThreshold {
			continue
		}

		progressCopy := progress

		if latest == nil || progressCopy.LastAttemptAt.After(latest.LastAttemptAt) {
			latest = &progressCopy
		}
	}

	return latest
}

func orderBonus(candidate model.CandidateSubtopic) float64 {
	topicBonus := 1.0 / float64(candidate.TopicOrderIndex+1)
	subtopicBonus := 1.0 / float64(candidate.SubtopicOrderIndex+1)

	return topicBonus + subtopicBonus
}

func levelToNum(level string) int {
	switch level {
	case "beginner":
		return 0
	case "basic":
		return 1
	case "intermediate":
		return 2
	case "advanced":
		return 3
	default:
		return 0
	}
}

func practicalExperienceToNum(value string) int {
	switch value {
	case "no_experience":
		return 0
	case "tracks_expenses":
		return 1
	case "plans_budget":
		return 2
	case "manages_finances":
		return 3
	default:
		return 0
	}
}

func learningGoalToNum(value string) int {
	switch value {
	case "general_improvement":
		return 0
	case "saving_money":
		return 1
	case "debt_management":
		return 2
	case "financial_planning":
		return 3
	case "increase_income":
		return 4
	case "control_spending":
		return 5
	case "understand_banking":
		return 6
	case "start_investing":
		return 7
	case "other":
		return 8
	default:
		return 0
	}
}

func timeCommitmentToMinutes(value string) int {
	switch value {
	case "5_min":
		return 5
	case "10_min":
		return 10
	case "15_min":
		return 15
	case "20_plus_min":
		return 20
	default:
		return 10
	}
}

func boolToInt(value bool) int {
	if value {
		return 1
	}

	return 0
}
