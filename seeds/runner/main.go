package main

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load()

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL is not set")
	}

	seedsDir := os.Getenv("SEEDS_DIR")
	if seedsDir == "" {
		seedsDir = "seeds"
	}

	entries, err := os.ReadDir(seedsDir)
	if err != nil {
		log.Fatalf("read seeds dir: %v", err)
	}

	var files []string
	for _, e := range entries {
		if !e.IsDir() && isSeedFile(e.Name()) {
			files = append(files, filepath.Join(seedsDir, e.Name()))
		}
	}
	sort.Strings(files)

	if len(files) == 0 {
		log.Println("no seed files found")
		return
	}

	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dbURL)
	if err != nil {
		log.Fatalf("connect: %v", err)
	}
	defer conn.Close(ctx)

	for _, f := range files {
		if err := runFile(ctx, conn, f); err != nil {
			log.Fatalf("seed %s: %v", f, err)
		}
		fmt.Printf("seeded %s\n", f)
	}
}

func runFile(ctx context.Context, conn *pgx.Conn, path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("read: %w", err)
	}

	tx, err := conn.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin: %w", err)
	}
	defer tx.Rollback(ctx)

	if bytes.HasPrefix(bytes.TrimSpace(data), []byte("{")) {
		if err := runJSONSeed(ctx, tx, data); err != nil {
			return err
		}
	} else if _, err := tx.Exec(ctx, string(data)); err != nil {
		return fmt.Errorf("exec: %w", err)
	}

	return tx.Commit(ctx)
}

func isSeedFile(name string) bool {
	return strings.HasSuffix(name, ".sql") || strings.HasSuffix(name, ".json")
}
