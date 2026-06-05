package dto

type RepetitionItemResponse struct {
	ConceptCode                string  `json:"conceptCode"`
	TopicCode                  *string `json:"topicCode,omitempty"`
	RecallProbability          float64 `json:"recallProbability"`
	PriorityScore              float64 `json:"priorityScore"`
	ReviewAction               string  `json:"reviewAction"`
	RecommendedReviewDelayDays int     `json:"recommendedReviewDelayDays"`
}

type RepetitionReviewResponse struct {
	Items        []RepetitionItemResponse `json:"items"`
	ModelName    string                   `json:"modelName,omitempty"`
	ModelVersion string                   `json:"modelVersion,omitempty"`
}
