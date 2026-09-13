package model_test

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"simo-server/internal/model"
)

func TestFlexibleTime_UnmarshalJSON(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected time.Time
		wantErr  bool
	}{
		{
			name:     "RFC3339 with Z",
			input:    `"2026-09-13T18:04:50Z"`,
			expected: time.Date(2026, 9, 13, 18, 4, 50, 0, time.UTC),
		},
		{
			name:     "RFC3339Nano with Z",
			input:    `"2026-09-13T18:04:50.123456Z"`,
			expected: time.Date(2026, 9, 13, 18, 4, 50, 123456000, time.UTC),
		},
		{
			name:     "ISO8601 without timezone offset",
			input:    `"2026-09-13T18:04:50.123456"`,
			expected: time.Date(2026, 9, 13, 18, 4, 50, 123456000, time.UTC),
		},
		{
			name:     "ISO8601 with timezone offset",
			input:    `"2026-09-13T18:04:50+07:00"`,
			expected: time.Date(2026, 9, 13, 11, 4, 50, 0, time.UTC),
		},
		{
			name:     "Datetime space separated",
			input:    `"2026-09-13 18:04:50"`,
			expected: time.Date(2026, 9, 13, 18, 4, 50, 0, time.UTC),
		},
		{
			name:     "Date only",
			input:    `"2026-09-13"`,
			expected: time.Date(2026, 9, 13, 0, 0, 0, 0, time.UTC),
		},
		{
			name:     "Empty string",
			input:    `""`,
			expected: time.Time{},
		},
		{
			name:     "Null value",
			input:    `null`,
			expected: time.Time{},
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			var ft model.FlexibleTime
			err := json.Unmarshal([]byte(tc.input), &ft)
			if tc.wantErr {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
				if tc.expected.IsZero() {
					assert.True(t, ft.IsZero())
				} else {
					assert.Equal(t, tc.expected, ft.Time)
				}
			}
		})
	}
}
