package model

import (
	"reflect"
	"testing"
)

func TestFormatDaysOfWeekCSV(t *testing.T) {
	tests := []struct {
		name string
		in   []int
		want string
		nilP bool
	}{
		{
			name: "nil slice returns nil",
			in:   nil,
			nilP: true,
		},
		{
			name: "empty slice returns nil",
			in:   []int{},
			nilP: true,
		},
		{
			name: "only out of range values returns nil",
			in:   []int{0, 8, -1},
			nilP: true,
		},
		{
			name: "unsorted with duplicates and invalid values is normalized",
			in:   []int{5, 1, 3, 1, 9, 2, 4, 0},
			want: "1,2,3,4,5",
		},
		{
			name: "weekends preset",
			in:   []int{7, 6},
			want: "6,7",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := FormatDaysOfWeekCSV(tc.in)
			if tc.nilP {
				if got != nil {
					t.Fatalf("expected nil, got %q", *got)
				}
				return
			}
			if got == nil {
				t.Fatalf("expected %q, got nil", tc.want)
			}
			if *got != tc.want {
				t.Fatalf("expected %q, got %q", tc.want, *got)
			}
		})
	}
}

func TestParseDaysOfWeekCSV(t *testing.T) {
	strPtr := func(s string) *string { return &s }

	tests := []struct {
		name string
		in   *string
		want []int
	}{
		{
			name: "nil returns nil",
			in:   nil,
			want: nil,
		},
		{
			name: "blank string returns nil",
			in:   strPtr("   "),
			want: nil,
		},
		{
			name: "canonical weekdays",
			in:   strPtr("1,2,3,4,5"),
			want: []int{1, 2, 3, 4, 5},
		},
		{
			name: "unordered with whitespace, duplicates, and invalid tokens",
			in:   strPtr(" 7, 6, invalid, 6, 0, 8 "),
			want: []int{6, 7},
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := ParseDaysOfWeekCSV(tc.in)
			if !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("expected %v, got %v", tc.want, got)
			}
		})
	}
}
