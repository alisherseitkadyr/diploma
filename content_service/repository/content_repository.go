package repository

import (
	"context"

	"diplomaBackend/content_service/dto"
)

type ContentRepository interface {
	ListTopics(ctx context.Context, languageCode string) ([]dto.TopicResponse, error)
	ListSubtopicsByTopicCode(ctx context.Context, topicCode, languageCode string) ([]dto.SubtopicResponse, error)
	GetTopicFinalQuizByTopicCode(ctx context.Context, topicCode, languageCode string) (*dto.TopicFinalQuizResponse, error)
	GetLessonBySubtopicCode(ctx context.Context, subtopicCode, languageCode string) (*dto.LessonResponse, error)
	MarkSubtopicRead(ctx context.Context, userID int64, subtopicCode string) error
	GetExploreView(ctx context.Context, userID int64, languageCode string) (*dto.ExploreViewResponse, error)
}
