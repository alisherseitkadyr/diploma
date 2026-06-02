package service

type JWTService interface {
	GenerateAccessToken(userID int64, email, username string) (string, error)
	GenerateRefreshToken() (string, error)
	ParseAccessToken(token string) (int64, string, string, error)
	HashRefreshToken(token string) string
}
