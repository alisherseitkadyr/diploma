package mlclient

type ReinforcementPredictRequest struct {
	UserLevel              string  `json:"user_level"`
	LearningGoal           string  `json:"learning_goal"`
	TopicCode              string  `json:"topic_code"`
	SubtopicCode           string  `json:"subtopic_code"`
	TopicLevel             string  `json:"topic_level"`
	QuizType               string  `json:"quiz_type"`
	QuizScore              float64 `json:"quiz_score"`
	AvgLast3Scores         float64 `json:"avg_last_3_scores"`
	PreviousFailsSameTopic int     `json:"previous_fails_same_topic"`
	SubtopicOrder          int     `json:"subtopic_order"`
	PreferredTopicMatch    int     `json:"preferred_topic_match"`
	CompletedInteractive   int     `json:"completed_interactive"`
}

type ReinforcementPredictResponse struct {
	NeedsReinforcement bool    `json:"needs_reinforcement"`
	Prediction         int     `json:"prediction"`
	Probability        float64 `json:"probability"`
	Confidence         float64 `json:"confidence"`
	Threshold          float64 `json:"threshold,omitempty"`
	ModelName          string  `json:"model_name,omitempty"`
}

type NextTopicRankRequest struct {
	Items []NextTopicRankItem `json:"items"`
}

type NextTopicRankItem struct {
	CandidateTopicCode            string  `json:"candidate_topic_code"`
	UserSkillIndex                float64 `json:"user_skill_index"`
	LearningGoalNum               int     `json:"learning_goal_num"`
	AverageBestScorePercent       float64 `json:"average_best_score_percent"`
	CandidateTopicOrderIndex      int     `json:"candidate_topic_order_index"`
	CandidateTopicDifficultyIndex float64 `json:"candidate_topic_difficulty_index"`
	DifficultyGap                 float64 `json:"difficulty_gap"`
	IsPreferredTopic              int     `json:"is_preferred_topic"`
}

type NextTopicRankResponse struct {
	Items        []NextTopicRankResult `json:"items"`
	ModelName    string                `json:"model_name"`
	ModelVersion string                `json:"model_version"`
}

type NextTopicRankResult struct {
	CandidateTopicCode string  `json:"candidate_topic_code"`
	Score              float64 `json:"score"`
}

type RepetitionRankItem struct {
	ConceptCode            string  `json:"concept_code"`
	TopicCode              *string `json:"topic_code,omitempty"`
	UserSkillIndex         float64 `json:"user_skill_index"`
	ConceptDifficultyIndex float64 `json:"concept_difficulty_index"`
	DaysSinceLastReview    float64 `json:"days_since_last_review"`
	ReviewCount            int     `json:"review_count"`
	RecallSuccessRate      float64 `json:"recall_success_rate"`
	LastRecallCorrect      int     `json:"last_recall_correct"`
	AverageLatencySeconds  float64 `json:"average_latency_seconds"`
}

type RepetitionRankRequest struct {
	Items []RepetitionRankItem `json:"items"`
}

type RepetitionRankResult struct {
	ConceptCode                string  `json:"concept_code"`
	TopicCode                  *string `json:"topic_code"`
	RecallProbability          float64 `json:"recall_probability"`
	PriorityScore              float64 `json:"priority_score"`
	ReviewAction               string  `json:"review_action"`
	RecommendedReviewDelayDays int     `json:"recommended_review_delay_days"`
}

type RepetitionRankResponse struct {
	Items        []RepetitionRankResult `json:"items"`
	ModelName    string                 `json:"model_name"`
	ModelVersion string                 `json:"model_version"`
}
