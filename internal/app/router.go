package app

import (
	adaptationHandler "diplomaBackend/adaptation_service/handler"
	assessmentHandler "diplomaBackend/assessment_service/handler"
	contentHandler "diplomaBackend/content_service/handler"
	progressHandler "diplomaBackend/progress_service/handler"
	"net/http"

	"diplomaBackend/authorization_service/handler"
	profileHandler "diplomaBackend/user_profile_service/handler"
)

func NewRouter(
	authHandler *handler.AuthHandler,
	profileHandler *profileHandler.Handler,
	contentHandler *contentHandler.Handler,
	assessmentHandler *assessmentHandler.Handler,
	progressHandler *progressHandler.Handler,
	adaptationHandler *adaptationHandler.Handler,
	authMiddleware func(http.Handler) http.Handler,
) http.Handler {
	apiMux := http.NewServeMux()

	apiMux.HandleFunc("POST /auth/register", authHandler.Register)
	apiMux.HandleFunc("POST /auth/login", authHandler.Login)
	apiMux.HandleFunc("POST /auth/google", authHandler.GoogleLogin)
	apiMux.HandleFunc("POST /auth/refresh", authHandler.Refresh)
	apiMux.HandleFunc("POST /auth/logout", authHandler.Logout)

	apiMux.Handle("GET /auth/me", authMiddleware(http.HandlerFunc(authHandler.Me)))
	apiMux.Handle("PATCH /auth/me/username", authMiddleware(http.HandlerFunc(authHandler.ChangeUsername)))
	apiMux.Handle("PATCH /auth/me/password", authMiddleware(http.HandlerFunc(authHandler.ChangePassword)))
	apiMux.Handle("DELETE /auth/me", authMiddleware(http.HandlerFunc(authHandler.DeleteMe)))

	apiMux.Handle("GET /profile/me", authMiddleware(http.HandlerFunc(profileHandler.GetProfile)))
	apiMux.Handle("PUT /profile/me", authMiddleware(http.HandlerFunc(profileHandler.UpsertProfile)))
	apiMux.Handle("GET /profile/settings", authMiddleware(http.HandlerFunc(profileHandler.GetSettings)))
	apiMux.Handle("PATCH /profile/settings", authMiddleware(http.HandlerFunc(profileHandler.UpdateSettings)))

	apiMux.Handle("GET /content/topics", authMiddleware(http.HandlerFunc(contentHandler.ListTopics)))
	apiMux.Handle("GET /content/topics/{topicCode}/subtopics", authMiddleware(http.HandlerFunc(contentHandler.ListSubtopicsByTopicCode)))
	apiMux.Handle("GET /content/subtopics/{subtopicCode}/lesson", authMiddleware(http.HandlerFunc(contentHandler.GetLessonBySubtopicCode)))
	apiMux.Handle("POST /content/subtopics/{subtopicCode}/complete", authMiddleware(http.HandlerFunc(contentHandler.CompleteSubtopic)))
	apiMux.Handle("GET /content/explore", authMiddleware(http.HandlerFunc(contentHandler.GetExploreView)))

	apiMux.Handle("GET /assessment/quizzes/{quizId}", authMiddleware(http.HandlerFunc(assessmentHandler.GetQuizByID)))
	apiMux.Handle("POST /assessment/quizzes/{quizId}/start", authMiddleware(http.HandlerFunc(assessmentHandler.StartQuiz)))
	apiMux.Handle("POST /assessment/attempts/{attemptId}/submit", authMiddleware(http.HandlerFunc(assessmentHandler.SubmitAttempt)))
	apiMux.Handle("GET /assessment/quizzes/{quizId}/latest-attempt", authMiddleware(http.HandlerFunc(assessmentHandler.GetLatestAttemptByQuizID)))
	apiMux.Handle("GET /assessment/attempts/{attemptId}", authMiddleware(http.HandlerFunc(assessmentHandler.GetAttemptByID)))
	apiMux.Handle("GET /progress/me", authMiddleware(http.HandlerFunc(progressHandler.GetMyProgress)))
	apiMux.Handle("GET /adaptation/recommendations/home", authMiddleware(http.HandlerFunc(adaptationHandler.GetHomeRecommendations)))
	apiMux.Handle("GET /adaptation/learning-map", authMiddleware(http.HandlerFunc(adaptationHandler.GetLearningMap)))
	apiMux.Handle("GET /adaptation/topics/{topicCode}/learning-map", authMiddleware(http.HandlerFunc(adaptationHandler.GetTopicLearningMap)))

	rootMux := http.NewServeMux()
	rootMux.Handle("/api/", http.StripPrefix("/api", apiMux))

	return rootMux
}
