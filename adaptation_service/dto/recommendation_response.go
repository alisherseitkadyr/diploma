package dto

type RecommendationActionResponse struct {
	Type         string   `json:"type"`
	TopicCode    string   `json:"topicCode"`
	SubtopicCode string   `json:"subtopicCode"`
	Title        string   `json:"title"`
	ReasonType   string   `json:"reasonType"`
	Score        *float64 `json:"score"`
}

type RecommendedSubtopicResponse struct {
	TopicCode    string  `json:"topicCode"`
	SubtopicCode string  `json:"subtopicCode"`
	Title        string  `json:"title"`
	Rank         int     `json:"rank"`
	ReasonType   string  `json:"reasonType"`
	Score        float64 `json:"score"`
}

type HomeRecommendationsResponse struct {
	State            string                        `json:"state"`
	ContinueLearning *RecommendationActionResponse `json:"continueLearning"`
	NextRecommended  *RecommendationActionResponse `json:"nextRecommended"`
	Recommended      []RecommendedSubtopicResponse `json:"recommended"`
}

type LearningMapTopicResponse struct {
	Code                        string `json:"code"`
	Title                       string `json:"title"`
	Level                       string `json:"level"`
	OrderIndex                  int    `json:"orderIndex"`
	Status                      string `json:"status"`
	TotalSubtopics              int    `json:"totalSubtopics"`
	CompletedSubtopics          int    `json:"completedSubtopics"`
	RecommendedSubtopics        int    `json:"recommendedSubtopics"`
	NeedsReinforcementSubtopics int    `json:"needsReinforcementSubtopics"`
}

type LearningMapResponse struct {
	Topics []LearningMapTopicResponse `json:"topics"`
}

type TopicLearningMapSubtopicResponse struct {
	Code             string `json:"code"`
	Title            string `json:"title"`
	OrderIndex       int    `json:"orderIndex"`
	EstimatedMinutes *int   `json:"estimatedMinutes,omitempty"`
	Status           string `json:"status"`
}

type TopicLearningMapTopicResponse struct {
	Code               string                             `json:"code"`
	Title              string                             `json:"title"`
	Level              string                             `json:"level"`
	OrderIndex         int                                `json:"orderIndex"`
	Status             string                             `json:"status"`
	TotalSubtopics     int                                `json:"totalSubtopics"`
	CompletedSubtopics int                                `json:"completedSubtopics"`
	Subtopics          []TopicLearningMapSubtopicResponse `json:"subtopics"`
}

type TopicLearningMapResponse struct {
	Topic TopicLearningMapTopicResponse `json:"topic"`
}
