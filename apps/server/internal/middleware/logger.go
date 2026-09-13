package middleware

import (
	"log"
	"net/http"
	"time"
)

// responseWriterWrapper wraps http.ResponseWriter to capture status code.
type responseWriterWrapper struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriterWrapper) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// Flush forwards flush calls to the underlying ResponseWriter if supported.
func (rw *responseWriterWrapper) Flush() {
	if flusher, ok := rw.ResponseWriter.(http.Flusher); ok {
		flusher.Flush()
	}
}

// Unwrap returns the underlying ResponseWriter for http.ResponseController support.
func (rw *responseWriterWrapper) Unwrap() http.ResponseWriter {
	return rw.ResponseWriter
}

// Logger returns a middleware that logs structured HTTP request details.
//
// @param next http.Handler
// @returns http.Handler wrapped with request logging
func Logger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		wrapper := &responseWriterWrapper{ResponseWriter: w, statusCode: http.StatusOK}

		next.ServeHTTP(wrapper, r)

		duration := time.Since(start)
		log.Printf("[HTTP] %s %s %d %s %s",
			r.Method,
			r.URL.Path,
			wrapper.statusCode,
			duration,
			r.RemoteAddr,
		)
	})
}
