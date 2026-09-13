package middleware

import (
	"log"
	"net/http"
	"runtime/debug"

	"simo-server/pkg/response"
)

// Recovery returns a middleware that recovers from unexpected panics and returns 500 error.
//
// @param next http.Handler
// @returns http.Handler wrapped with panic recovery
func Recovery(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("[PANIC] %v\nStack trace:\n%s", err, string(debug.Stack()))
				response.Error(w, http.StatusInternalServerError, "Internal server error occurred", "INTERNAL_ERROR")
			}
		}()

		next.ServeHTTP(w, r)
	})
}
