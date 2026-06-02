package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"diplomaBackend/assessment_service/service"
	"diplomaBackend/internal/http/middleware"
	"diplomaBackend/internal/http/response"
)

type Handler struct {
	service service.AssessmentService
}

func NewHandler(service service.AssessmentService) *Handler {
	return &Handler{service: service}
}

func (h *Handler) GetQuizByID(w http.ResponseWriter, r *http.Request) {
	quizID, err := parsePathInt64(r, "quizId")
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_QUIZ_ID")
		return
	}

	languageCode := getLanguageCode(r)

	res, err := h.service.GetQuizByID(r.Context(), quizID, languageCode)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *Handler) StartQuiz(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	quizID, err := parsePathInt64(r, "quizId")
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_QUIZ_ID")
		return
	}

	languageCode := getLanguageCode(r)

	res, err := h.service.StartQuiz(r.Context(), userID, quizID, languageCode)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusCreated, res)
}

func (h *Handler) SubmitAttempt(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	attemptID, err := parsePathInt64(r, "attemptId")
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_ATTEMPT_ID")
		return
	}

	var req SubmitQuizRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST")
		return
	}

	answers := make([]service.SubmitAnswerInput, 0, len(req.Answers))
	for _, answer := range req.Answers {
		answers = append(answers, service.SubmitAnswerInput{
			QuestionID:        answer.QuestionID,
			SelectedOptionIDs: answer.SelectedOptionIDs,
		})
	}

	res, err := h.service.SubmitAttempt(r.Context(), service.SubmitQuizInput{
		UserID:          userID,
		AttemptID:       attemptID,
		DurationSeconds: req.DurationSeconds,
		Answers:         answers,
	})
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *Handler) GetLatestAttemptByQuizID(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	quizID, err := parsePathInt64(r, "quizId")
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_QUIZ_ID")
		return
	}

	res, err := h.service.GetLatestAttemptByQuizID(r.Context(), userID, quizID)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func (h *Handler) GetAttemptByID(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED")
		return
	}

	attemptID, err := parsePathInt64(r, "attemptId")
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_ATTEMPT_ID")
		return
	}

	languageCode := getLanguageCode(r)

	res, err := h.service.GetAttemptByID(r.Context(), userID, attemptID, languageCode)
	if err != nil {
		response.WriteAppError(w, err)
		return
	}

	response.WriteJSON(w, http.StatusOK, res)
}

func getLanguageCode(r *http.Request) string {
	lang := r.URL.Query().Get("lang")

	switch lang {
	case "ru", "kk", "en":
		return lang
	default:
		return "kk"
	}
}

func parsePathInt64(r *http.Request, key string) (int64, error) {
	return strconv.ParseInt(r.PathValue(key), 10, 64)
}
