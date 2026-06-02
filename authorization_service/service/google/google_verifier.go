package google

import (
	"context"
	"fmt"

	authErrors "diplomaBackend/authorization_service/errors"
	"diplomaBackend/authorization_service/service"

	"google.golang.org/api/idtoken"
)

type Verifier struct {
	clientID string
}

func NewVerifier(clientID string) *Verifier {
	return &Verifier{clientID: clientID}
}

func (v *Verifier) VerifyIDToken(ctx context.Context, idToken string) (*service.GoogleUserInfo, error) {
	payload, err := idtoken.Validate(ctx, idToken, v.clientID)
	if err != nil {
		return nil, authErrors.ErrInvalidGoogleToken
	}

	sub, _ := payload.Claims["sub"].(string)
	email, _ := payload.Claims["email"].(string)
	name, _ := payload.Claims["name"].(string)

	emailVerified := false
	switch val := payload.Claims["email_verified"].(type) {
	case bool:
		emailVerified = val
	case string:
		emailVerified = val == "true"
	}

	if sub == "" || email == "" {
		return nil, fmt.Errorf("google token missing required claims")
	}

	return &service.GoogleUserInfo{
		Sub:           sub,
		Email:         email,
		EmailVerified: emailVerified,
		Name:          name,
	}, nil
}
