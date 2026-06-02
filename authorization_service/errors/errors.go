package errors

import "errors"

var (
	ErrUserNotFound         = errors.New("USER_NOT_FOUND")
	ErrInvalidCredentials   = errors.New("INVALID_CREDENTIALS")
	ErrEmailAlreadyExists   = errors.New("EMAIL_ALREADY_EXISTS")
	ErrInactiveUser         = errors.New("INACTIVE_USER")
	ErrRefreshTokenExpired  = errors.New("REFRESH_TOKEN_EXPIRED")
	ErrRefreshTokenRevoked  = errors.New("REFRESH_TOKEN_REVOKED")
	ErrRefreshTokenNotFound = errors.New("REFRESH_TOKEN_NOT_FOUND")
	ErrInvalidRefreshToken  = errors.New("INVALID_REFRESH_TOKEN")

	ErrEmptyUsername         = errors.New("EMPTY_USERNAME")
	ErrEmptyEmail            = errors.New("EMPTY_EMAIL")
	ErrInvalidEmailFormat    = errors.New("INVALID_EMAIL_FORMAT")
	ErrEmptyPassword         = errors.New("EMPTY_PASSWORD")
	ErrPasswordTooShort      = errors.New("PASSWORD_TOO_SHORT")
	ErrPasswordMustHaveDigit = errors.New("PASSWORD_MUST_HAVE_DIGIT")
	ErrPasswordInvalidChars  = errors.New("PASSWORD_INVALID_CHARS")

	ErrUsernameTooShort      = errors.New("USERNAME_TOO_SHORT")
	ErrUsernameTooLong       = errors.New("USERNAME_TOO_LONG")
	ErrUsernameBadSymbols    = errors.New("USERNAME_BAD_SYMBOLS")
	ErrUsernameSameAsCurrent = errors.New("USERNAME_SAME_AS_CURRENT")
	ErrInvalidUsername       = errors.New("INVALID_USERNAME")
	ErrPasswordSameAsCurrent = errors.New("PASSWORD_SAME_AS_CURRENT")

	ErrOAuthAccountNotFound     = errors.New("OAUTH_ACCOUNT_NOT_FOUND")
	ErrInvalidGoogleToken       = errors.New("INVALID_GOOGLE_TOKEN")
	ErrGoogleEmailNotVerified   = errors.New("GOOGLE_EMAIL_NOT_VERIFIED")
	ErrGoogleEmailAlreadyExists = errors.New("GOOGLE_EMAIL_ALREADY_EXISTS")
	
	ErrUserLoginSecurityNotFound = errors.New("USER_LOGIN_SECURITY_NOT_FOUND")
	ErrTooManyLoginAttempts      = errors.New("TOO_MANY_LOGIN_ATTEMPTS")
)
