package repository

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// InitDB creates and verifies a new PostgreSQL connection pool using pgxpool.
//
// @param databaseURL PostgreSQL connection string loaded from environment
// @returns *pgxpool.Pool instance and error if connection fails
func InitDB(databaseURL string) (*pgxpool.Pool, error) {
	if databaseURL == "" {
		return nil, fmt.Errorf("database URL is empty")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database configuration: %w", err)
	}

	// Pool tuning parameters
	config.MaxConns = 25
	config.MinConns = 2
	config.MaxConnLifetime = 1 * time.Hour
	config.MaxConnIdleTime = 15 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("failed to create database connection pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return pool, nil
}

// InitDBWithRetry calls InitDB until it succeeds or maxWait elapses, doubling the delay between
// attempts (capped at 5s). It exists because on host reboot the database container may come up
// after the API container, and a single failed ping must not leave the API permanently degraded.
//
// @param ctx context.Context cancelling the wait (e.g. on shutdown signal)
// @param databaseURL PostgreSQL connection string
// @param maxWait total time budget for all attempts
// @returns *pgxpool.Pool on success, or the last connection error once the budget is exhausted
func InitDBWithRetry(ctx context.Context, databaseURL string, maxWait time.Duration) (*pgxpool.Pool, error) {
	deadline := time.Now().Add(maxWait)
	delay := 500 * time.Millisecond
	for attempt := 1; ; attempt++ {
		pool, err := InitDB(databaseURL)
		if err == nil {
			return pool, nil
		}
		if time.Now().Add(delay).After(deadline) {
			return nil, fmt.Errorf("database unreachable after %d attempts: %w", attempt, err)
		}
		log.Printf("Database not ready (attempt %d), retrying in %s: %v", attempt, delay, err)
		select {
		case <-ctx.Done():
			return nil, fmt.Errorf("database connection aborted: %w", ctx.Err())
		case <-time.After(delay):
		}
		delay = min(delay*2, 5*time.Second)
	}
}
