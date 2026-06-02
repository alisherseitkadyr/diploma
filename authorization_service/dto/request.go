package dto

type RegisterInput struct {
	Email    string
	Username string
	Password string
}

type LoginInput struct {
	Email    string
	Password string
}

type GoogleLoginInput struct {
	IDToken string
}

type ChangePasswordInput struct {
	CurrentPassword string
	NewPassword     string
	RefreshToken    string
}

type ChangeUsernameInput struct {
	NewUsername string
}
