package jwt

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type Service struct {
	accessSecret []byte
	accessTTL    time.Duration
}

type Claims struct {
	UserID   int64  `json:"user_id"`
	Email    string `json:"email"`
	Username string `json:"username"`
	jwt.RegisteredClaims
}

func NewService(accessSecret string, accessTTL time.Duration) *Service {
	return &Service{
		accessSecret: []byte(accessSecret),
		accessTTL:    accessTTL,
	}
}

func (s *Service) GenerateAccessToken(userID int64, email, username string) (string, error) {
	now := time.Now().UTC()

	claims := Claims{
		UserID:   userID,
		Email:    email,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   fmt.Sprintf("%d", userID),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.accessTTL)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.accessSecret)
}

func (s *Service) GenerateRefreshToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}

	return hex.EncodeToString(b), nil
}

func (s *Service) ParseAccessToken(tokenString string) (int64, string, string, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (any, error) {
		if token.Method != jwt.SigningMethodHS256 {
			return nil, fmt.Errorf("unexpected signing method")
		}
		return s.accessSecret, nil
	})
	if err != nil {
		return 0, "", "", err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return 0, "", "", fmt.Errorf("invalid token")
	}

	return claims.UserID, claims.Email, claims.Username, nil
}

func (s *Service) HashRefreshToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}
