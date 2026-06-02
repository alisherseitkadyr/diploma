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

type NextLessonRankRequest struct {
	Items []NextLessonRankItem `json:"items"`
}

type NextLessonRankItem struct {
	CandidateSubtopicCode string `json:"candidate_subtopic_code"`

	UserLevelNum           int `json:"user_level_num"`
	PracticalExperienceNum int `json:"practical_experience_num"`
	LearningGoalNum        int `json:"learning_goal_num"`
	TimeCommitmentMinutes  int `json:"time_commitment_minutes"`

	CompletedSubtopicsCount        int     `json:"completed_subtopics_count"`
	CompletionRatio                float64 `json:"completion_ratio"`
	AverageBestScorePercent        float64 `json:"average_best_score_percent"`
	AverageAllAttemptsScorePercent float64 `json:"average_all_attempts_score_percent"`
	LastQuizScore                  float64 `json:"last_quiz_score"`
	FailedQuizCount                int     `json:"failed_quiz_count"`
	DaysSinceLastActivity          int     `json:"days_since_last_activity"`

	CandidateLevelNum           int `json:"candidate_level_num"`
	CandidateTopicOrderIndex    int `json:"candidate_topic_order_index"`
	CandidateSubtopicOrderIndex int `json:"candidate_subtopic_order_index"`
	CandidateEstimatedMinutes   int `json:"candidate_estimated_minutes"`

	IsPreferredTopic           int `json:"is_preferred_topic"`
	IsSameTopicAsLastCompleted int `json:"is_same_topic_as_last_completed"`
	IsNextSubtopicInSameTopic  int `json:"is_next_subtopic_in_same_topic"`
	IsFirstSubtopicInTopic     int `json:"is_first_subtopic_in_topic"`
	IsLevelMatch               int `json:"is_level_match"`
	IsTimeCommitmentMatch      int `json:"is_time_commitment_match"`
	IsTopicNotStarted          int `json:"is_topic_not_started"`
	IsTopicInProgress          int `json:"is_topic_in_progress"`

	NeedReinforcement     int     `json:"need_reinforcement"`
	LastScoreForCandidate float64 `json:"last_score_for_candidate"`
	BestScoreForCandidate float64 `json:"best_score_for_candidate"`
	AttemptsForCandidate  int     `json:"attempts_for_candidate"`
}

type NextLessonRankResponse struct {
	Items        []NextLessonRankResult `json:"items"`
	ModelName    string                 `json:"model_name"`
	ModelVersion string                 `json:"model_version"`
}

type NextLessonRankResult struct {
	CandidateSubtopicCode string  `json:"candidate_subtopic_code"`
	Score                 float64 `json:"score"`
}
