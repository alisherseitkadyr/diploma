package model

import "time"

type UserLoginSecurity struct {
	UserID         int64
	FailedAttempts int
	LockedUntil    *time.Time
	CreatedAt      time.Time
	UpdatedAt      time.Time
}
