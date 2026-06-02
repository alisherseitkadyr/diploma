package response

import (
	"encoding/json"
	"log"
	"net/http"
)

type ErrorResponse struct {
	Error ErrorBody `json:"error"`
}

type ErrorBody struct {
	Code string `json:"code"`
}

func WriteJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(data); err != nil {
		log.Println("failed to encode response:", err)
	}
}

func WriteError(w http.ResponseWriter, status int, code string) {
	WriteJSON(w, status, ErrorResponse{
		Error: ErrorBody{
			Code: code,
		},
	})
}
