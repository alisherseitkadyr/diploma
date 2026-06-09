package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"

	"diplomaBackend/internal/app"
	"diplomaBackend/internal/config"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
)

func runMigrations(databaseURL string) {
	m, err := migrate.New("file://migrations", databaseURL)
	if err != nil {
		log.Fatalf("migrations init: %v", err)
	}
	defer m.Close()

	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		log.Fatalf("migrations up: %v", err)
	}
	log.Println("migrations applied")
}

func runSeeds(databaseURL string) {
	cmd := exec.Command("/app/seed")
	cmd.Env = append(os.Environ(),
		"DATABASE_URL="+databaseURL,
		"SEEDS_DIR=/app/seeds",
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatalf("seeds: %v", err)
	}
	log.Println("seeds applied")
}

func main() {
	cfg := config.Load()

	runMigrations(cfg.DatabaseURL)
	runSeeds(cfg.DatabaseURL)

	application := app.New(cfg)
	defer application.Close()

	server := &http.Server{
		Addr:    "0.0.0.0:" + cfg.Port,
		Handler: application.Router(),
	}

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Printf("server running on :%s", cfg.Port)

		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
	}()

	<-quit

	log.Println("gracefully shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Printf("server forced to shutdown: %v", err)
	} else {
		log.Println("server stopped")
	}
}
