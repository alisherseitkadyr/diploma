package model

import "time"

type LessonStep struct {
	ID                 int64
	LessonID           int64
	StepType           string
	OrderIndex         int
	InteractiveType    *string
	InteractiveContent []byte
	CreatedAt          time.Time
	UpdatedAt          time.Time
}

type LessonStepTranslation struct {
	ID           int64
	LessonStepID int64
	LanguageCode string
	Title        *string
	Content      []byte
}
