package model

import "time"

type UserLearningProfile struct {
	ID                     int64
	UserID                 int64
	FinancialLiteracyLevel string
	PracticalExperience    string
	LearningGoal           string
	PreferredLanguage      string
	TimeCommitment         string
	OnboardingCompleted    bool
	CreatedAt              time.Time
	UpdatedAt              time.Time
}
