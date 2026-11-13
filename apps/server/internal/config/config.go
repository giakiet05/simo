package config

import (
	"cmp"
	"errors"
	"log"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

// minJWTSecretLength is the minimum accepted HMAC secret length in production.
const minJWTSecretLength = 32

// DefaultGoogleClientID is Simo's public web OAuth client ID. It is not a secret (it ships inside
// the mobile and web apps) and is used as the token audience when GOOGLE_CLIENT_ID is unset.
const DefaultGoogleClientID = "249729017539-b22m2t1b958l3d24olhp249h3r26bn6a.apps.googleusercontent.com"

// knownInsecureJWTSecrets lists secrets that were ever committed to the public repository.
// A production instance must never sign tokens with any of them.
var knownInsecureJWTSecrets = map[string]bool{
	"simo_jwt_secret_key_production_2026":       true,
	"simo_super_secret_jwt_key_change_me":       true,
	"simo_default_jwt_secret_please_set_in_env": true,
}

// Config holds all configuration properties for the Simo backend service.
type Config struct {
	Port        string
	DatabaseURL string
	JWTSecret   string
	AppEnv      string
	// GoogleClientID holds one or more comma-separated OAuth client IDs accepted as token audiences.
	GoogleClientID string
	DevAuthBypass  bool
}

// GoogleAudiences returns the parsed list of accepted Google OAuth client IDs.
//
// @returns []string trimmed, non-empty client IDs
func (c *Config) GoogleAudiences() []string {
	return ParseClientIDs(c.GoogleClientID)
}

// IsProduction reports whether the service runs with APP_ENV=production.
//
// @returns bool
func (c *Config) IsProduction() bool {
	return strings.EqualFold(c.AppEnv, "production")
}

// HasWeakJWTSecret reports whether the JWT secret is short or was ever published in the repository.
// Anyone knowing the secret can forge a session token for any user.
//
// @returns bool
func (c *Config) HasWeakJWTSecret() bool {
	return len(c.JWTSecret) < minJWTSecretLength || knownInsecureJWTSecrets[c.JWTSecret]
}

// Validate checks that the configuration is safe to run with.
// In production it rejects a missing database URL, missing Google client IDs and the dev auth bypass.
// A weak JWT secret is reported separately via HasWeakJWTSecret so that rotating it does not
// require downtime.
//
// @returns error describing every violated rule, or nil
func (c *Config) Validate() error {
	if !c.IsProduction() {
		return nil
	}
	var errs []error
	if len(c.GoogleAudiences()) == 0 {
		errs = append(errs, errors.New("GOOGLE_CLIENT_ID must be set so Google ID token audiences can be verified"))
	}
	if c.DevAuthBypass {
		errs = append(errs, errors.New("DEV_AUTH_BYPASS must not be enabled in production"))
	}
	if c.DatabaseURL == "" {
		errs = append(errs, errors.New("DATABASE_URL must be set"))
	}
	return errors.Join(errs...)
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
		AppEnv:         os.Getenv("APP_ENV"),
		GoogleClientID: cmp.Or(os.Getenv("GOOGLE_CLIENT_ID"), DefaultGoogleClientID),
		DevAuthBypass:  devAuthBypass,
	}
}

// ParseClientIDs splits a comma-separated list of Google OAuth client IDs, dropping blanks.
//
// @param raw comma-separated client IDs
// @returns []string trimmed, non-empty client IDs
func ParseClientIDs(raw string) []string {
	var ids []string
	for _, part := range strings.Split(raw, ",") {
		if id := strings.TrimSpace(part); id != "" {
			ids = append(ids, id)
		}
	}
	return ids
}
