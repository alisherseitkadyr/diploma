package service

import (
	"context"

	"diplomaBackend/content_service/dto"
)

type ContentService interface {
	ListTopics(ctx context.Context, languageCode string) ([]dto.TopicResponse, error)
	ListSubtopicsByTopicCode(ctx context.Context, topicCode, languageCode string) (*dto.TopicSubtopicsResponse, error)
	GetLessonBySubtopicCode(ctx context.Context, subtopicCode, languageCode string) (*dto.LessonResponse, error)
	CompleteSubtopic(ctx context.Context, userID int64, subtopicCode string) error
	GetExploreView(ctx context.Context, userID int64, languageCode string) (*dto.ExploreViewResponse, error)
}
