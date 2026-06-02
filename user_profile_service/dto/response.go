package dto

type ProfileResponse struct {
	UserID                 int64    `json:"userId"`
	FinancialLiteracyLevel string   `json:"financialLiteracyLevel"`
	PracticalExperience    string   `json:"practicalExperience"`
	LearningGoal           string   `json:"learningGoal"`
	PreferredLanguage      string   `json:"preferredLanguage"`
	TimeCommitment         string   `json:"timeCommitment"`
	PreferredTopics        []string `json:"preferredTopics"`
	OnboardingCompleted    bool     `json:"onboardingCompleted"`
}
