package app

import (
	"net/http"

	adaptationHTTP "diplomaBackend/adaptation_service/handler"
	adaptationPostgres "diplomaBackend/adaptation_service/repository/postgres"
	adaptationService "diplomaBackend/adaptation_service/service/adaptation"
	assessmentHandler "diplomaBackend/assessment_service/handler"
	assessmentPostgres "diplomaBackend/assessment_service/repository/postgres"
	assessmentService "diplomaBackend/assessment_service/service/assessment"
	authHandler "diplomaBackend/authorization_service/handler"
	authPostgres "diplomaBackend/authorization_service/repository/postgres"
	authService "diplomaBackend/authorization_service/service/auth"
	googleverifier "diplomaBackend/authorization_service/service/google"
	jwtservice "diplomaBackend/authorization_service/service/jwt"
	passwordservice "diplomaBackend/authorization_service/service/password"
	contentHandler "diplomaBackend/content_service/handler"
	contentPostgres "diplomaBackend/content_service/repository/postgres"
	contentService "diplomaBackend/content_service/service/content"
	"diplomaBackend/internal/config"
	"diplomaBackend/internal/http/middleware"
	"diplomaBackend/internal/mlclient"
	storagePostgres "diplomaBackend/internal/storage/postgres"
	progressHandler "diplomaBackend/progress_service/handler"
	progressPostgres "diplomaBackend/progress_service/repository/postgres"
	progressService "diplomaBackend/progress_service/service/progress"
	userProfileHandler "diplomaBackend/user_profile_service/handler"
	userProfilePostgres "diplomaBackend/user_profile_service/repository/postgres"
	userProfileService "diplomaBackend/user_profile_service/service/user"

	"github.com/jackc/pgx/v5/pgxpool"
)

type App struct {
	db     *pgxpool.Pool
	router http.Handler
}

func New(cfg *config.Config) *App {
	db := storagePostgres.New(cfg.DatabaseURL)
	authTxManager := authPostgres.NewTxManager(db)

	userRepo := authPostgres.NewUserRepository(db)
	refreshTokenRepo := authPostgres.NewRefreshTokenRepository(db)
	oauthAccountRepo := authPostgres.NewOAuthAccountRepository(db)
	userLoginSecurityRepo := authPostgres.NewUserLoginSecurityRepository(db)

	profileRepo := userProfilePostgres.NewProfileRepository(db)
	preferredTopicRepo := userProfilePostgres.NewPreferredTopicRepository(db)
	settingsRepo := userProfilePostgres.NewSettingsRepository(db)

	contentRepo := contentPostgres.NewContentRepository(db)
	assessmentRepo := assessmentPostgres.NewAssessmentRepository(db)
	assessmentTxManager := assessmentPostgres.NewTxManager(db)
	profileTxManager := userProfilePostgres.NewTxManager(db)
	progressRepo := progressPostgres.NewProgressRepository(db)

	adaptationRepo := adaptationPostgres.NewAdaptationRepository(db)

	var reinforcementMLClient mlclient.Client
	if cfg.ReinforcementMLServiceURL != "" {
		reinforcementMLClient = mlclient.NewHTTPClient(cfg.ReinforcementMLServiceURL)
	}

	var nextLessonMLClient mlclient.Client
	if cfg.NextLessonMLServiceURL != "" {
		nextLessonMLClient = mlclient.NewHTTPClient(cfg.NextLessonMLServiceURL)
	}

	adaptationSvc := adaptationService.NewService(
		adaptationRepo,
		reinforcementMLClient,
		nextLessonMLClient,
	)

	adaptationHandler := adaptationHTTP.NewHandler(adaptationSvc)

	profileSvc := userProfileService.NewService(
		profileRepo,
		preferredTopicRepo,
		settingsRepo,
		profileTxManager,
	)

	contentSvc := contentService.NewService(contentRepo)
	progressSvc := progressService.NewService(progressRepo)
	passwordSvc := passwordservice.NewService()
	jwtSvc := jwtservice.NewService(cfg.JWTAccessSecret, cfg.AccessTokenTTL)
	googleVerifier := googleverifier.NewVerifier(cfg.GoogleClientID)

	authSvc := authService.NewService(
		userRepo,
		refreshTokenRepo,
		oauthAccountRepo,
		userLoginSecurityRepo,
		passwordSvc,
		jwtSvc,
		googleVerifier,
		authTxManager,
		cfg.RefreshTokenTTL,
	)

	assessmentSvc := assessmentService.NewService(
		assessmentRepo,
		assessmentTxManager,
		progressSvc,
		adaptationSvc,
	)

	profileHandler := userProfileHandler.NewHandler(profileSvc)
	contentHandler := contentHandler.NewHandler(contentSvc)
	progressHandler := progressHandler.NewHandler(progressSvc)
	authHandler := authHandler.NewAuthHandler(authSvc)
	assessmentHandler := assessmentHandler.NewHandler(assessmentSvc)
	authMiddleware := middleware.AuthMiddleware(jwtSvc)

	router := middleware.CORS(NewRouter(
		authHandler,
		profileHandler,
		contentHandler,
		assessmentHandler,
		progressHandler,
		adaptationHandler,
		authMiddleware,
	))

	return &App{
		db:     db,
		router: router,
	}
}

func (a *App) Router() http.Handler {
	return a.router
}

func (a *App) Close() {
	if a.db != nil {
		a.db.Close()
	}
}
