package dto

type SettingsResponse struct {
	UserID               int64   `json:"userId"`
	LanguageCode         string  `json:"languageCode"`
	Theme                string  `json:"theme"`
	NotificationsEnabled bool    `json:"notificationsEnabled"`
	ReminderTime         *string `json:"reminderTime"`
}
