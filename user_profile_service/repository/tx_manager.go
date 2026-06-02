package repository

import "context"

type TxManager interface {
	WithinTransaction(ctx context.Context, fn func(profileRepo ProfileRepository,
		preferredTopicRepo PreferredTopicRepository,
		settingsRepo SettingsRepository) error,
	) error
}
