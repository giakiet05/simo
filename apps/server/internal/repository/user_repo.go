package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"simo-server/internal/model"
)

// UserRepositoryInterface defines repository contract for user management.
type UserRepositoryInterface interface {
	UpsertUserByGoogleID(ctx context.Context, googleID, email string, displayName, avatarURL *string) (*model.User, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (*model.User, error)
	GetUserByGoogleID(ctx context.Context, googleID string) (*model.User, error)
}

// UserRepository handles user persistence operations in PostgreSQL.
type UserRepository struct {
	pool *pgxpool.Pool
}

// NewUserRepository creates a new UserRepository instance.
//
// @param pool *pgxpool.Pool database connection pool
// @returns *UserRepository
func NewUserRepository(pool *pgxpool.Pool) *UserRepository {
	return &UserRepository{pool: pool}
}

// UpsertUserByGoogleID inserts or updates a user account identified by Google sub identifier.
//
// @param ctx context.Context request context
// @param googleID string Google subject identifier (sub)
// @param email string User email address
// @param displayName *string User full name from Google profile
// @param avatarURL *string User avatar URL from Google profile
// @returns *model.User, error
func (r *UserRepository) UpsertUserByGoogleID(ctx context.Context, googleID, email string, displayName, avatarURL *string) (*model.User, error) {
	query := `
		INSERT INTO users (google_id, email, display_name, avatar_url, updated_at)
		VALUES ($1, $2, $3, $4, NOW() AT TIME ZONE 'UTC')
		ON CONFLICT (google_id) DO UPDATE SET
			email = EXCLUDED.email,
			display_name = COALESCE(EXCLUDED.display_name, users.display_name),
			avatar_url = COALESCE(EXCLUDED.avatar_url, users.avatar_url),
			updated_at = NOW() AT TIME ZONE 'UTC'
		RETURNING id, email, google_id, display_name, avatar_url, created_at, updated_at;
	`

	var user model.User
	err := r.pool.QueryRow(ctx, query, googleID, email, displayName, avatarURL).Scan(
		&user.ID,
		&user.Email,
		&user.GoogleID,
		&user.DisplayName,
		&user.AvatarURL,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to upsert user by google id: %w", err)
	}

	return &user, nil
}

// GetUserByID retrieves a user record by its primary key UUID.
//
// @param ctx context.Context request context
// @param id uuid.UUID user UUID
// @returns *model.User, error (returns nil, nil if not found)
func (r *UserRepository) GetUserByID(ctx context.Context, id uuid.UUID) (*model.User, error) {
	query := `
		SELECT id, email, google_id, display_name, avatar_url, created_at, updated_at
		FROM users
		WHERE id = $1;
	`

	var user model.User
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&user.ID,
		&user.Email,
		&user.GoogleID,
		&user.DisplayName,
		&user.AvatarURL,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to query user by id: %w", err)
	}

	return &user, nil
}

// GetUserByGoogleID retrieves a user record by its Google subject identifier.
//
// @param ctx context.Context request context
// @param googleID string Google subject identifier
// @returns *model.User, error (returns nil, nil if not found)
func (r *UserRepository) GetUserByGoogleID(ctx context.Context, googleID string) (*model.User, error) {
	query := `
		SELECT id, email, google_id, display_name, avatar_url, created_at, updated_at
		FROM users
		WHERE google_id = $1;
	`

	var user model.User
	err := r.pool.QueryRow(ctx, query, googleID).Scan(
		&user.ID,
		&user.Email,
		&user.GoogleID,
		&user.DisplayName,
		&user.AvatarURL,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to query user by google id: %w", err)
	}

	return &user, nil
}
