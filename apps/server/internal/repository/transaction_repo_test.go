package repository

import "testing"

func TestTransactionFilter_Normalize(t *testing.T) {
	tests := []struct {
		name                string
		in                  TransactionFilter
		wantPage, wantLimit int
	}{
		{name: "zero values get defaults", in: TransactionFilter{}, wantPage: 1, wantLimit: defaultTransactionPageSize},
		{name: "negative values get defaults", in: TransactionFilter{Page: -3, Limit: -1}, wantPage: 1, wantLimit: defaultTransactionPageSize},
		{name: "oversized limit is capped", in: TransactionFilter{Page: 2, Limit: 1_000_000}, wantPage: 2, wantLimit: maxTransactionPageSize},
		{name: "valid values kept", in: TransactionFilter{Page: 4, Limit: 50}, wantPage: 4, wantLimit: 50},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			f := tc.in
			f.Normalize()
			if f.Page != tc.wantPage || f.Limit != tc.wantLimit {
				t.Fatalf("got page=%d limit=%d, want page=%d limit=%d", f.Page, f.Limit, tc.wantPage, tc.wantLimit)
			}
		})
	}
}
