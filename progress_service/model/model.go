package model

import "time"

const (
	QuizTypeSubtopicQuiz   = "subtopic_quiz"
	QuizTypeTopicFinalQuiz = "topic_final_quiz"
)

const (
	ProgressLevelBeginner        = "beginner"
	ProgressLevelAmateur         = "amateur"
	ProgressLevelPractitioner    = "practitioner"
	ProgressLevelAdvancedLearner = "advanced_learner"
)

type UserProgress struct {
	UserID         int64
	TotalXP        int
	ProgressLevel  string
	LastActivityAt *time.Time
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

type UserQuizProgress struct {
	ID               int64
	UserID           int64
	QuizCode         string
	QuizType         string
	TopicCode        *string
	SubtopicCode     *string
	BestScorePoints  int
	MaxScorePoints   int
	BestScorePercent float64
	EarnedXP         int
	AttemptsCount    int
	FirstAttemptAt   time.Time
	BestAttemptAt    time.Time
	LastAttemptAt    time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

type UserLearningStats struct {
	UserID                          int64
	TotalQuizAttempts               int
	CompletedQuizzesCount           int
	CompletedSubtopicQuizzesCount   int
	CompletedTopicFinalQuizzesCount int
	CompletedSubtopicsCount         int
	CompletedTopicsCount            int
	AverageBestScorePercent         float64
	AverageAllAttemptsScorePercent  float64
	MaxScoreQuizzesCount            int
	BestTopicCode                   *string
	WeakestTopicCode                *string
	LastQuizCompletedAt             *time.Time
	CreatedAt                       time.Time
	UpdatedAt                       time.Time
}
