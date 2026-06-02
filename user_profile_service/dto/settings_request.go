package dto

type UpdateSettingsRequest struct {
	LanguageCode         *string `json:"languageCode"`
	Theme                *string `json:"theme"`
	NotificationsEnabled *bool   `json:"notificationsEnabled"`
	ReminderTime         *string `json:"reminderTime"`
}
