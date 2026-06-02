package dto

type CodeOption struct {
	Code string `json:"code"`
}

type QuestionnaireOptionsResponse struct {
	FinancialLiteracyLevels []CodeOption `json:"financialLiteracyLevels"`
	PracticalExperiences    []CodeOption `json:"practicalExperiences"`
	LearningGoals           []CodeOption `json:"learningGoals"`
	PreferredLanguages      []CodeOption `json:"preferredLanguages"`
	TimeCommitments         []CodeOption `json:"timeCommitments"`
	PreferredTopics         []CodeOption `json:"preferredTopics"`
}
