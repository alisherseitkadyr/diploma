package validation

import (
	"diplomaBackend/authorization_service/dto"
	"net/mail"
	"regexp"
	"strings"
	"unicode"
	"unicode/utf8"

	authErrors "diplomaBackend/authorization_service/errors"
)

var (
	passwordRegex = regexp.MustCompile(`^[A-Za-z0-9@!_#$%^&*?.+\-=<>]+$`)
	digitRegex    = regexp.MustCompile(`[0-9]`)
)

func NormalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

func NormalizeUsername(nickname string) string {
	return strings.Join(strings.Fields(strings.TrimSpace(nickname)), " ")
}

func ValidateRegisterInput(input dto.RegisterInput) error {
	if err := ValidateUsername(input.Username); err != nil {
		return err
	}

	if err := ValidateEmail(input.Email); err != nil {
		return err
	}

	if err := ValidatePassword(input.Password); err != nil {
		return err
	}

	return nil
}

func ValidateLoginInput(input dto.LoginInput) error {
	if err := ValidateEmail(input.Email); err != nil {
		return err
	}

	if err := ValidatePassword(input.Password); err != nil {
		return err
	}

	return nil
}

func ValidateEmail(email string) error {
	email = NormalizeEmail(email)

	if email == "" {
		return authErrors.ErrEmptyEmail
	}

	if len(email) > 254 {
		return authErrors.ErrInvalidEmailFormat
	}

	addr, err := mail.ParseAddress(email)
	if err != nil || addr.Address != email {
		return authErrors.ErrInvalidEmailFormat
	}

	parts := strings.Split(email, "@")
	if len(parts) != 2 {
		return authErrors.ErrInvalidEmailFormat
	}

	localPart := parts[0]
	domainPart := parts[1]

	if localPart == "" || domainPart == "" {
		return authErrors.ErrInvalidEmailFormat
	}

	if strings.HasPrefix(localPart, ".") || strings.HasSuffix(localPart, ".") {
		return authErrors.ErrInvalidEmailFormat
	}

	if strings.Contains(localPart, "..") || strings.Contains(domainPart, "..") {
		return authErrors.ErrInvalidEmailFormat
	}

	domainLabels := strings.Split(domainPart, ".")
	if len(domainLabels) < 2 || len(domainLabels) > 3 {
		return authErrors.ErrInvalidEmailFormat
	}

	for _, label := range domainLabels {
		if label == "" {
			return authErrors.ErrInvalidEmailFormat
		}
		if strings.HasPrefix(label, "-") || strings.HasSuffix(label, "-") {
			return authErrors.ErrInvalidEmailFormat
		}
	}

	tld := domainLabels[len(domainLabels)-1]
	if len(tld) < 2 || len(tld) > 10 {
		return authErrors.ErrInvalidEmailFormat
	}

	return nil
}

func ValidatePassword(password string) error {
	if password == "" {
		return authErrors.ErrEmptyPassword
	}

	if len(password) < 5 {
		return authErrors.ErrPasswordTooShort
	}

	if strings.ContainsAny(password, " \t\n\r,") {
		return authErrors.ErrPasswordInvalidChars
	}

	if !passwordRegex.MatchString(password) {
		return authErrors.ErrPasswordInvalidChars
	}

	if !digitRegex.MatchString(password) {
		return authErrors.ErrPasswordMustHaveDigit
	}

	return nil
}

func ValidateUsername(nickname string) error {
	nickname = NormalizeUsername(nickname)

	if nickname == "" {
		return authErrors.ErrEmptyUsername
	}

	length := utf8.RuneCountInString(nickname)
	if length < 2 {
		return authErrors.ErrUsernameTooShort
	}
	if length > 20 {
		return authErrors.ErrUsernameTooLong
	}

	for _, r := range nickname {
		if !isAllowedNicknameRune(r) {
			return authErrors.ErrUsernameBadSymbols
		}
	}

	return nil
}

func isAllowedNicknameRune(r rune) bool {
	if unicode.IsLetter(r) || unicode.IsDigit(r) {
		return true
	}

	switch r {
	case ' ', '_', '-', '.', '\u200d', '\ufe0f':
		return true
	}

	if unicode.IsControl(r) {
		return false
	}

	return true
}
