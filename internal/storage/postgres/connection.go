package postgres

import (
	"context"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func New(databaseURL string) *pgxpool.Pool {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, databaseURL)

	if err != nil {
		log.Fatal("failed to connect to database:", err)
	}

	if err := pool.Ping(ctx); err != nil {
		log.Fatal("failed to ping database:", err)
	}

	log.Println("connected to database")

	return pool
}
