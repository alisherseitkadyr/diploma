package service

type PasswordService interface {
	Hash(password string) (string, error)
	Compare(hash string, password string) error
}
