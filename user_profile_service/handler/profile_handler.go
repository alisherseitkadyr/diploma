package handler

import (
	"encoding/json"
	"net/http"

	"diplomaBackend/internal/http/middleware"
	"diplomaBackend/internal/http/response"
	"diplomaBackend/user_profile_service/service"
)

type Handler struct {
	service service.UserProfileService
}

func NewHandler(service service.UserProfileService) *Handler {
	return &Handler{service: service}
}

type UpsertProfileRequest struct {
	FinancialLiteracyLevel string   `json:"financial_literacy_level"`
	PracticalExperience    string   `json:"practical_experience"`
	LearningGoal           string   `json:"learning_goal"`
	PreferredLanguage      string   `json:"preferred_language"`
	TimeCommitment         string   `json:"time_commitment"`
	PreferredTopics        []string `json:"preferred_topics"`
}

type UpdateSettingsRequest struct {
	LanguageCode         *string `json:"language_code"`
	Theme                *string `json:"theme"`
	NotificationsEnabled *bool   `json:"notifications_enabled"`
	ReminderTime         *string `json:"reminder_time"`
}

func (h *Handler) GetProfile(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}
	res, err := h.service.GetProfileByUserID(r.Context(), userID)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *Handler) UpsertProfile(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}
	var req UpsertProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST")
		return
	}

	res, err := h.service.UpsertProfile(r.Context(), service.UpsertProfileInput{
		UserID:                 userID,
		FinancialLiteracyLevel: req.FinancialLiteracyLevel,
		PracticalExperience:    req.PracticalExperience,
		LearningGoal:           req.LearningGoal,
		PreferredLanguage:      req.PreferredLanguage,
		TimeCommitment:         req.TimeCommitment,
		PreferredTopics:        req.PreferredTopics,
	})
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *Handler) GetSettings(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	res, err := h.service.GetSettingsByUserID(r.Context(), userID)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *Handler) UpdateSettings(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	var req UpdateSettingsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST")
		return
	}

	res, err := h.service.UpdateSettings(r.Context(), service.UpdateSettingsInput{
		UserID:               userID,
		LanguageCode:         req.LanguageCode,
		Theme:                req.Theme,
		NotificationsEnabled: req.NotificationsEnabled,
		ReminderTime:         req.ReminderTime,
	})
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}
