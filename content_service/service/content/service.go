package content

import (
	"context"

	"diplomaBackend/content_service/dto"
	"diplomaBackend/content_service/repository"
	"diplomaBackend/content_service/service"
	"diplomaBackend/internal/logger"
)

type Service struct {
	contentRepo repository.ContentRepository
}

func NewService(contentRepo repository.ContentRepository) service.ContentService {
	return &Service{
		contentRepo: contentRepo,
	}
}

func (s *Service) ListTopics(ctx context.Context, languageCode string) ([]dto.TopicResponse, error) {
	topics, err := s.contentRepo.ListTopics(ctx, languageCode)
	if err != nil {
		logger.Error("content service: failed to list topics: language_code=%s err=%v", languageCode, err)
		return nil, err
	}

	return topics, nil
}

func (s *Service) ListSubtopicsByTopicCode(ctx context.Context, topicCode, languageCode string) (*dto.TopicSubtopicsResponse, error) {
	subtopics, err := s.contentRepo.ListSubtopicsByTopicCode(ctx, topicCode, languageCode)
	if err != nil {
		logger.Error(
			"content service: failed to list subtopics: topic_code=%s language_code=%s err=%v",
			topicCode,
			languageCode,
			err,
		)
		return nil, err
	}

	finalQuiz, err := s.contentRepo.GetTopicFinalQuizByTopicCode(ctx, topicCode, languageCode)
	if err != nil {
		logger.Error(
			"content service: failed to get topic final quiz: topic_code=%s language_code=%s err=%v",
			topicCode,
			languageCode,
			err,
		)
		return nil, err
	}

	return &dto.TopicSubtopicsResponse{
		Subtopics: subtopics,
		FinalQuiz: finalQuiz,
	}, nil
}

func (s *Service) GetLessonBySubtopicCode(ctx context.Context, subtopicCode, languageCode string) (*dto.LessonResponse, error) {
	lesson, err := s.contentRepo.GetLessonBySubtopicCode(ctx, subtopicCode, languageCode)
	if err != nil {
		logger.Error(
			"content service: failed to get lesson: subtopic_code=%s language_code=%s err=%v",
			subtopicCode,
			languageCode,
			err,
		)
		return nil, err
	}

	return lesson, nil
}

func (s *Service) CompleteSubtopic(ctx context.Context, userID int64, subtopicCode string) error {
	if err := s.contentRepo.MarkSubtopicRead(ctx, userID, subtopicCode); err != nil {
		logger.Error("content service: failed to mark subtopic read: user_id=%d subtopic_code=%s err=%v", userID, subtopicCode, err)
		return err
	}
	return nil
}

func (s *Service) GetExploreView(ctx context.Context, userID int64, languageCode string) (*dto.ExploreViewResponse, error) {
	view, err := s.contentRepo.GetExploreView(ctx, userID, languageCode)
	if err != nil {
		logger.Error("content service: failed to get explore view: user_id=%d language_code=%s err=%v", userID, languageCode, err)
		return nil, err
	}
	return view, nil
}

func (s *Service) GetTip(ctx context.Context, languageCode string) (*dto.TipResponse, error) {
	tip, err := s.contentRepo.GetRandomTip(ctx, languageCode)
	if err != nil {
		logger.Error("content service: failed to get random tip: language_code=%s err=%v", languageCode, err)
		return nil, err
	}
	return tip, nil
}
