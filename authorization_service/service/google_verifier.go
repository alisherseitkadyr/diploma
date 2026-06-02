package service

import "context"

type GoogleUserInfo struct {
	Sub           string
	Email         string
	EmailVerified bool
	Name          string
}

type GoogleVerifier interface {
	VerifyIDToken(ctx context.Context, idToken string) (*GoogleUserInfo, error)
}
