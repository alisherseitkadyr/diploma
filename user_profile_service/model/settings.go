package model

import "time"

type UserSettings struct {
	ID                   int64
	UserID               int64
	LanguageCode         string
	Theme                string
	NotificationsEnabled bool
	ReminderTime         *string
	CreatedAt            time.Time
	UpdatedAt            time.Time
}
