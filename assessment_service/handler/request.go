package handler

type SubmitQuizRequest struct {
	DurationSeconds int                   `json:"duration_seconds"`
	Answers         []SubmitAnswerRequest `json:"answers"`
}

type SubmitAnswerRequest struct {
	QuestionID        int64   `json:"question_id"`
	SelectedOptionIDs []int64 `json:"selected_option_ids"`
}
