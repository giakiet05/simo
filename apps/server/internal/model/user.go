package model

import (
	"time"

	"github.com/google/uuid"
)

// User represents a registered user account in PostgreSQL.
type User struct {
	ID          uuid.UUID `json:"id"`
	Email       string    `json:"email"`
	GoogleID    *string   `json:"google_id,omitempty"`
	DisplayName *string   `json:"display_name,omitempty"`
	AvatarURL   *string   `json:"avatar_url,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// UserSettings represents global user preferences.
type UserSettings struct {
	UserID          uuid.UUID `json:"user_id"`
	Currency        string    `json:"currency"`
	Language        string    `json:"language"`
	ThemeMode       string    `json:"theme_mode"`
	MonthlyBudget   float64   `json:"monthly_budget"`
	ServerUpdatedAt time.Time `json:"server_updated_at"`
}
