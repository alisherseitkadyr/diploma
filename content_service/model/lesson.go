package model

import "time"

type Lesson struct {
	ID          int64
	SubtopicID  int64
	IsPublished bool
	CreatedAt   time.Time
	UpdatedAt   time.Time
}
