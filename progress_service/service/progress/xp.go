package progress

import "diplomaBackend/progress_service/model"

func CalculateQuizXP(quizType string, scorePercent float64) int {
	switch quizType {
	case model.QuizTypeTopicFinalQuiz:
		return CalculateTopicFinalQuizXP(scorePercent)
	default:
		return CalculateSubtopicQuizXP(scorePercent)
	}
}

func CalculateSubtopicQuizXP(scorePercent float64) int {
	switch {
	case scorePercent >= 100:
		return 15
	case scorePercent >= 50:
		return 10
	default:
		return 5
	}
}

func CalculateTopicFinalQuizXP(scorePercent float64) int {
	if scorePercent >= 75 {
		return 50
	}

	return 10
}

func CalculateProgressLevel(totalXP int) string {
	switch {
	case totalXP >= 260:
		return model.ProgressLevelAdvancedLearner
	case totalXP >= 150:
		return model.ProgressLevelPractitioner
	case totalXP >= 60:
		return model.ProgressLevelAmateur
	default:
		return model.ProgressLevelBeginner
	}
}
