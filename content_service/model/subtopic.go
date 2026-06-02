package model

import "time"

type Subtopic struct {
	ID               int64
	TopicID          int64
	Code             string
	OrderIndex       int
	EstimatedMinutes *int
	IsActive         bool
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

type SubtopicTranslation struct {
	ID           int64
	SubtopicID   int64
	LanguageCode string
	Title        string
	Description  *string
}
