package dto

import "time"

type TopicProgressDetail struct {
	SubtopicsRead  int  `json:"subtopics_read"`
	TotalSubtopics int  `json:"total_subtopics"`
	QuizPassed     bool `json:"quiz_passed"`
	IsComplete     bool `json:"is_complete"`
}

type ProgressResponse struct {
	TotalXP        int                            `json:"total_xp"`
	ProgressLevel  string                         `json:"progress_level"`
	LastActivityAt *time.Time                     `json:"last_activity_at,omitempty"`
	Topics         map[string]TopicProgressDetail `json:"topics,omitempty"`
}

type LearningStatsResponse struct {
	TotalQuizAttempts               int        `json:"total_quiz_attempts"`
	CompletedQuizzesCount           int        `json:"completed_quizzes_count"`
	CompletedSubtopicQuizzesCount   int        `json:"completed_subtopic_quizzes_count"`
	CompletedTopicFinalQuizzesCount int        `json:"completed_topic_final_quizzes_count"`
	CompletedSubtopicsCount         int        `json:"completed_subtopics_count"`
	CompletedTopicsCount            int        `json:"completed_topics_count"`
	AverageBestScorePercent         float64    `json:"average_best_score_percent"`
	AverageAllAttemptsScorePercent  float64    `json:"average_all_attempts_score_percent"`
	MaxScoreQuizzesCount            int        `json:"max_score_quizzes_count"`
	BestTopicCode                   *string    `json:"best_topic_code,omitempty"`
	WeakestTopicCode                *string    `json:"weakest_topic_code,omitempty"`
	LastQuizCompletedAt             *time.Time `json:"last_quiz_completed_at,omitempty"`
}

type ProgressOverviewResponse struct {
	Progress        ProgressResponse      `json:"progress"`
	Stats           LearningStatsResponse `json:"stats"`
	CompletedTopics []string              `json:"completed_topics"`
}
