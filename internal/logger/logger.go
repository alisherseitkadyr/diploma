package logger

import "log"

func Warn(format string, args ...any) {
	log.Printf("[WARN] "+format, args...)
}

func Error(format string, args ...any) {
	log.Printf("[ERROR] "+format, args...)
}
