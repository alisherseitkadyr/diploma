package handler

import (
	"diplomaBackend/authorization_service/dto"
	"encoding/json"
	"net/http"

	"diplomaBackend/authorization_service/service"
	"diplomaBackend/internal/http/middleware"
	"diplomaBackend/internal/http/response"
)

type AuthHandler struct {
	authService service.AuthService
}

func NewAuthHandler(authService service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req RegisterRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST")
		return
	}

	res, err := h.authService.Register(r.Context(), dto.RegisterInput{
		Email:    req.Email,
		Username: req.Username,
		Password: req.Password,
	})
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusCreated, res)
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST")
		return
	}

	res, err := h.authService.Login(r.Context(), dto.LoginInput{
		Email:    req.Email,
		Password: req.Password,
	})
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *AuthHandler) GoogleLogin(w http.ResponseWriter, r *http.Request) {
	var req GoogleLoginRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST")
		return
	}

	res, err := h.authService.GoogleLogin(r.Context(), dto.GoogleLoginInput{
		IDToken: req.IDToken,
	})
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *AuthHandler) Refresh(w http.ResponseWriter, r *http.Request) {
	var req RefreshRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST")
		return
	}

	res, err := h.authService.Refresh(r.Context(), req.RefreshToken)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	var req LogoutRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST")
		return
	}

	if err := h.authService.Logout(r.Context(), req.RefreshToken); err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, map[string]string{
		"message": "LOGGED_OUT",
	})
}

func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	res, err := h.authService.Me(r.Context(), userID)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *AuthHandler) ChangeUsername(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	var req ChangeUsernameRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST")
		return
	}

	res, err := h.authService.ChangeUsername(r.Context(), userID, dto.ChangeUsernameInput{
		NewUsername: req.NewUsername,
	})
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *AuthHandler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	var req ChangePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST")
		return
	}

	err := h.authService.ChangePassword(r.Context(), userID, dto.ChangePasswordInput{
		CurrentPassword: req.CurrentPassword,
		NewPassword:     req.NewPassword,
		RefreshToken:    req.RefreshToken,
	})
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, map[string]string{
		"message": "PASSWORD_CHANGED",
	})
}

func (h *AuthHandler) DeleteMe(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	if err := h.authService.DeleteAccount(r.Context(), userID); err != nil {
		response.WriteAppError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
