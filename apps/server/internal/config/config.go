package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

// Config holds all configuration properties for the Simo backend service.
type Config struct {
	Port         string
	DatabaseURL  string
	JWTSecret    string
	GoogleClientID string
	DevAuthBypass  bool
}

// Load reads configuration from environment variables, optionally falling back to a local .env file.
//
// @returns *Config with loaded values
func Load() *Config {
	// Attempt to load local .env file if it exists; ignore error if not found in production
	if err := godotenv.Load(); err != nil {
		log.Println("Note: .env file not found or could not be loaded, using environment variables")
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Println("WARNING: DATABASE_URL environment variable is empty. Database connections will fail.")
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "simo_default_jwt_secret_please_set_in_env"
	}

	devAuthBypass := os.Getenv("DEV_AUTH_BYPASS") == "true" || os.Getenv("DEV_AUTH_BYPASS") == "1"

	return &Config{
		Port:           port,
		DatabaseURL:    dbURL,
		JWTSecret:      jwtSecret,
		GoogleClientID: os.Getenv("GOOGLE_CLIENT_ID"),
		DevAuthBypass:  devAuthBypass,
	}
}
