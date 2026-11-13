package config

import (
	"strings"
	"testing"
)

// validProductionConfig returns a production config that passes every Validate rule.
func validProductionConfig() *Config {
	return &Config{
		AppEnv:         "production",
		DatabaseURL:    "postgres://u:p@db:5432/simo",
		JWTSecret:      strings.Repeat("x", 48),
		GoogleClientID: "web-client.apps.googleusercontent.com",
	}
}

func TestValidate_Production(t *testing.T) {
	tests := []struct {
		name    string
		mutate  func(c *Config)
		wantErr string
	}{
		{name: "valid config passes", mutate: func(c *Config) {}},
		{
			name:    "missing google client id rejected",
			mutate:  func(c *Config) { c.GoogleClientID = " , " },
			wantErr: "GOOGLE_CLIENT_ID",
		},
		{
			name:    "dev bypass rejected",
			mutate:  func(c *Config) { c.DevAuthBypass = true },
			wantErr: "DEV_AUTH_BYPASS",
		},
		{
			name:    "missing database url rejected",
			mutate:  func(c *Config) { c.DatabaseURL = "" },
			wantErr: "DATABASE_URL",
		},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			cfg := validProductionConfig()
			tc.mutate(cfg)
			err := cfg.Validate()
			if tc.wantErr == "" {
				if err != nil {
					t.Fatalf("expected no error, got: %v", err)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), tc.wantErr) {
				t.Fatalf("expected error mentioning %q, got: %v", tc.wantErr, err)
			}
		})
	}
}

func TestValidate_NonProductionIsLenient(t *testing.T) {
	cfg := &Config{AppEnv: "development", JWTSecret: "short", DevAuthBypass: true}
	if err := cfg.Validate(); err != nil {
		t.Fatalf("expected development config to pass, got: %v", err)
	}
}

func TestGoogleAudiences(t *testing.T) {
	cfg := &Config{GoogleClientID: " web-id , ,android-id "}
	got := cfg.GoogleAudiences()
	if len(got) != 2 || got[0] != "web-id" || got[1] != "android-id" {
		t.Fatalf("unexpected audiences: %#v", got)
	}
}

func TestHasWeakJWTSecret(t *testing.T) {
	tests := map[string]bool{
		"simo_jwt_secret_key_production_2026":       true,
		"simo_default_jwt_secret_please_set_in_env": true,
		"short":                 true,
		strings.Repeat("k", 64): false,
	}
	for secret, wantWeak := range tests {
		cfg := &Config{JWTSecret: secret}
		if got := cfg.HasWeakJWTSecret(); got != wantWeak {
			t.Errorf("HasWeakJWTSecret(%q) = %v, want %v", secret, got, wantWeak)
		}
	}
}
