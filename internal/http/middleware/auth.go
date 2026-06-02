package middleware

import (
	"context"
	"diplomaBackend/internal/http/response"
	"diplomaBackend/internal/logger"
	"net/http"
	"strings"

	"diplomaBackend/authorization_service/service"
)

type contextKey string

const userIDKey contextKey = "user_id"

func AuthMiddleware(jwtService service.JWTService) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")

			if authHeader == "" {
				response.WriteError(w, http.StatusUnauthorized, "MISSING_TOKEN")
				return
			}

			parts := strings.Split(authHeader, " ")
			if len(parts) != 2 || parts[0] != "Bearer" {
				response.WriteError(w, http.StatusUnauthorized, "INVALID_TOKEN_FORMAT")
				return
			}

			userID, _, _, err := jwtService.ParseAccessToken(parts[1])

			if err != nil {
				logger.Warn("access token rejected: reason=%v", err)
				response.WriteError(w, http.StatusUnauthorized, "INVALID_TOKEN")
				return
			}

			ctx := context.WithValue(r.Context(), userIDKey, userID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func UserIDFromContext(ctx context.Context) (int64, bool) {
	userID, ok := ctx.Value(userIDKey).(int64)
	return userID, ok
}
