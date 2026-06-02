package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"diplomaBackend/internal/app"
	"diplomaBackend/internal/config"
)

func main() {
	cfg := config.Load()

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
