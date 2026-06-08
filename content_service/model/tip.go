package model

import "time"

type Tip struct {
	ID        int64
	SectionID int64
	Weight    int
	Status    string
	CreatedAt time.Time
	UpdatedAt time.Time
}

type TipTranslation struct {
	ID           int64
	TipID        int64
	LanguageCode string
	Title        string
	Body         string
	IconKey      string
	ThemeKey     string
}
