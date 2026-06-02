package model

type ReinforcementFeatures struct {
	UserLevel              string
	LearningGoal           string
	TopicCode              string
	SubtopicCode           string
	TopicLevel             string
	QuizType               string
	QuizScore              float64
	AvgLast3Scores         float64
	PreviousFailsSameTopic int
	SubtopicOrder          int
	PreferredTopicMatch    int
	CompletedInteractive   int
}

type ReinforcementPrediction struct {
	UserID    int64
	QuizID    int64
	AttemptID int64

	QuizType     string
	TopicCode    string
	SubtopicCode string

	ScorePercent   float64
	AvgLast3Scores float64

	NeedsReinforcement bool
	Prediction         int
	Probability        float64
	Confidence         float64

	DecisionSource string
	ModelName      string
	ModelVersion   string
}
