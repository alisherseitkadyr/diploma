package service

type SubmitQuizInput struct {
	UserID          int64
	AttemptID       int64
	DurationSeconds int
	Answers         []SubmitAnswerInput
}

type SubmitAnswerInput struct {
	QuestionID        int64
	SelectedOptionIDs []int64
}
