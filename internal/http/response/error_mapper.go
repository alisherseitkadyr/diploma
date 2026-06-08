package response

import (
	adaptationErrors "diplomaBackend/adaptation_service/errors"
	assessmentErrors "diplomaBackend/assessment_service/errors"
	authErrors "diplomaBackend/authorization_service/errors"
	contentErrors "diplomaBackend/content_service/errors"
	progressErrors "diplomaBackend/progress_service/errors"
	profileErrors "diplomaBackend/user_profile_service/errors"
	"errors"
	"net/http"
)

type AppError struct {
	Status int
	Code   string
}

func MapError(err error) AppError {
	switch {
	case err == nil:
		return AppError{
			Status: http.StatusInternalServerError,
			Code:   "INTERNAL_ERROR",
		}

	case errors.Is(err, authErrors.ErrEmptyUsername),
		errors.Is(err, authErrors.ErrEmptyEmail),
		errors.Is(err, authErrors.ErrInvalidEmailFormat),
		errors.Is(err, authErrors.ErrEmptyPassword),
		errors.Is(err, authErrors.ErrPasswordTooShort),
		errors.Is(err, authErrors.ErrPasswordMustHaveDigit),
		errors.Is(err, authErrors.ErrPasswordInvalidChars),
		errors.Is(err, authErrors.ErrUsernameTooShort),
		errors.Is(err, authErrors.ErrUsernameTooLong),
		errors.Is(err, authErrors.ErrUsernameBadSymbols),
		errors.Is(err, authErrors.ErrUsernameSameAsCurrent),
		errors.Is(err, authErrors.ErrInvalidUsername),
		errors.Is(err, authErrors.ErrPasswordSameAsCurrent),

		errors.Is(err, profileErrors.ErrPreferredTopicsRequired),
		errors.Is(err, profileErrors.ErrInvalidFinancialLiteracyLevel),
		errors.Is(err, profileErrors.ErrInvalidPracticalExperience),
		errors.Is(err, profileErrors.ErrInvalidLearningGoal),
		errors.Is(err, profileErrors.ErrInvalidPreferredLanguage),
		errors.Is(err, profileErrors.ErrInvalidTimeCommitment),
		errors.Is(err, profileErrors.ErrInvalidPreferredTopic),
		errors.Is(err, profileErrors.ErrInvalidTheme),
		errors.Is(err, profileErrors.ErrInvalidReminderTime),

		errors.Is(err, contentErrors.ErrInvalidLanguageCode),

		errors.Is(err, progressErrors.ErrInvalidUserID),
		errors.Is(err, progressErrors.ErrInvalidQuizCode),
		errors.Is(err, progressErrors.ErrInvalidMaxScorePoints),
		errors.Is(err, progressErrors.ErrInvalidScorePoints),
		errors.Is(err, progressErrors.ErrInvalidScorePercent),

		errors.Is(err, adaptationErrors.ErrInvalidUserID),
		errors.Is(err, adaptationErrors.ErrInvalidAttemptID),

		errors.Is(err, assessmentErrors.ErrInvalidLanguageCode),
		errors.Is(err, assessmentErrors.ErrInvalidQuizID),
		errors.Is(err, assessmentErrors.ErrInvalidAttemptID),
		errors.Is(err, assessmentErrors.ErrInvalidQuestionID),
		errors.Is(err, assessmentErrors.ErrInvalidOptionID),
		errors.Is(err, assessmentErrors.ErrIncompleteQuizAttempt),
		errors.Is(err, assessmentErrors.ErrDuplicateQuestion),
		errors.Is(err, assessmentErrors.ErrEmptySelectedOptions),
		errors.Is(err, assessmentErrors.ErrInvalidSelectedCount),
		errors.Is(err, assessmentErrors.ErrAttemptAlreadyCompleted),
		errors.Is(err, assessmentErrors.ErrAttemptNotInProgress),
		errors.Is(err, assessmentErrors.ErrInvalidAttemptQuestion),
		errors.Is(err, assessmentErrors.ErrNotEnoughQuizQuestions),
		errors.Is(err, assessmentErrors.ErrAttemptExpired),
		errors.Is(err, adaptationErrors.ErrInvalidUserID),
		errors.Is(err, adaptationErrors.ErrInvalidAttemptID):
		return AppError{
			Status: http.StatusBadRequest,
			Code:   err.Error(),
		}

	case errors.Is(err, authErrors.ErrInvalidCredentials),
		errors.Is(err, authErrors.ErrInvalidRefreshToken),
		errors.Is(err, authErrors.ErrRefreshTokenExpired),
		errors.Is(err, authErrors.ErrRefreshTokenRevoked),
		errors.Is(err, authErrors.ErrRefreshTokenNotFound),
		errors.Is(err, authErrors.ErrInvalidGoogleToken):
		return AppError{
			Status: http.StatusUnauthorized,
			Code:   err.Error(),
		}

	case errors.Is(err, authErrors.ErrInactiveUser),
		errors.Is(err, authErrors.ErrGoogleEmailNotVerified):
		return AppError{
			Status: http.StatusForbidden,
			Code:   err.Error(),
		}

	case errors.Is(err, authErrors.ErrUserNotFound),
		errors.Is(err, authErrors.ErrOAuthAccountNotFound),

		errors.Is(err, profileErrors.ErrProfileNotFound),
		errors.Is(err, profileErrors.ErrSettingsNotFound),

		errors.Is(err, contentErrors.ErrTopicNotFound),
		errors.Is(err, contentErrors.ErrSubtopicNotFound),
		errors.Is(err, contentErrors.ErrLessonNotFound),
		errors.Is(err, contentErrors.ErrNoTipsFound),

		errors.Is(err, progressErrors.ErrUserProgressNotFound),
		errors.Is(err, progressErrors.ErrLearningStatsNotFound),

		errors.Is(err, adaptationErrors.ErrReinforcementFeaturesNotFound),

		errors.Is(err, assessmentErrors.ErrQuizNotFound),
		errors.Is(err, assessmentErrors.ErrAttemptNotFound),
		errors.Is(err, adaptationErrors.ErrRecommendationDataNotFound),
		errors.Is(err, adaptationErrors.ErrTopicNotFound):
		return AppError{
			Status: http.StatusNotFound,
			Code:   err.Error(),
		}

	case errors.Is(err, authErrors.ErrEmailAlreadyExists),
		errors.Is(err, authErrors.ErrGoogleEmailAlreadyExists),
		errors.Is(err, profileErrors.ErrProfileAlreadyCompleted):
		return AppError{
			Status: http.StatusConflict,
			Code:   err.Error(),
		}

	case errors.Is(err, authErrors.ErrTooManyLoginAttempts):
		return AppError{
			Status: http.StatusTooManyRequests,
			Code:   err.Error(),
		}

	default:
		return AppError{
			Status: http.StatusInternalServerError,
			Code:   "INTERNAL_ERROR",
		}
	}
}

func WriteAppError(w http.ResponseWriter, err error) {
	appErr := MapError(err)
	WriteError(w, appErr.Status, appErr.Code)
}
