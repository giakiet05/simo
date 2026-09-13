package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"simo-server/internal/config"
	"simo-server/internal/repository"
)

// main executes database migration scripts against the configured PostgreSQL instance.
func main() {
	var migrationDir string
	flag.StringVar(&migrationDir, "dir", "migrations", "Path to migrations directory")
	flag.Parse()

	cfg := config.Load()
	if cfg.DatabaseURL == "" {
		log.Fatal("Error: DATABASE_URL is not configured in environment or .env file")
	}

	pool, err := repository.InitDB(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Database connection failed: %v", err)
	}
	defer pool.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	migrationFile := filepath.Join(migrationDir, "001_initial_schema.up.sql")
	sqlBytes, err := os.ReadFile(migrationFile)
	if err != nil {
		log.Fatalf("Failed to read migration file %s: %v", migrationFile, err)
	}

	log.Printf("Executing schema migration: %s...", migrationFile)
	if _, err := pool.Exec(ctx, string(sqlBytes)); err != nil {
		log.Fatalf("Migration failed: %v", err)
	}

	fmt.Println("Schema migration applied successfully!")
}
