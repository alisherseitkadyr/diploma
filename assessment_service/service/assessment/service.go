package assessment

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"time"

	adaptationService "diplomaBackend/adaptation_service/service"
	"diplomaBackend/assessment_service/dto"
	assessmentErrors "diplomaBackend/assessment_service/errors"
	"diplomaBackend/assessment_service/model"
	"diplomaBackend/assessment_service/repository"
	"diplomaBackend/assessment_service/service"
	"diplomaBackend/internal/logger"
	progressService "diplomaBackend/progress_service/service"
)

type Service struct {
	assessmentRepo    repository.AssessmentRepository
	txManager         repository.TxManager
	progressService   progressService.ProgressService
	adaptationService adaptationService.AdaptationService
}

func NewService(
	assessmentRepo repository.AssessmentRepository,
	txManager repository.TxManager,
	progressService progressService.ProgressService,
	adaptationService adaptationService.AdaptationService,
) service.AssessmentService {
	return &Service{
		assessmentRepo:    assessmentRepo,
		txManager:         txManager,
		progressService:   progressService,
		adaptationService: adaptationService,
	}
}

func (s *Service) GetQuizByID(ctx context.Context, quizID int64, languageCode string) (*dto.QuizResponse, error) {
	if quizID <= 0 {
		return nil, assessmentErrors.ErrInvalidQuizID
	}

	if !isSupportedLanguage(languageCode) {
		return nil, assessmentErrors.ErrInvalidLanguageCode
	}

	quiz, err := s.assessmentRepo.GetQuizByID(ctx, quizID, languageCode)
	if err != nil {
		if !errors.Is(err, assessmentErrors.ErrQuizNotFound) {
			logger.Error("assessment service: failed to get quiz: quiz_id=%d language_code=%s err=%v", quizID, languageCode, err)
		}
		return nil, err
	}

	return quiz, nil
}

func (s *Service) StartQuiz(ctx context.Context, userID, quizID int64, languageCode string) (*dto.StartQuizResponse, error) {
	if quizID <= 0 {
		return nil, assessmentErrors.ErrInvalidQuizID
	}

	if !isSupportedLanguage(languageCode) {
		return nil, assessmentErrors.ErrInvalidLanguageCode
	}

	var response *dto.StartQuizResponse

	err := s.txManager.WithinTransaction(ctx, func(assessmentRepo repository.AssessmentRepository) error {
		meta, err := assessmentRepo.GetQuizStartMeta(ctx, quizID, languageCode)
		if err != nil {
			if !errors.Is(err, assessmentErrors.ErrQuizNotFound) {
				logger.Error("assessment service: failed to get quiz start meta: quiz_id=%d language_code=%s err=%v", quizID, languageCode, err)
			}
			return err
		}

		var questions []dto.QuestionResponse

		if meta.QuizType == model.QuizTypeTopicFinalQuiz {
			if meta.TopicCode == nil || *meta.TopicCode == "" {
				return assessmentErrors.ErrQuizNotFound
			}

			subtopicInfos, err := assessmentRepo.GetSubtopicQuizInfoByTopicCode(ctx, *meta.TopicCode)
			if err != nil {
				logger.Error("assessment service: failed to get subtopic quiz infos: topic_code=%s err=%v", *meta.TopicCode, err)
				return err
			}

			if len(subtopicInfos) > 0 {
				shares := computeShares(len(subtopicInfos), 10)
				for i, info := range subtopicInfos {
					pool, err := assessmentRepo.GetRandomQuestionsByQuizID(ctx, info.QuizID, languageCode, shares[i])
					if err != nil {
						logger.Error("assessment service: failed to get questions for subtopic: quiz_id=%d err=%v", info.QuizID, err)
						return err
					}
					questions = append(questions, pool...)
				}
				rand.Shuffle(len(questions), func(i, j int) {
					questions[i], questions[j] = questions[j], questions[i]
				})
				for i := range questions {
					questions[i].OrderIndex = i + 1
				}
			}
		} else {
			questionLimit := questionLimitForQuiz(meta.QuizType, meta.TopicLevel)
			questions, err = assessmentRepo.GetRandomQuestionsByQuizID(ctx, quizID, languageCode, questionLimit)
			if err != nil {
				logger.Error("assessment service: failed to get random questions: quiz_id=%d language_code=%s err=%v", quizID, languageCode, err)
				return err
			}
			if len(questions) == 0 {
				return assessmentErrors.ErrNotEnoughQuizQuestions
			}
		}

		attempt := &model.QuizAttempt{
			UserID:          userID,
			QuizID:          quizID,
			TotalQuestions:  len(questions),
			CorrectAnswers:  0,
			WrongAnswers:    0,
			ScorePercent:    0,
			Passed:          false,
			XPForScore:      0,
			DurationSeconds: 0,
			Status:          model.AttemptStatusInProgress,
		}

		if err := assessmentRepo.CreateStartedAttempt(ctx, attempt); err != nil {
			logger.Error("assessment service: failed to create started attempt: user_id=%d quiz_id=%d err=%v", userID, quizID, err)
			return err
		}

		if err := assessmentRepo.CreateAttemptQuestions(ctx, attempt.ID, questions); err != nil {
			logger.Error("assessment service: failed to create attempt questions: attempt_id=%d err=%v", attempt.ID, err)
			return err
		}

		response = &dto.StartQuizResponse{
			AttemptID:      attempt.ID,
			QuizID:         meta.ID,
			QuizType:       meta.QuizType,
			Title:          meta.Title,
			TotalQuestions: len(questions),
			Questions:      questions,
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return response, nil
}

func (s *Service) SubmitAttempt(ctx context.Context, input service.SubmitQuizInput) (*dto.SubmitQuizResponse, error) {
	if input.AttemptID <= 0 {
		return nil, assessmentErrors.ErrInvalidAttemptID
	}

	if input.DurationSeconds < 0 {
		input.DurationSeconds = 0
	}

	expired, err := s.assessmentRepo.ExpireAttemptIfNeeded(ctx, input.UserID, input.AttemptID)
	if err != nil {
		logger.Error("assessment service: failed to expire attempt if needed: user_id=%d attempt_id=%d err=%v", input.UserID, input.AttemptID, err)
		return nil, err
	}

	if expired {
		return nil, assessmentErrors.ErrAttemptExpired
	}

	attemptData, err := s.assessmentRepo.GetAttemptCheckData(ctx, input.UserID, input.AttemptID)
	if err != nil {
		if !errors.Is(err, assessmentErrors.ErrAttemptNotFound) {
			logger.Error("assessment service: failed to get attempt check data: user_id=%d attempt_id=%d err=%v", input.UserID, input.AttemptID, err)
		}
		return nil, err
	}

	if attemptData.Status == model.AttemptStatusCompleted {
		return nil, assessmentErrors.ErrAttemptAlreadyCompleted
	}
	if attemptData.Status == model.AttemptStatusExpired {
		return nil, assessmentErrors.ErrAttemptExpired
	}
	if attemptData.Status != model.AttemptStatusInProgress {
		return nil, assessmentErrors.ErrAttemptNotInProgress
	}

	answerResults, correctCount, err := checkAnswers(attemptData.Questions, input.Answers)
	if err != nil {
		return nil, err
	}

	totalQuestions := len(attemptData.Questions)
	wrongCount := totalQuestions - correctCount
	scorePercent := correctCount * 100 / totalQuestions
	xpForScore := calculateXPForScore(attemptData.QuizType, scorePercent)

	attempt := &model.QuizAttempt{
		ID:              input.AttemptID,
		UserID:          input.UserID,
		QuizID:          attemptData.QuizID,
		TotalQuestions:  totalQuestions,
		CorrectAnswers:  correctCount,
		WrongAnswers:    wrongCount,
		ScorePercent:    scorePercent,
		Passed:          scorePercent >= attemptData.PassingScore,
		XPForScore:      xpForScore,
		DurationSeconds: input.DurationSeconds,
		Status:          model.AttemptStatusCompleted,
	}

	err = s.txManager.WithinTransaction(ctx, func(assessmentRepo repository.AssessmentRepository) error {
		for i := range answerResults {
			answerResults[i].AttemptID = input.AttemptID
		}

		if err := assessmentRepo.CreateAttemptAnswers(ctx, answerResults); err != nil {
			logger.Error("assessment service: failed to create attempt answers: user_id=%d attempt_id=%d err=%v", input.UserID, input.AttemptID, err)
			return err
		}

		if err := assessmentRepo.CompleteAttempt(ctx, attempt); err != nil {
			logger.Error("assessment service: failed to complete attempt: user_id=%d attempt_id=%d err=%v", input.UserID, input.AttemptID, err)
			return err
		}

		return nil
	})
	if err != nil {
		return nil, err
	}

	if s.progressService != nil {
		quizCode := buildQuizCode(attemptData.QuizType, attemptData.TopicCode, attemptData.SubtopicCode, attemptData.QuizID)

		err = s.progressService.ProcessQuizResult(ctx, progressService.ProcessQuizResultInput{
			UserID:         input.UserID,
			QuizCode:       quizCode,
			QuizType:       attemptData.QuizType,
			TopicCode:      attemptData.TopicCode,
			SubtopicCode:   attemptData.SubtopicCode,
			ScorePoints:    correctCount,
			MaxScorePoints: totalQuestions,
			ScorePercent:   float64(scorePercent),
			CompletedAt:    time.Now(),
		})

		if err != nil {
			logger.Error("assessment service: failed to update progress: user_id=%d attempt_id=%d err=%v", input.UserID, input.AttemptID, err)
			return nil, err
		}
	}

	var reinforcement *dto.ReinforcementResultResponse

	if s.adaptationService != nil {
		adaptationResult, err := s.adaptationService.ProcessQuizResult(ctx, adaptationService.ProcessQuizResultInput{
			UserID:       input.UserID,
			QuizID:       attemptData.QuizID,
			AttemptID:    input.AttemptID,
			QuizType:     attemptData.QuizType,
			TopicCode:    attemptData.TopicCode,
			SubtopicCode: attemptData.SubtopicCode,
			ScorePercent: float64(scorePercent),
		})
		if err != nil {
			logger.Error("assessment service: failed to process adaptation: user_id=%d attempt_id=%d err=%v", input.UserID, input.AttemptID, err)
		} else if adaptationResult != nil {
			reinforcement = &dto.ReinforcementResultResponse{
				NeedsReinforcement: adaptationResult.NeedsReinforcement,
				Prediction:         adaptationResult.Prediction,
				Probability:        adaptationResult.Probability,
				Confidence:         adaptationResult.Confidence,
				DecisionSource:     adaptationResult.DecisionSource,
				ModelName:          adaptationResult.ModelName,
			}
		}
	}

	completedAttempt, err := s.assessmentRepo.GetAttemptByID(ctx, input.UserID, input.AttemptID)
	if err != nil {
		logger.Error("assessment service: failed to read completed attempt: user_id=%d attempt_id=%d err=%v", input.UserID, input.AttemptID, err)
		return nil, err
	}

	return &dto.SubmitQuizResponse{
		AttemptID:      completedAttempt.AttemptID,
		QuizID:         completedAttempt.QuizID,
		ScorePercent:   completedAttempt.ScorePercent,
		TotalQuestions: completedAttempt.TotalQuestions,
		CorrectAnswers: completedAttempt.CorrectAnswers,
		WrongAnswers:   completedAttempt.WrongAnswers,
		Passed:         completedAttempt.Passed,
		XPForScore:     completedAttempt.XPForScore,
		SubmittedAt:    completedAttempt.SubmittedAt,
		Reinforcement:  reinforcement,
	}, nil
}

func (s *Service) GetLatestAttemptByQuizID(ctx context.Context, userID, quizID int64) (*dto.LatestAttemptResponse, error) {
	if quizID <= 0 {
		return nil, assessmentErrors.ErrInvalidQuizID
	}

	attempt, err := s.assessmentRepo.GetLatestAttemptByQuizID(ctx, userID, quizID)
	if err != nil {
		if errors.Is(err, assessmentErrors.ErrAttemptNotFound) {
			return &dto.LatestAttemptResponse{
				HasAttempt: false,
				Attempt:    nil,
			}, nil
		}

		logger.Error("assessment service: failed to get latest attempt: user_id=%d quiz_id=%d err=%v", userID, quizID, err)
		return nil, err
	}

	return &dto.LatestAttemptResponse{
		HasAttempt: true,
		Attempt:    attempt,
	}, nil
}

func (s *Service) GetAttemptByID(ctx context.Context, userID, attemptID int64, languageCode string) (*dto.AttemptDetailResponse, error) {
	if attemptID <= 0 {
		return nil, assessmentErrors.ErrInvalidAttemptID
	}

	if !isSupportedLanguage(languageCode) {
		return nil, assessmentErrors.ErrInvalidLanguageCode
	}

	attempt, err := s.assessmentRepo.GetAttemptByID(ctx, userID, attemptID)
	if err != nil {
		if !errors.Is(err, assessmentErrors.ErrAttemptNotFound) {
			logger.Error("assessment service: failed to get attempt: user_id=%d attempt_id=%d err=%v", userID, attemptID, err)
		}
		return nil, err
	}

	answers, err := s.assessmentRepo.GetAttemptAnswers(ctx, attemptID, languageCode)
	if err != nil {
		logger.Error("assessment service: failed to get attempt answers: user_id=%d attempt_id=%d language_code=%s err=%v", userID, attemptID, languageCode, err)
		return nil, err
	}

	attempt.Answers = answers
	return attempt, nil
}

func checkAnswers(questions []model.QuestionCheckData, inputAnswers []service.SubmitAnswerInput) ([]model.QuizAttemptAnswer, int, error) {
	if len(questions) == 0 {
		return nil, 0, assessmentErrors.ErrAttemptNotFound
	}

	if len(inputAnswers) != len(questions) {
		return nil, 0, assessmentErrors.ErrIncompleteQuizAttempt
	}

	questionsByID := make(map[int64]model.QuestionCheckData, len(questions))
	for _, question := range questions {
		questionsByID[question.ID] = question
	}

	seenQuestions := make(map[int64]struct{}, len(inputAnswers))
	attemptAnswers := make([]model.QuizAttemptAnswer, 0)
	correctCount := 0

	for _, inputAnswer := range inputAnswers {
		question, ok := questionsByID[inputAnswer.QuestionID]
		if !ok {
			return nil, 0, assessmentErrors.ErrInvalidAttemptQuestion
		}

		if _, exists := seenQuestions[inputAnswer.QuestionID]; exists {
			return nil, 0, assessmentErrors.ErrDuplicateQuestion
		}
		seenQuestions[inputAnswer.QuestionID] = struct{}{}

		if len(inputAnswer.SelectedOptionIDs) == 0 {
			return nil, 0, assessmentErrors.ErrEmptySelectedOptions
		}

		if question.QuestionType == model.QuestionTypeSingleChoice || question.QuestionType == model.QuestionTypeTrueFalse {
			if len(inputAnswer.SelectedOptionIDs) != 1 {
				return nil, 0, assessmentErrors.ErrInvalidSelectedCount
			}
		}

		optionByID := make(map[int64]model.OptionCheckData, len(question.Options))
		correctOptions := make(map[int64]struct{})

		for _, option := range question.Options {
			optionByID[option.ID] = option
			if option.IsCorrect {
				correctOptions[option.ID] = struct{}{}
			}
		}

		selectedOptions := make(map[int64]struct{}, len(inputAnswer.SelectedOptionIDs))

		for _, selectedOptionID := range inputAnswer.SelectedOptionIDs {
			option, ok := optionByID[selectedOptionID]
			if !ok || option.QuestionID != inputAnswer.QuestionID {
				return nil, 0, assessmentErrors.ErrInvalidOptionID
			}

			if _, exists := selectedOptions[selectedOptionID]; exists {
				return nil, 0, assessmentErrors.ErrInvalidOptionID
			}

			selectedOptions[selectedOptionID] = struct{}{}
		}

		isQuestionCorrect := setsEqual(selectedOptions, correctOptions)
		if isQuestionCorrect {
			correctCount++
		}

		for _, selectedOptionID := range inputAnswer.SelectedOptionIDs {
			option := optionByID[selectedOptionID]

			attemptAnswers = append(attemptAnswers, model.QuizAttemptAnswer{
				QuestionID:              inputAnswer.QuestionID,
				SelectedOptionID:        selectedOptionID,
				IsCorrect:               isQuestionCorrect,
				IsSelectedOptionCorrect: option.IsCorrect,
				IsQuestionCorrect:       isQuestionCorrect,
			})
		}
	}

	return attemptAnswers, correctCount, nil
}

func setsEqual(left, right map[int64]struct{}) bool {
	if len(left) != len(right) {
		return false
	}

	for key := range left {
		if _, ok := right[key]; !ok {
			return false
		}
	}

	return true
}

func calculateXPForScore(quizType string, score int) int {
	if quizType == model.QuizTypeTopicFinalQuiz {
		if score >= 75 {
			return 50
		}

		return 10
	}

	switch {
	case score >= 100:
		return 15
	case score >= 50:
		return 10
	default:
		return 5
	}
}

func questionLimitForQuiz(quizType string, level string) int {
	if quizType == model.QuizTypeTopicFinalQuiz {
		return 10
	}

	return questionLimitByLevel(level)
}

func questionLimitByLevel(level string) int {
	switch level {
	case "intermediate", "advanced":
		return 3
	default:
		return 2
	}
}

func isSupportedLanguage(languageCode string) bool {
	switch languageCode {
	case "ru", "kk", "en":
		return true
	default:
		return false
	}
}

// computeShares distributes total questions across n subtopics using largest-remainder,
// so the first (total%n) subtopics each get one extra question.
func computeShares(n, total int) []int {
	if n <= 0 {
		return nil
	}
	base := total / n
	extra := total % n
	shares := make([]int, n)
	for i := range shares {
		shares[i] = base
		if i < extra {
			shares[i]++
		}
	}
	return shares
}

func buildQuizCode(quizType string, topicCode *string, subtopicCode *string, quizID int64) string {
	if quizType == model.QuizTypeTopicFinalQuiz {
		if topicCode != nil && *topicCode != "" {
			return fmt.Sprintf("%s_final", *topicCode)
		}

		return fmt.Sprintf("topic_final_quiz_%d", quizID)
	}

	if subtopicCode != nil && *subtopicCode != "" {
		return *subtopicCode
	}

	return fmt.Sprintf("subtopic_quiz_%d", quizID)
}
