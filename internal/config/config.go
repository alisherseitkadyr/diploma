package config

import (
	"log"
	"os"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	Port                      string
	DatabaseURL               string
	JWTAccessSecret           string
	GoogleClientID            string
	AccessTokenTTL            time.Duration
	RefreshTokenTTL           time.Duration
	NextTopicMLServiceURL string
	MLAPIKey              string
}

func Load() *Config {
	err := godotenv.Load()
	if err != nil {
		log.Println(".env not found, using system env")
	}

	accessTokenTTL, err := time.ParseDuration(os.Getenv("ACCESS_TOKEN_TTL"))
	if err != nil {
		log.Fatalf("invalid ACCESS_TOKEN_TTL: %v", err)
	}

	refreshTokenTTL, err := time.ParseDuration(os.Getenv("REFRESH_TOKEN_TTL"))
	if err != nil {
		log.Fatalf("invalid REFRESH_TOKEN_TTL: %v", err)
	}

	cfg := &Config{
		Port:                      os.Getenv("PORT"),
		DatabaseURL:               os.Getenv("DATABASE_URL"),
		JWTAccessSecret:           os.Getenv("JWT_ACCESS_SECRET"),
		GoogleClientID:            os.Getenv("GOOGLE_CLIENT_ID"),
		AccessTokenTTL:            accessTokenTTL,
		RefreshTokenTTL:           refreshTokenTTL,
		NextTopicMLServiceURL: os.Getenv("NEXT_TOPIC_ML_SERVICE_URL"),
		MLAPIKey:              os.Getenv("ML_API_KEY"),
		// ML_URL: os.Getenv("NEXT_TOPIC_ML_SERVICE_URL"),
		// CORS_ORIGINS: os.Getenv("CORS_ORIGINS"),
		// POSTGRES_USER: os.Getenv("POSTGRES_USER"),
		// POSTGRES_PASSWORD: os.Getenv("POSTGRES_PASSWORD"),
		// POSTGRES_DB: os.Getenv("POSTGRES_DB"),

	}

	validate(cfg)

	return cfg
}

func validate(cfg *Config) {
	if cfg.Port == "" {
		log.Fatal("PORT is required")
	}
	if cfg.DatabaseURL == "" {
		log.Fatal("DATABASE_URL is required")
	}
	if cfg.JWTAccessSecret == "" {
		log.Fatal("JWT_ACCESS_SECRET is required")
	}
	if cfg.GoogleClientID == "" {
		log.Fatal("GOOGLE_CLIENT_ID is required")
	}
	if cfg.AccessTokenTTL <= 0 {
		log.Fatal("ACCESS_TOKEN_TTL must be greater than 0")
	}
	if cfg.RefreshTokenTTL <= 0 {
		log.Fatal("REFRESH_TOKEN_TTL must be greater than 0")
	}
	if cfg.NextTopicMLServiceURL == "" {
		log.Println("NEXT_TOPIC_ML_SERVICE_URL is empty, next topic ML calls will use fallback ranker")
	}
}
