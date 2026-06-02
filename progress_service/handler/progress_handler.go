package handler

import (
	"net/http"

	"diplomaBackend/internal/http/middleware"
	"diplomaBackend/internal/http/response"
	"diplomaBackend/progress_service/service"
)

type Handler struct {
	service service.ProgressService
}

func NewHandler(service service.ProgressService) *Handler {
	return &Handler{service: service}
}

func (h *Handler) GetMyProgress(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	res, err := h.service.GetProgressOverview(r.Context(), userID)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}
