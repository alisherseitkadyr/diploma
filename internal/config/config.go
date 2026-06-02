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
	ReinforcementMLServiceURL string
	NextLessonMLServiceURL    string
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
		ReinforcementMLServiceURL: os.Getenv("REINFORCEMENT_ML_SERVICE_URL"),
		NextLessonMLServiceURL:    os.Getenv("NEXT_LESSON_ML_SERVICE_URL"),
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
	if cfg.ReinforcementMLServiceURL == "" {
		log.Println("REINFORCEMENT_ML_SERVICE_URL is empty, reinforcement ML calls will be disabled")
	}
	if cfg.NextLessonMLServiceURL == "" {
		log.Println("NEXT_LESSON_ML_SERVICE_URL is empty, next lesson ML calls will use fallback ranker")
	}
}
