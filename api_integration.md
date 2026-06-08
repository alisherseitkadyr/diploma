# Backend API Integration Specification for Flutter


Updated: `GET /api/content/topics/{topicCode}/subtopics` now describes regular subtopics with the `quizId` field, and `finalQuiz` is described as a separate final quiz card for the topic.

## General Rules

The local Base URL depends on how the backend is started. All endpoints below use this prefix:

```text
/api
```

Protected endpoints require this header:

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

The common error format is:

```json
{
  "error": {
    "code": "SOME_ERROR_CODE"
  }
}
```

Time values are returned as RFC3339 strings, for example:

```json
"2026-05-01T12:34:56Z"
```

Important: JSON naming is mixed in the project:

- `auth`, `assessment`, and `progress` mostly use `snake_case`
- `content` and `adaptation` use `camelCase`
- `profile/settings` request uses `snake_case`, but response uses `camelCase`

For Flutter, it is better to create separate DTO/model classes for each endpoint instead of relying on one universal serializer.

---

# 1. Auth API

## 1.1 Register

```http
POST /api/auth/register
```

Creates a user with email/password.

Auth header: not required.

### Request

```json
{
  "email": "user@example.com",
  "username": "John",
  "password": "pass123"
}
```

### Response `201 Created`

```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "John",
    "is_active": true
  },
  "access_token": "jwt_access_token",
  "refresh_token": "refresh_token"
}
```

### Errors

```text
400 INVALID_REQUEST
400 EMPTY_USERNAME
400 USERNAME_TOO_SHORT
400 USERNAME_TOO_LONG
400 USERNAME_BAD_SYMBOLS
400 EMPTY_EMAIL
400 INVALID_EMAIL_FORMAT
400 EMPTY_PASSWORD
400 PASSWORD_TOO_SHORT
400 PASSWORD_MUST_HAVE_DIGIT
400 PASSWORD_INVALID_CHARS
409 EMAIL_ALREADY_EXISTS
500 INTERNAL_ERROR
```

### Flutter Validation

- `username`: 2..20 characters
- `password`: at least 5 characters
- `password`: must contain at least 1 digit
- `password`: spaces and commas are not allowed
- email must have a valid format

---

## 1.2 Login

```http
POST /api/auth/login
```

Auth header: not required.

### Request

```json
{
  "email": "user@example.com",
  "password": "pass123"
}
```

### Response `200 OK`

```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "John",
    "is_active": true
  },
  "access_token": "jwt_access_token",
  "refresh_token": "refresh_token"
}
```

### Errors

```text
400 INVALID_REQUEST
400 EMPTY_EMAIL
400 INVALID_EMAIL_FORMAT
400 EMPTY_PASSWORD
400 PASSWORD_TOO_SHORT
400 PASSWORD_MUST_HAVE_DIGIT
400 PASSWORD_INVALID_CHARS
401 INVALID_CREDENTIALS
403 INACTIVE_USER
429 TOO_MANY_LOGIN_ATTEMPTS
500 INTERNAL_ERROR
```

### Notes

After 5 failed login attempts, login is blocked for about 20 minutes.

---

## 1.3 Google Login

```http
POST /api/auth/google
```

Uses a Google ID token received by the Flutter client through Google Sign-In.

Auth header: not required.

### Request

```json
{
  "id_token": "google_id_token"
}
```

### Response `200 OK`

```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "John",
    "is_active": true
  },
  "access_token": "jwt_access_token",
  "refresh_token": "refresh_token"
}
```

### Errors

```text
400 INVALID_REQUEST
401 INVALID_GOOGLE_TOKEN
403 GOOGLE_EMAIL_NOT_VERIFIED
403 INACTIVE_USER
409 GOOGLE_EMAIL_ALREADY_EXISTS
500 INTERNAL_ERROR
```

---

## 1.4 Refresh Token

```http
POST /api/auth/refresh
```

Refreshes the access token using a refresh token.

Auth header: not required.

### Request

```json
{
  "refresh_token": "refresh_token"
}
```

### Response `200 OK`

```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "John",
    "is_active": true
  },
  "access_token": "new_jwt_access_token",
  "refresh_token": "new_refresh_token"
}
```

### Errors

```text
400 INVALID_REQUEST
401 INVALID_REFRESH_TOKEN
401 REFRESH_TOKEN_EXPIRED
401 REFRESH_TOKEN_REVOKED
401 REFRESH_TOKEN_NOT_FOUND
403 INACTIVE_USER
500 INTERNAL_ERROR
```

### Notes

After refresh, the old refresh token is revoked and the backend returns a new refresh token.

---

## 1.5 Logout

```http
POST /api/auth/logout
```

Auth header: not required. Logout works through the refresh token.

### Request

```json
{
  "refresh_token": "refresh_token"
}
```

### Response `200 OK`

```json
{
  "message": "LOGGED_OUT"
}
```

### Errors

```text
400 INVALID_REQUEST
401 INVALID_REFRESH_TOKEN
401 REFRESH_TOKEN_EXPIRED
401 REFRESH_TOKEN_REVOKED
401 REFRESH_TOKEN_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 1.6 Get Current User

```http
GET /api/auth/me
```

Auth header: required.

### Response `200 OK`

```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "John",
  "is_active": true
}
```

### Errors

```text
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 USER_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 1.7 Change Username

```http
PATCH /api/auth/me/username
```

Auth header: required.

### Request

```json
{
  "new_username": "New Name"
}
```

### Response `200 OK`

```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "New Name",
  "is_active": true
}
```

### Errors

```text
400 INVALID_REQUEST
400 EMPTY_USERNAME
400 USERNAME_TOO_SHORT
400 USERNAME_TOO_LONG
400 USERNAME_BAD_SYMBOLS
400 USERNAME_SAME_AS_CURRENT
400 INVALID_USERNAME
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 USER_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 1.8 Change Password

```http
PATCH /api/auth/me/password
```

Auth header: required.

### Request

```json
{
  "current_password": "old123",
  "new_password": "new123",
  "refresh_token": "current_refresh_token"
}
```

### Response `200 OK`

```json
{
  "message": "PASSWORD_CHANGED"
}
```

### Errors

```text
400 INVALID_REQUEST
400 EMPTY_PASSWORD
400 PASSWORD_TOO_SHORT
400 PASSWORD_MUST_HAVE_DIGIT
400 PASSWORD_INVALID_CHARS
400 PASSWORD_SAME_AS_CURRENT
401 INVALID_CREDENTIALS
401 INVALID_REFRESH_TOKEN
401 REFRESH_TOKEN_EXPIRED
401 REFRESH_TOKEN_REVOKED
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 USER_NOT_FOUND
500 INTERNAL_ERROR
```

### Notes

When the password is changed, the backend revokes all user refresh tokens except the refresh token sent in the request.

---

# 2. Profile API

## Allowed Profile Values

### `financial_literacy_level`

```text
beginner
basic
intermediate
advanced
```

### `practical_experience`

```text
no_experience
tracks_expenses
plans_budget
manages_finances
```

### `learning_goal`

```text
general_improvement
saving_money
debt_management
financial_planning
increase_income
control_spending
understand_banking
start_investing
other
```

### `preferred_language`

```text
ru
kk
en
```

### `time_commitment`

```text
5_min
10_min
15_min
20_plus_min
```

### `preferred_topics`

```text
budgeting
savings
credits_and_debts
financial_planning
investing
```

---

## 2.1 Get Profile

```http
GET /api/profile/me
```

Auth header: required.

### Response `200 OK`

```json
{
  "userId": 1,
  "financialLiteracyLevel": "beginner",
  "practicalExperience": "no_experience",
  "learningGoal": "saving_money",
  "preferredLanguage": "kk",
  "timeCommitment": "10_min",
  "preferredTopics": ["budgeting", "savings"],
  "onboardingCompleted": true
}
```

### Errors

```text
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 PROFILE_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 2.2 Create Profile / Complete Onboarding

```http
PUT /api/profile/me
```

Auth header: required.

Important: in the current service version, an already created profile is not updated. If the profile already exists, the backend returns `409 PROFILE_ALREADY_COMPLETED`.

### Request

Request uses `snake_case`.

```json
{
  "financial_literacy_level": "beginner",
  "practical_experience": "no_experience",
  "learning_goal": "saving_money",
  "preferred_language": "kk",
  "time_commitment": "10_min",
  "preferred_topics": ["budgeting", "savings"]
}
```

### Response `200 OK`

Response uses `camelCase`.

```json
{
  "userId": 1,
  "financialLiteracyLevel": "beginner",
  "practicalExperience": "no_experience",
  "learningGoal": "saving_money",
  "preferredLanguage": "kk",
  "timeCommitment": "10_min",
  "preferredTopics": ["budgeting", "savings"],
  "onboardingCompleted": true
}
```

### Errors

```text
400 INVALID_REQUEST
400 PREFERRED_TOPICS_REQUIRED
400 INVALID_FINANCIAL_LITERACY_LEVEL
400 INVALID_PRACTICAL_EXPERIENCE
400 INVALID_LEARNING_GOAL
400 INVALID_PREFERRED_LANGUAGE
400 INVALID_TIME_COMMITMENT
400 INVALID_PREFERRED_TOPIC
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
409 PROFILE_ALREADY_COMPLETED
500 INTERNAL_ERROR
```

### Notes

After successful onboarding, the backend:

- creates the learning profile
- saves preferred topics
- creates default settings if they do not exist yet
- synchronizes settings language with `preferred_language`

---

# 3. Settings API

## Allowed Settings Values

### `language_code`

```text
ru
kk
en
```

### `theme`

```text
light
dark
system
```

### `reminder_time`

It is better to send the value in DB time format:

```text
HH:MM:SS
```

Examples:

```text
09:00:00
21:30:00
```

---

## 3.1 Get Settings

```http
GET /api/profile/settings
```

Auth header: required.

### Response `200 OK`

```json
{
  "userId": 1,
  "languageCode": "kk",
  "theme": "system",
  "notificationsEnabled": true,
  "reminderTime": "09:00:00"
}
```

`reminderTime` can be `null`.

### Errors

```text
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 SETTINGS_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 3.2 Update Settings

```http
PATCH /api/profile/settings
```

Auth header: required.

All fields are optional. Send only the fields that should be changed.

### Request

Request uses `snake_case`.

```json
{
  "language_code": "en",
  "theme": "dark",
  "notifications_enabled": true,
  "reminder_time": "21:30:00"
}
```

Partial update example:

```json
{
  "theme": "dark"
}
```

### Response `200 OK`

Response uses `camelCase`.

```json
{
  "userId": 1,
  "languageCode": "en",
  "theme": "dark",
  "notificationsEnabled": true,
  "reminderTime": "21:30:00"
}
```

### Errors

```text
400 INVALID_REQUEST
400 INVALID_LANGUAGE_CODE
400 INVALID_THEME
400 INVALID_REMINDER_TIME
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 SETTINGS_NOT_FOUND
500 INTERNAL_ERROR
```

### Notes

Changing `language_code` in settings also synchronizes the language in the user profile.

---

# 4. Content API

All content endpoints support the query parameter:

```text
?lang=ru|kk|en
```

If `lang` is not provided, the backend uses `kk`.

---

## 4.1 List Topics

```http
GET /api/content/topics?lang=ru
```

Auth header: required.

### Response `200 OK`

```json
[
  {
    "code": "budgeting",
    "level": "beginner",
    "orderIndex": 1,
    "title": "Budgeting",
    "description": "Topic description"
  }
]
```

### Response fields

```text
code: topic code used for navigation and requests
level: beginner/intermediate/advanced
orderIndex: order inside the level
title: localized title
description: localized description, can be empty
```

### Errors

```text
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
500 INTERNAL_ERROR
```

---

## 4.2 List Subtopics by Topic

```http
GET /api/content/topics/{topicCode}/subtopics?lang=ru
```

Auth header: required.

### Path params

```text
topicCode: string
```

### Response `200 OK`

Endpoint returns an object, not an array.

Regular subtopics must contain `quizId`, so Flutter can open the subtopic quiz right after the lesson.

```json
{
  "subtopics": [
    {
      "code": "income_expenses",
      "orderIndex": 1,
      "estimatedMinutes": 5,
      "title": "Income and expenses",
      "description": "Subtopic description",
      "quizId": 10
    }
  ],
  "finalQuiz": {
    "quizId": 100,
    "topicCode": "budgeting",
    "quizType": "topic_final_quiz",
    "title": "Final quiz for the topic",
    "passingScore": 75,
    "timeLimitSeconds": null
  }
}
```

`finalQuiz` can be absent if the topic has no final quiz.

### Flutter Display Logic

Regular `subtopics` are displayed as a list of lessons inside the topic.

Each subtopic card uses:

```text
subtopic.code
subtopic.title
subtopic.description
subtopic.estimatedMinutes
subtopic.quizId
```

Flow for a regular subtopic:

```text
1. User opens a subtopic card
2. Flutter opens the lesson by subtopic.code
3. After the lesson, Flutter starts the quiz by subtopic.quizId
4. Flutter submits the quiz attempt
5. Flutter refreshes progress/adaptation state
```

`finalQuiz` is displayed separately after all regular subtopics, as a separate final quiz card for the topic.

`finalQuiz` is not a lesson and does not have a lesson screen. On tap, Flutter opens the quiz flow directly by `finalQuiz.quizId`.

Flow for the final quiz:

```text
1. User opens the Final Quiz card
2. Flutter starts the quiz by finalQuiz.quizId
3. Flutter submits the quiz attempt
4. Flutter refreshes progress/adaptation state
```

For MVP, `finalQuiz` can be shown whenever `finalQuiz != null`.

Since the project does not strictly lock content, Flutter does not have to disable the card. It can show a hint instead:

```text
Recommended after completing all subtopics
```

if the `learning-map` shows that the topic is not fully completed yet.

### Errors

```text
400 INVALID_TOPIC_CODE
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 TOPIC_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 4.3 Get Lesson by Subtopic

```http
GET /api/content/subtopics/{subtopicCode}/lesson?lang=ru
```

Auth header: required.

### Path params

```text
subtopicCode: string
```

### Response `200 OK`

```json
{
  "lessonId": 1,
  "subtopicCode": "income_expenses",
  "title": "Income and expenses",
  "description": "Lesson description",
  "steps": [
    {
      "id": 1,
      "stepType": "introduction",
      "orderIndex": 1,
      "title": "Introduction",
      "content": {
        "blocks": [
          {
            "type": "paragraph",
            "text": "Lesson text"
          }
        ]
      },
      "interactiveType": null,
      "interactiveContent": null
    },
    {
      "id": 2,
      "stepType": "interactive",
      "orderIndex": 2,
      "title": "Interactive task",
      "content": {
        "blocks": []
      },
      "interactiveType": "budget_calculator",
      "interactiveContent": {
        "description": "Interactive content JSON"
      }
    }
  ]
}
```

### Step fields

```text
id: lesson step id
stepType: type of lesson step
orderIndex: step order
title: optional localized step title
content: dynamic JSON content
interactiveType: optional interactive type
interactiveContent: optional dynamic JSON content
```

### Possible `stepType`

```text
introduction
explanation
example
summary
interactive
```

### Possible `content.blocks[].type`

```text
paragraph
list
example
formula
warning
```

### Possible `interactiveType`

```text
budget_calculator
expense_classifier
savings_goal_calculator
credit_overpayment_calculator
investment_risk_quiz
```

### Flutter Notes

`content` and `interactiveContent` are dynamic JSON objects. Flutter should parse them as:

```dart
Map<String, dynamic> content;
Map<String, dynamic>? interactiveContent;
```

### Errors

```text
400 INVALID_SUBTOPIC_CODE
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 LESSON_NOT_FOUND
500 INTERNAL_ERROR
```

---

# 5. Assessment API

All assessment endpoints are protected.

Query param:

```text
?lang=ru|kk|en
```

If `lang` is not provided, the backend uses `kk`.

## Enum Values

### `quiz_type`

```text
subtopic_quiz
topic_final_quiz
```

### `question_type`

```text
single_choice
multiple_choice
true_false
```

---

## 5.1 Get Quiz by ID

```http
GET /api/assessment/quizzes/{quizId}?lang=ru
```

Auth header: required.

### Path params

```text
quizId: integer
```

### Response `200 OK`

```json
{
  "id": 1,
  "subtopic_code": "income_expenses",
  "topic_code": "budgeting",
  "quiz_type": "subtopic_quiz",
  "title": "Quiz title",
  "passing_score": 70,
  "time_limit_seconds": null,
  "questions": [
    {
      "id": 10,
      "question_type": "single_choice",
      "order_index": 1,
      "question_text": "Question text?",
      "explanation": "Explanation text",
      "answers": [
        {
          "id": 100,
          "order_index": 1,
          "answer_text": "Answer A"
        }
      ]
    }
  ]
}
```

Important: answers returned to Flutter do not include `is_correct`.

### Errors

```text
400 INVALID_QUIZ_ID
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 QUIZ_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 5.2 Start Quiz Attempt

```http
POST /api/assessment/quizzes/{quizId}/start?lang=ru
```

Auth header: required.

### Path params

```text
quizId: integer
```

### Request

Usually empty body:

```json
{}
```

### Response `201 Created`

```json
{
  "attempt_id": 1,
  "quiz": {
    "id": 1,
    "subtopic_code": "income_expenses",
    "topic_code": "budgeting",
    "quiz_type": "subtopic_quiz",
    "title": "Quiz title",
    "passing_score": 70,
    "time_limit_seconds": null,
    "questions": [
      {
        "id": 10,
        "question_type": "single_choice",
        "order_index": 1,
        "question_text": "Question text?",
        "explanation": "Explanation text",
        "answers": [
          {
            "id": 100,
            "order_index": 1,
            "answer_text": "Answer A"
          }
        ]
      }
    ]
  }
}
```

### Notes

Flutter can use `/start` as the main quiz loading endpoint, because it returns both `attempt_id` and the quiz questions.

If the user opens a quiz screen, the recommended flow is:

```text
POST /api/assessment/quizzes/{quizId}/start
render returned quiz
submit by attempt_id
```

### Errors

```text
400 INVALID_QUIZ_ID
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 QUIZ_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 5.3 Submit Attempt

```http
POST /api/assessment/attempts/{attemptId}/submit
```

Auth header: required.

### Path params

```text
attemptId: integer
```

### Request

```json
{
  "answers": [
    {
      "question_id": 10,
      "selected_answer_ids": [100]
    },
    {
      "question_id": 11,
      "selected_answer_ids": [105, 106]
    }
  ]
}
```

### Request Rules

```text
single_choice: selected_answer_ids must contain exactly 1 answer id
true_false: selected_answer_ids must contain exactly 1 answer id
multiple_choice: selected_answer_ids can contain several answer ids
```

### Response `200 OK`

```json
{
  "attempt_id": 1,
  "quiz_id": 1,
  "score_percent": 80,
  "correct_answers": 4,
  "total_questions": 5,
  "passed": true,
  "xp_earned": 15,
  "completed_at": "2026-05-01T12:34:56Z"
}
```

### XP Rules

```text
If passed = true:
  subtopic_quiz => 15 XP
  topic_final_quiz => 25 XP

If passed = false:
  0 XP
```

### Notes

After submit, Flutter should refresh:

```http
GET /api/progress/me
GET /api/adaptation/recommendations/home?lang=ru
GET /api/adaptation/learning-map?lang=ru
```

### Errors

```text
400 INVALID_ATTEMPT_ID
400 INVALID_REQUEST
400 EMPTY_ANSWERS
400 INVALID_QUESTION_ID
400 INVALID_ANSWER_ID
400 INVALID_SELECTED_ANSWERS
400 ATTEMPT_ALREADY_COMPLETED
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 ATTEMPT_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 5.4 Get Latest Completed Attempt by Quiz ID

```http
GET /api/assessment/quizzes/{quizId}/latest-completed-attempt
```

Auth header: required.

### Response when no completed attempt `200 OK`

```json
{
  "attempt": null
}
```

### Response with attempt `200 OK`

```json
{
  "attempt": {
    "attempt_id": 1,
    "quiz_id": 1,
    "score_percent": 80,
    "correct_answers": 4,
    "total_questions": 5,
    "passed": true,
    "xp_earned": 15,
    "completed_at": "2026-05-01T12:34:56Z"
  }
}
```

### Errors

```text
400 INVALID_QUIZ_ID
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 QUIZ_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 5.5 Get Attempt Details

```http
GET /api/assessment/attempts/{attemptId}
```

Auth header: required.

### Response `200 OK`

```json
{
  "attempt_id": 1,
  "quiz_id": 1,
  "score_percent": 80,
  "correct_answers": 4,
  "total_questions": 5,
  "passed": true,
  "xp_earned": 15,
  "completed_at": "2026-05-01T12:34:56Z",
  "answers": [
    {
      "question_id": 10,
      "selected_answer_ids": [100],
      "is_correct": true
    }
  ]
}
```

### Errors

```text
400 INVALID_ATTEMPT_ID
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 ATTEMPT_NOT_FOUND
500 INTERNAL_ERROR
```

---

# 6. Progress API

## 6.1 Get My Progress

```http
GET /api/progress/me
```

Auth header: required.

### Response `200 OK`

```json
{
  "progress": {
    "user_id": 1,
    "total_xp": 120,
    "current_streak_days": 3,
    "longest_streak_days": 5,
    "last_activity_at": "2026-05-01T12:34:56Z",
    "progress_level": "amateur"
  },
  "stats": {
    "completed_quizzes_count": 8,
    "completed_subtopic_quizzes_count": 7,
    "completed_topic_final_quizzes_count": 1,
    "completed_subtopics_count": 4,
    "completed_topics_count": 1,
    "average_best_score_percent": 78.5,
    "average_all_attempts_score_percent": 71.25,
    "max_score_quizzes_count": 2,
    "best_topic_code": "budgeting",
    "weakest_topic_code": "investing",
    "last_quiz_completed_at": "2026-05-01T12:34:56Z"
  }
}
```

### Possible `progress_level`

```text
beginner
amateur
practitioner
advanced_learner
```

### Progress Level Thresholds

```text
0..59 XP => beginner
60..149 XP => amateur
150..259 XP => practitioner
260+ XP => advanced_learner
```

### Optional Fields

These fields may be absent if there is no data:

```text
progress.last_activity_at
stats.best_topic_code
stats.weakest_topic_code
stats.last_quiz_completed_at
```

### Notes

If the progress row does not exist, the backend automatically creates an empty progress row.

### Errors

```text
400 INVALID_USER_ID
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 USER_PROGRESS_NOT_FOUND
404 LEARNING_STATS_NOT_FOUND
500 INTERNAL_ERROR
```

---

# 7. Adaptation / Recommendation API

All endpoints are protected.

Query param:

```text
?lang=ru|kk|en
```

If `lang` is not provided, the backend uses `kk`.

---

## 7.1 Home Recommendations

```http
GET /api/adaptation/recommendations/home?lang=ru
```

Auth header: required.

Returns recommendations for the home screen.

### Response `200 OK` with recommendations

```json
{
  "state": "HAS_RECOMMENDATIONS",
  "continueLearning": {
    "type": "NEXT_LESSON",
    "topicCode": "budgeting",
    "subtopicCode": "fixed_variable_expenses",
    "title": "Fixed and variable expenses",
    "reasonType": "NEXT_LOGICAL_STEP",
    "score": 2.4186
  },
  "nextRecommended": null,
  "recommended": [
    {
      "topicCode": "budgeting",
      "subtopicCode": "fixed_variable_expenses",
      "title": "Fixed and variable expenses",
      "rank": 1,
      "reasonType": "NEXT_LOGICAL_STEP",
      "score": 2.4186
    }
  ]
}
```

### Response when user needs reinforcement

```json
{
  "state": "HAS_RECOMMENDATIONS",
  "continueLearning": {
    "type": "NEEDS_REINFORCEMENT",
    "topicCode": "budgeting",
    "subtopicCode": "income_expenses",
    "title": "Income and expenses",
    "reasonType": "NEEDS_REINFORCEMENT",
    "score": null
  },
  "nextRecommended": {
    "type": "NEXT_LESSON",
    "topicCode": "savings",
    "subtopicCode": "why_save",
    "title": "Why save money",
    "reasonType": "MATCHES_USER_INTEREST",
    "score": 1.9043
  },
  "recommended": [
    {
      "topicCode": "savings",
      "subtopicCode": "why_save",
      "title": "Why save money",
      "rank": 1,
      "reasonType": "MATCHES_USER_INTEREST",
      "score": 1.9043
    }
  ]
}
```

### Response when all content is completed

```json
{
  "state": "ALL_COMPLETED",
  "continueLearning": null,
  "nextRecommended": null,
  "recommended": []
}
```

### Possible `state`

```text
HAS_RECOMMENDATIONS
ALL_COMPLETED
```

### Possible action `type`

```text
NEEDS_REINFORCEMENT
NEXT_LESSON
```

### Possible `reasonType`

```text
NEEDS_REINFORCEMENT
NEXT_BEST_LESSON
NEXT_LOGICAL_STEP
MATCHES_USER_INTEREST
MATCHES_USER_LEVEL
```

### Flutter Notes

- `continueLearning` can be `null`
- `nextRecommended` can be `null`
- `score` inside an action can be `null`, especially for reinforcement
- `recommended` usually contains up to 3 items

### Errors

```text
400 INVALID_USER_ID
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 RECOMMENDATION_DATA_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 7.2 Learning Map

```http
GET /api/adaptation/learning-map?lang=ru
```

Auth header: required.

Returns a list of topics with aggregated status.

### Response `200 OK`

```json
{
  "topics": [
    {
      "code": "budgeting",
      "title": "Budgeting",
      "level": "beginner",
      "orderIndex": 1,
      "status": "IN_PROGRESS",
      "totalSubtopics": 5,
      "completedSubtopics": 2,
      "recommendedSubtopics": 1,
      "needsReinforcementSubtopics": 0
    }
  ]
}
```

### Possible topic `status`

```text
COMPLETED
NEEDS_REINFORCEMENT
RECOMMENDED
IN_PROGRESS
AVAILABLE
```

### Errors

```text
400 INVALID_USER_ID
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 RECOMMENDATION_DATA_NOT_FOUND
500 INTERNAL_ERROR
```

---

## 7.3 Topic Learning Map

```http
GET /api/adaptation/topics/{topicCode}/learning-map?lang=ru
```

Auth header: required.

Returns one topic and all its subtopics with statuses.

### Path params

```text
topicCode: string
```

### Response `200 OK`

```json
{
  "topic": {
    "code": "budgeting",
    "title": "Budgeting",
    "level": "beginner",
    "orderIndex": 1,
    "status": "IN_PROGRESS",
    "totalSubtopics": 5,
    "completedSubtopics": 2,
    "subtopics": [
      {
        "code": "income_expenses",
        "title": "Income and expenses",
        "orderIndex": 1,
        "estimatedMinutes": 5,
        "status": "COMPLETED"
      },
      {
        "code": "fixed_variable_expenses",
        "title": "Fixed and variable expenses",
        "orderIndex": 2,
        "estimatedMinutes": 5,
        "status": "RECOMMENDED"
      }
    ]
  }
}
```

### Possible subtopic `status`

```text
COMPLETED
NEEDS_REINFORCEMENT
RECOMMENDED
AVAILABLE
```

### Possible topic `status`

```text
COMPLETED
NEEDS_REINFORCEMENT
RECOMMENDED
IN_PROGRESS
AVAILABLE
```

### Errors

```text
400 INVALID_TOPIC_CODE
400 INVALID_USER_ID
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
404 TOPIC_NOT_FOUND
404 RECOMMENDATION_DATA_NOT_FOUND
500 INTERNAL_ERROR
```

---

# 8. Recommended Flutter Flow

## First Launch / Auth Flow

1. User registers, logs in, or logs in with Google.
2. Flutter saves:
   - `access_token`
   - `refresh_token`
3. Flutter calls:

```http
GET /api/profile/me
```

4. If the response is `404 PROFILE_NOT_FOUND`, show the onboarding questionnaire.
5. After onboarding, submit:

```http
PUT /api/profile/me
```

6. Then go to the home screen and call:

```http
GET /api/adaptation/recommendations/home?lang=<selected_language>
GET /api/progress/me
```

---

## Home Screen Flow

Use:

```http
GET /api/adaptation/recommendations/home?lang=ru
GET /api/progress/me
```

Show:

- total XP
- progress level
- continue learning card
- recommended lessons list

---

## Learning Map Flow

Use:

```http
GET /api/adaptation/learning-map?lang=ru
```

Then when the user opens a topic:

```http
GET /api/adaptation/topics/{topicCode}/learning-map?lang=ru
```

Then when the user opens a subtopic lesson:

```http
GET /api/content/subtopics/{subtopicCode}/lesson?lang=ru
```

---

## Lesson + Quiz Flow

Recommended flow when opening a topic from the content screen:

1. Flutter gets topic subtopics:

```http
GET /api/content/topics/{topicCode}/subtopics?lang=ru
```

2. Flutter stores `subtopic.quizId` for each subtopic card.
3. User opens a lesson:

```http
GET /api/content/subtopics/{subtopicCode}/lesson?lang=ru
```

4. Flutter renders all lesson steps.
5. After the lesson, Flutter starts the subtopic quiz using the already known `subtopic.quizId`:

```http
POST /api/assessment/quizzes/{quizId}/start?lang=ru
```

6. Render questions from the `/start` response.
7. Submit:

```http
POST /api/assessment/attempts/{attemptId}/submit
```

8. After submit, refresh:

```http
GET /api/progress/me
GET /api/adaptation/recommendations/home?lang=ru
GET /api/adaptation/learning-map?lang=ru
```

Final quiz flow:

1. Flutter shows `finalQuiz` as a separate card at the bottom of the topic screen.
2. On tap, Flutter starts the quiz directly by `finalQuiz.quizId`:

```http
POST /api/assessment/quizzes/{finalQuiz.quizId}/start?lang=ru
```

3. Then submit the attempt and refresh progress/adaptation state.

---

# 9. Important Backend Notes for Flutter

## 9.1 No Public Questionnaire Options Endpoint

The service has a `GetQuestionnaireOptions` method, but the router does not expose it as an endpoint.

For now, Flutter should keep enum options locally, or the backend should add an endpoint such as:

```http
GET /api/profile/questionnaire-options
```

## 9.2 Subtopic Quiz ID

`GET /api/content/topics/{topicCode}/subtopics` should return `quizId` inside every regular subtopic.

This is needed for a simple Flutter flow:

```text
subtopic.code -> open lesson
subtopic.quizId -> open quiz after lesson
```

Subtopic example:

```json
{
  "code": "income_expenses",
  "orderIndex": 1,
  "estimatedMinutes": 5,
  "title": "Income and expenses",
  "description": "Subtopic description",
  "quizId": 10
}
```

A separate endpoint like `GET /api/assessment/quizzes/by-subtopic/{subtopicCode}` is not needed for MVP if `quizId` already comes in the content response.

## 9.3 Final Quiz Display

`finalQuiz` comes in the same endpoint:

```http
GET /api/content/topics/{topicCode}/subtopics?lang=ru
```

Flutter should display it as a separate card after the regular subtopics list.

Example:

```text
Topic screen
├── Subtopic 1
├── Subtopic 2
├── Subtopic 3
└── Final Quiz
```

`finalQuiz` does not open a lesson. It directly opens the quiz flow by `finalQuiz.quizId`.

For MVP, the card can be shown whenever `finalQuiz != null`.

If the app needs to guide the user, show this text:

```text
Recommended after completing all subtopics
```

Strictly locking the final quiz is not required.

## 9.4 Content Interactive Schemas Are Dynamic

`content` and `interactiveContent` do not have one strict DTO. Flutter should be ready for different JSON shapes.

Best current option:

```dart
Map<String, dynamic> content;
Map<String, dynamic>? interactiveContent;
```

## 9.5 Mixed snake_case and camelCase

Configure Flutter models carefully:

- `AuthResponse`: snake_case for token fields
- `ProfileResponse`: camelCase
- `ProfileRequest`: snake_case
- `SettingsRequest`: snake_case
- `SettingsResponse`: camelCase
- `ContentResponse`: camelCase
- `AssessmentResponse`: snake_case
- `ProgressResponse`: snake_case
- `AdaptationResponse`: camelCase

---

# 10. Common Auth Middleware Errors

All protected endpoints can return:

```text
401 MISSING_TOKEN
401 INVALID_TOKEN_FORMAT
401 INVALID_TOKEN
401 UNAUTHORIZED
```

For `401 INVALID_TOKEN` or expired access token, Flutter should try the refresh flow:

```http
POST /api/auth/refresh
```

If refresh also fails, log the user out and navigate to the login screen.
