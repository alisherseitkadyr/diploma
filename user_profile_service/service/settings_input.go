package service

type UpdateSettingsInput struct {
	UserID               int64
	LanguageCode         *string
	Theme                *string
	NotificationsEnabled *bool
	ReminderTime         *string
}
