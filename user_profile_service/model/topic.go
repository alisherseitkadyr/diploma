package model

import "time"

type UserPreferredTopic struct {
	ID        int64
	UserID    int64
	TopicCode string
	CreatedAt time.Time
}
