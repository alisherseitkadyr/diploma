package dto

type UpsertProfileRequest struct {
	FinancialLiteracyLevel string   `json:"financialLiteracyLevel"`
	PracticalExperience    string   `json:"practicalExperience"`
	LearningGoal           string   `json:"learningGoal"`
	PreferredLanguage      string   `json:"preferredLanguage"`
	TimeCommitment         string   `json:"timeCommitment"`
	PreferredTopics        []string `json:"preferredTopics"`
}
