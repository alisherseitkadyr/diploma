package postgres

import (
	"context"
	"diplomaBackend/internal/storage/postgres"
	"diplomaBackend/user_profile_service/model"
)

type PreferredTopicRepository struct {
	db postgres.DBTX
}

func NewPreferredTopicRepository(db postgres.DBTX) *PreferredTopicRepository {
	return &PreferredTopicRepository{db: db}
}

func (r *PreferredTopicRepository) GetByUserID(ctx context.Context, userID int64) ([]model.UserPreferredTopic, error) {
	query := `
		SELECT id, user_id, topic_code, created_at
		FROM user_preferred_topics
		WHERE user_id = $1
		ORDER BY id
	`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var topics []model.UserPreferredTopic

	for rows.Next() {
		var topic model.UserPreferredTopic
		if err := rows.Scan(
			&topic.ID,
			&topic.UserID,
			&topic.TopicCode,
			&topic.CreatedAt,
		); err != nil {
			return nil, err
		}

		topics = append(topics, topic)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return topics, nil
}

func (r *PreferredTopicRepository) ReplaceByUserID(ctx context.Context, userID int64, topicCodes []string) error {
	deleteQuery := `DELETE FROM user_preferred_topics WHERE user_id = $1`
	if _, err := r.db.Exec(ctx, deleteQuery, userID); err != nil {
		return err
	}

	insertQuery := `
		INSERT INTO user_preferred_topics (user_id, topic_code)
		VALUES ($1, $2)
	`

	for _, topicCode := range topicCodes {
		if _, err := r.db.Exec(ctx, insertQuery, userID, topicCode); err != nil {
			return err
		}
	}

	return nil
}
