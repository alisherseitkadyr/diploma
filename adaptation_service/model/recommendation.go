package model

import "time"

type RecommendationUserData struct {
	UserID                         int64
	FinancialLiteracyLevel         string
	PracticalExperience            string
	LearningGoal                   string
	TimeCommitment                 string
	PreferredTopics                []string
	CompletedSubtopicsCount        int
	CompletedTopicsCount           int
	AverageBestScorePercent        float64
	AverageAllAttemptsScorePercent float64
	LastQuizScore                  float64
	FailedQuizCount                int
	DaysSinceLastActivity          int
}

type CandidateSubtopic struct {
	TopicCode          string
	TopicTitle         string
	TopicLevel         string
	TopicOrderIndex    int
	SubtopicCode       string
	SubtopicTitle      string
	SubtopicOrderIndex int
	EstimatedMinutes   *int
}

type UserSubtopicProgress struct {
	TopicCode        string
	SubtopicCode     string
	BestScorePercent float64
	AttemptsCount    int
	LastAttemptAt    time.Time
}

type ActiveReinforcement struct {
	TopicCode    string
	SubtopicCode string
	QuizType     string
	ScorePercent float64
	CreatedAt    time.Time
}

type RepetitionCandidate struct {
	TopicCode           string
	SubtopicCode        string
	TopicLevel          string
	TopicOrderIndex     int
	BestScorePercent    float64
	AttemptsCount       int
	DaysSinceLastReview float64
}
