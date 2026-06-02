package model

import "time"

type User struct {
	ID           int64
	Email        string
	Username     string
	PasswordHash string
	IsActive     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time
}
