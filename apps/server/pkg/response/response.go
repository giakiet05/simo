package response

import (
	"encoding/json"
	"net/http"
)

// Envelope defines the standard API JSON response envelope.
type Envelope struct {
	Message   string `json:"message"`
	Data      any    `json:"data,omitempty"`
	ErrorCode string `json:"error_code,omitempty"`
}

// JSON sends a standard JSON response with the given status code and payload.
//
// @param w http.ResponseWriter
// @param status HTTP status code (e.g. 200, 201)
// @param message Human-readable message for debugging
// @param data Payload to return (can be nil)
func JSON(w http.ResponseWriter, status int, message string, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(Envelope{
		Message: message,
		Data:    data,
	})
}

// Error sends a standardized JSON error response.
//
// @param w http.ResponseWriter
// @param status HTTP error status code (e.g. 400, 401, 500)
// @param message Error description message
// @param errorCode Machine-readable error code string
func Error(w http.ResponseWriter, status int, message string, errorCode string) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(Envelope{
		Message:   message,
		ErrorCode: errorCode,
	})
}
