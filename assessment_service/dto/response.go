package dto

import "time"

type StartQuizResponse struct {
	AttemptID      int64              `json:"attempt_id"`
	QuizID         int64              `json:"quiz_id"`
	QuizType       string             `json:"quiz_type"`
	Title          string             `json:"title"`
	TotalQuestions int                `json:"total_questions"`
	Questions      []QuestionResponse `json:"questions"`
}

type QuestionResponse struct {
	ID           int64            `json:"id"`
	QuestionType string           `json:"question_type"`
	OrderIndex   int              `json:"order_index"`
	QuestionText string           `json:"question_text"`
	Options      []OptionResponse `json:"options"`
}

type OptionResponse struct {
	ID         int64  `json:"id"`
	OrderIndex int    `json:"order_index"`
	Text       string `json:"text"`
	IsCorrect  bool   `json:"is_correct"`
}

type SubmitQuizResponse struct {
	AttemptID      int64                        `json:"attempt_id"`
	QuizID         int64                        `json:"quiz_id"`
	ScorePercent   int                          `json:"score_percent"`
	TotalQuestions int                          `json:"total_questions"`
	CorrectAnswers int                          `json:"correct_answers"`
	WrongAnswers   int                          `json:"wrong_answers"`
	Passed         bool                         `json:"passed"`
	XPForScore     int                          `json:"xp_for_score"`
	SubmittedAt    time.Time                    `json:"submitted_at"`
	Reinforcement  *ReinforcementResultResponse `json:"reinforcement,omitempty"`
}

type LatestAttemptResponse struct {
	HasAttempt bool                    `json:"has_attempt"`
	Attempt    *AttemptSummaryResponse `json:"attempt"`
}

type AttemptSummaryResponse struct {
	AttemptID      int64     `json:"attempt_id"`
	QuizID         int64     `json:"quiz_id"`
	ScorePercent   int       `json:"score_percent"`
	TotalQuestions int       `json:"total_questions"`
	CorrectAnswers int       `json:"correct_answers"`
	WrongAnswers   int       `json:"wrong_answers"`
	Passed         bool      `json:"passed"`
	XPForScore     int       `json:"xp_for_score"`
	SubmittedAt    time.Time `json:"submitted_at"`
}

type AttemptDetailResponse struct {
	AttemptID      int64                  `json:"attempt_id"`
	QuizID         int64                  `json:"quiz_id"`
	ScorePercent   int                    `json:"score_percent"`
	TotalQuestions int                    `json:"total_questions"`
	CorrectAnswers int                    `json:"correct_answers"`
	WrongAnswers   int                    `json:"wrong_answers"`
	Passed         bool                   `json:"passed"`
	XPForScore     int                    `json:"xp_for_score"`
	SubmittedAt    time.Time              `json:"submitted_at"`
	Answers        []AttemptAnswerDetails `json:"answers"`
}

type AttemptAnswerDetails struct {
	QuestionID        int64                  `json:"question_id"`
	QuestionText      string                 `json:"question_text"`
	QuestionType      string                 `json:"question_type"`
	OrderIndex        int                    `json:"order_index"`
	SelectedOptions   []SelectedOptionResult `json:"selected_options"`
	CorrectOptions    []CorrectOptionResult  `json:"correct_options"`
	IsQuestionCorrect bool                   `json:"is_question_correct"`
}

type SelectedOptionResult struct {
	OptionID  int64  `json:"option_id"`
	Text      string `json:"text"`
	IsCorrect bool   `json:"is_correct"`
}

type CorrectOptionResult struct {
	OptionID int64  `json:"option_id"`
	Text     string `json:"text"`
}

type QuizResponse struct {
	ID               int64              `json:"id"`
	SubtopicCode     *string            `json:"subtopic_code,omitempty"`
	TopicCode        *string            `json:"topic_code,omitempty"`
	QuizType         string             `json:"quiz_type"`
	Title            string             `json:"title"`
	PassingScore     int                `json:"passing_score"`
	TimeLimitSeconds *int               `json:"time_limit_seconds"`
	Questions        []QuestionResponse `json:"questions"`
}

type ReinforcementResultResponse struct {
	NeedsReinforcement bool    `json:"needs_reinforcement"`
	Prediction         int     `json:"prediction"`
	Probability        float64 `json:"probability"`
	Confidence         float64 `json:"confidence"`
	DecisionSource     string  `json:"decision_source"`
	ModelName          string  `json:"model_name,omitempty"`
}
