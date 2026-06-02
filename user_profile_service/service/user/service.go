package user

import (
	"context"
	"errors"

	"diplomaBackend/internal/logger"
	"diplomaBackend/user_profile_service/dto"
	profileErrors "diplomaBackend/user_profile_service/errors"
	"diplomaBackend/user_profile_service/model"
	"diplomaBackend/user_profile_service/repository"
	"diplomaBackend/user_profile_service/service"
)

type Service struct {
	profileRepo        repository.ProfileRepository
	preferredTopicRepo repository.PreferredTopicRepository
	settingsRepo       repository.SettingsRepository
	txManager          repository.TxManager
}

func NewService(
	profileRepo repository.ProfileRepository,
	preferredTopicRepo repository.PreferredTopicRepository,
	settingsRepo repository.SettingsRepository,
	txManager repository.TxManager,
) service.UserProfileService {
	return &Service{
		profileRepo:        profileRepo,
		preferredTopicRepo: preferredTopicRepo,
		settingsRepo:       settingsRepo,
		txManager:          txManager,
	}
}

func (s *Service) GetProfileByUserID(ctx context.Context, userID int64) (*dto.ProfileResponse, error) {
	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil {
		if !errors.Is(err, profileErrors.ErrProfileNotFound) {
			logger.Error("profile service: failed to get profile: user_id=%d err=%v", userID, err)
		}
		return nil, err
	}

	topics, err := s.preferredTopicRepo.GetByUserID(ctx, userID)
	if err != nil {
		logger.Error("profile service: failed to get preferred topics: user_id=%d err=%v", userID, err)
		return nil, err
	}

	preferredTopics := make([]string, 0, len(topics))
	for _, topic := range topics {
		preferredTopics = append(preferredTopics, topic.TopicCode)
	}

	return &dto.ProfileResponse{
		UserID:                 profile.UserID,
		FinancialLiteracyLevel: profile.FinancialLiteracyLevel,
		PracticalExperience:    profile.PracticalExperience,
		LearningGoal:           profile.LearningGoal,
		PreferredLanguage:      profile.PreferredLanguage,
		TimeCommitment:         profile.TimeCommitment,
		PreferredTopics:        preferredTopics,
		OnboardingCompleted:    profile.OnboardingCompleted,
	}, nil
}

func (s *Service) UpsertProfile(ctx context.Context, input service.UpsertProfileInput) (*dto.ProfileResponse, error) {
	if len(input.PreferredTopics) == 0 {
		return nil, profileErrors.ErrPreferredTopicsRequired
	}

	profile := &model.UserLearningProfile{
		UserID:                 input.UserID,
		FinancialLiteracyLevel: input.FinancialLiteracyLevel,
		PracticalExperience:    input.PracticalExperience,
		LearningGoal:           input.LearningGoal,
		PreferredLanguage:      input.PreferredLanguage,
		TimeCommitment:         input.TimeCommitment,
		OnboardingCompleted:    true,
	}

	err := s.txManager.WithinTransaction(ctx, func(
		profileRepo repository.ProfileRepository,
		preferredTopicRepo repository.PreferredTopicRepository,
		settingsRepo repository.SettingsRepository,
	) error {
		existingProfile, err := profileRepo.GetByUserID(ctx, input.UserID)
		if err == nil && existingProfile != nil {
			return profileErrors.ErrProfileAlreadyCompleted
		}

		if err != nil && !errors.Is(err, profileErrors.ErrProfileNotFound) {
			logger.Error("profile service: failed to get profile before onboarding: user_id=%d err=%v", input.UserID, err)
			return err
		}

		if err := profileRepo.Create(ctx, profile); err != nil {
			logger.Error("profile service: failed to create profile: user_id=%d err=%v", input.UserID, err)
			return err
		}

		if err := preferredTopicRepo.ReplaceByUserID(ctx, input.UserID, input.PreferredTopics); err != nil {
			logger.Error("profile service: failed to replace preferred topics: user_id=%d err=%v", input.UserID, err)
			return err
		}

		existingSettings, err := settingsRepo.GetByUserID(ctx, input.UserID)
		if err != nil {
			if errors.Is(err, profileErrors.ErrSettingsNotFound) {
				settings := &model.UserSettings{
					UserID:               input.UserID,
					LanguageCode:         input.PreferredLanguage,
					Theme:                "system",
					NotificationsEnabled: true,
					ReminderTime:         nil,
				}

				if err := settingsRepo.Create(ctx, settings); err != nil {
					logger.Error("profile service: failed to create default settings after onboarding: user_id=%d err=%v", input.UserID, err)
					return err
				}

				return nil
			}

			logger.Error("profile service: failed to get settings during onboarding: user_id=%d err=%v", input.UserID, err)
			return err
		}

		existingSettings.LanguageCode = input.PreferredLanguage

		if err := settingsRepo.Update(ctx, existingSettings); err != nil {
			logger.Error("profile service: failed to sync settings language after onboarding: user_id=%d err=%v", input.UserID, err)
			return err
		}

		return nil
	})
	if err != nil {
		return nil, err
	}

	return &dto.ProfileResponse{
		UserID:                 profile.UserID,
		FinancialLiteracyLevel: profile.FinancialLiteracyLevel,
		PracticalExperience:    profile.PracticalExperience,
		LearningGoal:           profile.LearningGoal,
		PreferredLanguage:      profile.PreferredLanguage,
		TimeCommitment:         profile.TimeCommitment,
		PreferredTopics:        input.PreferredTopics,
		OnboardingCompleted:    profile.OnboardingCompleted,
	}, nil
}

func (s *Service) GetQuestionnaireOptions(ctx context.Context) (*dto.QuestionnaireOptionsResponse, error) {
	return &dto.QuestionnaireOptionsResponse{
		FinancialLiteracyLevels: []dto.CodeOption{
			{Code: "beginner"},
			{Code: "basic"},
			{Code: "intermediate"},
			{Code: "advanced"},
		},
		PracticalExperiences: []dto.CodeOption{
			{Code: "no_experience"},
			{Code: "tracks_expenses"},
			{Code: "plans_budget"},
			{Code: "manages_finances"},
		},
		LearningGoals: []dto.CodeOption{
			{Code: "general_improvement"},
			{Code: "saving_money"},
			{Code: "debt_management"}, 
			{Code: "financial_planning"},
			{Code: "increase_income"},
			{Code: "control_spending"},
			{Code: "understand_banking"},
			{Code: "start_investing"},
			{Code: "other"},
		},
		PreferredLanguages: []dto.CodeOption{
			{Code: "ru"},
			{Code: "kk"},
			{Code: "en"},
		},
		TimeCommitments: []dto.CodeOption{
			{Code: "5_min"},
			{Code: "10_min"},
			{Code: "15_min"},
			{Code: "20_plus_min"},
		},
		PreferredTopics: []dto.CodeOption{
			{Code: "budgeting"},
			{Code: "savings"},
			{Code: "credits_and_debts"},
			{Code: "financial_planning"},
			{Code: "investing"},
		},
	}, nil
}

func (s *Service) GetSettingsByUserID(ctx context.Context, userID int64) (*dto.SettingsResponse, error) {
	settings, err := s.settingsRepo.GetByUserID(ctx, userID)
	if err != nil {
		if !errors.Is(err, profileErrors.ErrSettingsNotFound) {
			logger.Error("profile service: failed to get settings: user_id=%d err=%v", userID, err)
		}
		return nil, err
	}

	return &dto.SettingsResponse{
		UserID:               settings.UserID,
		LanguageCode:         settings.LanguageCode,
		Theme:                settings.Theme,
		NotificationsEnabled: settings.NotificationsEnabled,
		ReminderTime:         settings.ReminderTime,
	}, nil
}

func (s *Service) UpdateSettings(ctx context.Context, input service.UpdateSettingsInput) (*dto.SettingsResponse, error) {
	var settings *model.UserSettings

	err := s.txManager.WithinTransaction(ctx, func(
		profileRepo repository.ProfileRepository,
		preferredTopicRepo repository.PreferredTopicRepository,
		settingsRepo repository.SettingsRepository,
	) error {
		_ = preferredTopicRepo

		existingSettings, err := settingsRepo.GetByUserID(ctx, input.UserID)
		if err != nil {
			if errors.Is(err, profileErrors.ErrSettingsNotFound) {
				settings = &model.UserSettings{
					UserID:               input.UserID,
					LanguageCode:         "kk",
					Theme:                "system",
					NotificationsEnabled: true,
					ReminderTime:         nil,
				}

				if input.LanguageCode != nil {
					settings.LanguageCode = *input.LanguageCode
				}
				if input.Theme != nil {
					settings.Theme = *input.Theme
				}
				if input.NotificationsEnabled != nil {
					settings.NotificationsEnabled = *input.NotificationsEnabled
				}
				if input.ReminderTime != nil {
					settings.ReminderTime = input.ReminderTime
				}

				if err := settingsRepo.Create(ctx, settings); err != nil {
					logger.Error("profile service: failed to create settings during update: user_id=%d err=%v", input.UserID, err)
					return err
				}
			} else {
				logger.Error("profile service: failed to get settings before update: user_id=%d err=%v", input.UserID, err)
				return err
			}
		} else {
			settings = existingSettings

			if input.LanguageCode != nil {
				settings.LanguageCode = *input.LanguageCode
			}
			if input.Theme != nil {
				settings.Theme = *input.Theme
			}
			if input.NotificationsEnabled != nil {
				settings.NotificationsEnabled = *input.NotificationsEnabled
			}
			if input.ReminderTime != nil {
				settings.ReminderTime = input.ReminderTime
			}

			if err := settingsRepo.Update(ctx, settings); err != nil {
				logger.Error("profile service: failed to update settings: user_id=%d err=%v", settings.UserID, err)
				return err
			}
		}

		return nil
	})
	if err != nil {
		return nil, err
	}

	return &dto.SettingsResponse{
		UserID:               settings.UserID,
		LanguageCode:         settings.LanguageCode,
		Theme:                settings.Theme,
		NotificationsEnabled: settings.NotificationsEnabled,
		ReminderTime:         settings.ReminderTime,
	}, nil
}
