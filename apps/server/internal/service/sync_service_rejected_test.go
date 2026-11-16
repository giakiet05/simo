package service

import (
	"maps"
	"testing"

	"simo-server/internal/model"
)

// TestCountRejectedByTable verifies rejected records are grouped per table for logging.
func TestCountRejectedByTable(t *testing.T) {
	tests := []struct {
		name     string
		rejected []model.RejectedRecord
		want     map[string]int
	}{
		{name: "empty", rejected: nil, want: map[string]int{}},
		{
			name: "grouped",
			rejected: []model.RejectedRecord{
				{Table: "wallets", ID: "a"},
				{Table: "transactions", ID: "b"},
				{Table: "transactions", ID: "c"},
			},
			want: map[string]int{"wallets": 1, "transactions": 2},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := countRejectedByTable(tt.rejected); !maps.Equal(got, tt.want) {
				t.Fatalf("countRejectedByTable() = %v, want %v", got, tt.want)
			}
		})
	}
}
