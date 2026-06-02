package model

import "time"

type Topic struct {
	ID         int64
	Code       string
	Level      string
	OrderIndex int
	IsActive   bool
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

type TopicTranslation struct {
	ID           int64
	TopicID      int64
	LanguageCode string
	Title        string
	Description  *string
}
