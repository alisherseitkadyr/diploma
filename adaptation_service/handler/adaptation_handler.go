package handler

import (
	"net/http"

	"diplomaBackend/adaptation_service/service"
	"diplomaBackend/internal/http/middleware"
	"diplomaBackend/internal/http/response"
)

type Handler struct {
	service service.AdaptationService
}

func NewHandler(service service.AdaptationService) *Handler {
	return &Handler{service: service}
}

func (h *Handler) GetHomeRecommendations(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	languageCode := r.URL.Query().Get("lang")
	if languageCode == "" {
		languageCode = "kk"
	}

	res, err := h.service.GetHomeRecommendations(r.Context(), userID, languageCode)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *Handler) GetLearningMap(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	languageCode := r.URL.Query().Get("lang")
	if languageCode == "" {
		languageCode = "kk"
	}

	res, err := h.service.GetLearningMap(r.Context(), userID, languageCode)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *Handler) GetRepetitionReview(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	res, err := h.service.GetRepetitionReview(r.Context(), userID)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *Handler) GetTopicLearningMap(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	topicCode := r.PathValue("topicCode")
	if topicCode == "" {
		response.WriteError(w, http.StatusBadRequest, "INVALID_TOPIC_CODE")
		return
	}

	languageCode := r.URL.Query().Get("lang")
	if languageCode == "" {
		languageCode = "kk"
	}

	res, err := h.service.GetTopicLearningMap(r.Context(), userID, topicCode, languageCode)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}
