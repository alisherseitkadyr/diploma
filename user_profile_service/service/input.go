package service

type UpsertProfileInput struct {
	UserID                 int64
	FinancialLiteracyLevel string
	PracticalExperience    string
	LearningGoal           string
	PreferredLanguage      string
	TimeCommitment         string
	PreferredTopics        []string
}
