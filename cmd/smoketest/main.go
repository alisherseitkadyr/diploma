// Smoke test for the SmartFin API. Run with:
//
//	go run ./cmd/smoketest [-base-url http://localhost:8081/api] [-google-token TOKEN]
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// ---------------------------------------------------------------------------
// CLI flags
// ---------------------------------------------------------------------------

var (
	baseURL     = flag.String("base-url", "http://localhost:8081/api", "API base URL")
	googleToken = flag.String("google-token", "", "Google ID token for /auth/google test (optional)")
)

// ---------------------------------------------------------------------------
// Result tracking
// ---------------------------------------------------------------------------

type result struct {
	endpoint string
	status   int
}

var results []result

func pass(endpoint string, status int) {
	results = append(results, result{endpoint, status})
}

func printResults() {
	fmt.Println()
	fmt.Printf("%-60s  %s\n", "ENDPOINT", "STATUS")
	fmt.Println(strings.Repeat("-", 70))
	for _, r := range results {
		fmt.Printf("%-60s  %d\n", r.endpoint, r.status)
	}
}

// ---------------------------------------------------------------------------
// HTTP core
// ---------------------------------------------------------------------------

var httpClient = &http.Client{Timeout: 15 * time.Second}

// doRaw executes one HTTP request and returns the status code and raw body.
func doRaw(method, path, token string, body any) (int, []byte) {
	url := strings.TrimRight(*baseURL, "/") + path

	var reqBody io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		must(err, "marshal body")
		reqBody = bytes.NewReader(b)
	}

	req, err := http.NewRequest(method, url, reqBody)
	must(err, "new request")

	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	resp, err := httpClient.Do(req)
	must(err, method+" "+url)
	defer resp.Body.Close()

	raw, _ := io.ReadAll(resp.Body)
	return resp.StatusCode, raw
}

// do executes a request and parses the body as a JSON object.
func do(method, path, token string, body any) (int, map[string]any) {
	status, raw := doRaw(method, path, token, body)
	var obj map[string]any
	if len(raw) > 0 {
		_ = json.Unmarshal(raw, &obj)
	}
	return status, obj
}

// doArr executes a request and parses the body as a JSON array.
func doArr(method, path, token string, body any) (int, []any) {
	status, raw := doRaw(method, path, token, body)
	var arr []any
	if len(raw) > 0 {
		if err := json.Unmarshal(raw, &arr); err != nil {
			fatalf("%s %s: response is not a JSON array: %s", method, path, string(raw))
		}
	}
	return status, arr
}

// expectObj calls do() and fatals if the status is not in want.
func expectObj(method, path, label, token string, body any, want ...int) (int, map[string]any) {
	status, j := do(method, path, token, body)
	for _, w := range want {
		if status == w {
			if label != "" {
				pass(label, status)
			}
			return status, j
		}
	}
	fatalf("%s %s: expected %v, got %d\n  body: %s", method, path, want, status, mustJSON(j))
	return 0, nil
}

// expectArr calls doArr() and fatals if the status is not in want.
func expectArr(method, path, label, token string, body any, want ...int) (int, []any) {
	status, arr := doArr(method, path, token, body)
	for _, w := range want {
		if status == w {
			if label != "" {
				pass(label, status)
			}
			return status, arr
		}
	}
	fatalf("%s %s: expected %v, got %d", method, path, want, status)
	return 0, nil
}

// expectStatus calls doRaw() and fatals if the status is not in want.
// Use this for responses with no body (204) or when the body is irrelevant.
func expectStatus(method, path, label, token string, body any, want ...int) int {
	status, _ := doRaw(method, path, token, body)
	for _, w := range want {
		if status == w {
			if label != "" {
				pass(label, status)
			}
			return status
		}
	}
	fatalf("%s %s: expected %v, got %d", method, path, want, status)
	return 0
}

// ---------------------------------------------------------------------------
// Assertion helpers
// ---------------------------------------------------------------------------

func assertStr(j map[string]any, key, expected, ctx string) {
	got := strField(j, key)
	if got != expected {
		fatalf("%s: field %q: expected %q, got %q", ctx, key, expected, got)
	}
}

func assertBool(j map[string]any, key string, expected bool, ctx string) {
	v, ok := j[key]
	if !ok {
		fatalf("%s: missing field %q", ctx, key)
	}
	got, ok := v.(bool)
	if !ok {
		fatalf("%s: field %q is not bool (got %T %v)", ctx, key, v, v)
	}
	if got != expected {
		fatalf("%s: field %q: expected %v, got %v", ctx, key, expected, got)
	}
}

func assertExists(j map[string]any, key, ctx string) {
	if _, ok := j[key]; !ok {
		fatalf("%s: missing field %q", ctx, key)
	}
}

func assertPosInt(j map[string]any, key, ctx string) {
	v, ok := j[key]
	if !ok {
		fatalf("%s: missing field %q", ctx, key)
	}
	f, ok := v.(float64)
	if !ok || f <= 0 {
		fatalf("%s: field %q must be a positive number, got %v", ctx, key, v)
	}
}

func assertGe(j map[string]any, key string, minVal float64, ctx string) {
	v, ok := j[key]
	if !ok {
		fatalf("%s: missing field %q", ctx, key)
	}
	f, ok := v.(float64)
	if !ok {
		fatalf("%s: field %q is not a number (got %T)", ctx, key, v)
	}
	if f < minVal {
		fatalf("%s: field %q: expected >= %.0f, got %.0f", ctx, key, minVal, f)
	}
}

func assertArrLen(arr []any, minLen int, ctx string) {
	if len(arr) < minLen {
		fatalf("%s: expected at least %d elements, got %d", ctx, minLen, len(arr))
	}
}

func assertFieldArrLen(j map[string]any, key string, minLen int, ctx string) []any {
	v, ok := j[key]
	if !ok {
		fatalf("%s: missing array field %q", ctx, key)
	}
	// JSON null is valid for an optional array field; treat as empty.
	if v == nil {
		if minLen > 0 {
			fatalf("%s: field %q is null, expected >= %d elements", ctx, key, minLen)
		}
		return nil
	}
	arr, ok := v.([]any)
	if !ok {
		fatalf("%s: field %q is not an array (got %T)", ctx, key, v)
	}
	if len(arr) < minLen {
		fatalf("%s: field %q: expected >= %d elements, got %d", ctx, key, minLen, len(arr))
	}
	return arr
}

func objField(j map[string]any, key, ctx string) map[string]any {
	v, ok := j[key]
	if !ok {
		fatalf("%s: missing object field %q", ctx, key)
	}
	obj, ok := v.(map[string]any)
	if !ok {
		fatalf("%s: field %q is not an object (got %T)", ctx, key, v)
	}
	return obj
}

func strField(j map[string]any, key string) string {
	v, _ := j[key]
	s, _ := v.(string)
	return s
}

func numField(j map[string]any, key string) float64 {
	v, _ := j[key]
	f, _ := v.(float64)
	return f
}

// ---------------------------------------------------------------------------
// Misc
// ---------------------------------------------------------------------------

func step(msg string) { fmt.Printf("\n==> %s\n", msg) }

func must(err error, ctx string) {
	if err != nil {
		fatalf("%s: %v", ctx, err)
	}
}

func fatalf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "\nFAIL: "+format+"\n", args...)
	printResults()
	os.Exit(1)
}

func mustJSON(v any) string {
	b, _ := json.MarshalIndent(v, "  ", "  ")
	return string(b)
}

// submitAttempt builds a first-option-per-question payload and submits it.
func submitAttempt(token string, attemptID float64, questions []any) map[string]any {
	type answer struct {
		QuestionID        float64   `json:"question_id"`
		SelectedOptionIDs []float64 `json:"selected_option_ids"`
	}
	var answers []answer
	for _, q := range questions {
		qObj, _ := q.(map[string]any)
		opts, _ := qObj["options"].([]any)
		if len(opts) == 0 {
			fatalf("question %.0f has no options", numField(qObj, "id"))
		}
		opt, _ := opts[0].(map[string]any)
		answers = append(answers, answer{
			QuestionID:        numField(qObj, "id"),
			SelectedOptionIDs: []float64{numField(opt, "id")},
		})
	}
	path := fmt.Sprintf("/assessment/attempts/%.0f/submit", attemptID)
	label := fmt.Sprintf("POST /assessment/attempts/{%.0f}/submit", attemptID)
	_, j := expectObj("POST", path, label, token,
		map[string]any{"duration_seconds": 90, "answers": answers},
		200)
	return j
}

// findFirstQuiz scans quiz IDs 1..300 for the first active one.
func findFirstQuiz(token string) float64 {
	for id := 1; id <= 300; id++ {
		path := fmt.Sprintf("/assessment/quizzes/%d?lang=en", id)
		status, j := do("GET", path, token, nil)
		if status == 200 {
			return numField(j, "id")
		}
		if errObj, ok := j["error"].(map[string]any); ok {
			if strField(errObj, "code") == "QUIZ_NOT_FOUND" {
				continue
			}
		}
		fatalf("unexpected response probing quiz %d: status %d body %s", id, status, mustJSON(j))
	}
	fatalf("no active quiz found in range 1..300 — did you run `make seed`?")
	return 0
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

func main() {
	flag.Parse()

	stamp := time.Now().UnixMilli()
	suffix := stamp % 1_000_000
	email := fmt.Sprintf("smoke.%d@example.com", stamp)
	username := fmt.Sprintf("sm%06d", suffix)
	updUsername := fmt.Sprintf("up%06d", suffix)
	password := fmt.Sprintf("pass%d1", stamp)
	newPassword := fmt.Sprintf("new%d1", stamp)

	// -------------------------------------------------------------------------
	// Auth
	// -------------------------------------------------------------------------
	step("Register temp user")
	_, regJ := expectObj("POST", "/auth/register", "POST /auth/register", "", map[string]any{
		"email": email, "username": username, "password": password,
	}, 201)
	assertStr(objField(regJ, "user", "register"), "email", email, "register.user")
	registerToken := strField(regJ, "access_token")

	step("Login")
	_, loginJ := expectObj("POST", "/auth/login", "POST /auth/login", "", map[string]any{
		"email": email, "password": password,
	}, 200)
	loginRefresh := strField(loginJ, "refresh_token")

	if *googleToken != "" {
		step("Google login")
		expectObj("POST", "/auth/google", "POST /auth/google", "", map[string]any{
			"id_token": *googleToken,
		}, 200)
	} else {
		fmt.Println("  skipping POST /auth/google (no -google-token provided)")
	}

	step("GET /auth/me")
	_, meJ := expectObj("GET", "/auth/me", "GET /auth/me", registerToken, nil, 200)
	assertStr(meJ, "email", email, "GET /auth/me")

	step("PATCH /auth/me/username")
	_, updJ := expectObj("PATCH", "/auth/me/username", "PATCH /auth/me/username", registerToken, map[string]any{
		"new_username": updUsername,
	}, 200)
	assertStr(updJ, "username", updUsername, "PATCH /auth/me/username")

	step("POST /auth/refresh")
	_, refJ := expectObj("POST", "/auth/refresh", "POST /auth/refresh", "", map[string]any{
		"refresh_token": loginRefresh,
	}, 200)
	refreshedRefresh := strField(refJ, "refresh_token")

	step("POST /auth/logout (refreshed session)")
	_, logoutJ := expectObj("POST", "/auth/logout", "POST /auth/logout", "", map[string]any{
		"refresh_token": refreshedRefresh,
	}, 200)
	assertStr(logoutJ, "message", "LOGGED_OUT", "logout")

	step("Login again after logout")
	_, la0 := expectObj("POST", "/auth/login", "", "", map[string]any{
		"email": email, "password": password,
	}, 200)
	token := strField(la0, "access_token")
	refresh := strField(la0, "refresh_token")

	step("PATCH /auth/me/password (change)")
	_, cpJ := expectObj("PATCH", "/auth/me/password", "PATCH /auth/me/password", token, map[string]any{
		"current_password": password,
		"new_password":     newPassword,
		"refresh_token":    refresh,
	}, 200)
	assertStr(cpJ, "message", "PASSWORD_CHANGED", "change password")

	step("Login with new password")
	_, lnJ := expectObj("POST", "/auth/login", "", "", map[string]any{
		"email": email, "password": newPassword,
	}, 200)
	token = strField(lnJ, "access_token")
	refresh = strField(lnJ, "refresh_token")

	step("PATCH /auth/me/password (revert)")
	_, rvJ := expectObj("PATCH", "/auth/me/password", "", token, map[string]any{
		"current_password": newPassword,
		"new_password":     password,
		"refresh_token":    refresh,
	}, 200)
	assertStr(rvJ, "message", "PASSWORD_CHANGED", "revert password")

	step("Final login for authenticated tests")
	_, flJ := expectObj("POST", "/auth/login", "", "", map[string]any{
		"email": email, "password": password,
	}, 200)
	token = strField(flJ, "access_token")
	refresh = strField(flJ, "refresh_token")

	// -------------------------------------------------------------------------
	// Profile
	// -------------------------------------------------------------------------
	step("GET /profile/me (before onboarding — expect 404)")
	_, mpJ := expectObj("GET", "/profile/me", "GET /profile/me (missing)", token, nil, 404)
	assertStr(objField(mpJ, "error", "missing profile"), "code", "PROFILE_NOT_FOUND", "missing profile")

	step("GET /profile/settings (before onboarding — expect 404)")
	_, msJ := expectObj("GET", "/profile/settings", "GET /profile/settings (missing)", token, nil, 404)
	assertStr(objField(msJ, "error", "missing settings"), "code", "SETTINGS_NOT_FOUND", "missing settings")

	step("PUT /profile/me (onboarding)")
	_, upJ := expectObj("PUT", "/profile/me", "PUT /profile/me", token, map[string]any{
		"financial_literacy_level": "beginner",
		"practical_experience":     "no_experience",
		"learning_goal":            "saving_money",
		"preferred_language":       "en",
		"time_commitment":          "10_min",
		"preferred_topics":         []string{"budgeting", "savings"},
	}, 200)
	assertStr(upJ, "preferredLanguage", "en", "PUT /profile/me")

	step("GET /profile/me")
	_, profJ := expectObj("GET", "/profile/me", "GET /profile/me", token, nil, 200)
	assertBool(profJ, "onboardingCompleted", true, "GET /profile/me")

	step("GET /profile/settings")
	_, setJ := expectObj("GET", "/profile/settings", "GET /profile/settings", token, nil, 200)
	assertStr(setJ, "languageCode", "en", "GET /profile/settings")

	step("PATCH /profile/settings")
	_, psJ := expectObj("PATCH", "/profile/settings", "PATCH /profile/settings", token, map[string]any{
		"language_code":         "kk",
		"theme":                 "dark",
		"notifications_enabled": true,
		"reminder_time":         "21:30:00",
	}, 200)
	assertStr(psJ, "languageCode", "kk", "PATCH /profile/settings")
	assertStr(psJ, "theme", "dark", "PATCH /profile/settings")

	// -------------------------------------------------------------------------
	// Content — topics (response is a bare JSON array)
	// -------------------------------------------------------------------------
	step("GET /content/topics")
	_, topicsArr := expectArr("GET", "/content/topics?lang=en", "GET /content/topics", token, nil, 200)
	if len(topicsArr) == 0 {
		fatalf("GET /content/topics: empty array — did you run `make seed`?")
	}
	topic0 := topicsArr[0].(map[string]any)
	topicCode := strField(topic0, "code")
	assertPosInt(topic0, "id", "topics[0]")
	fmt.Printf("  topic: code=%s id=%.0f\n", topicCode, numField(topic0, "id"))

	// -------------------------------------------------------------------------
	// Content — subtopics (response is {subtopics:[...], finalQuiz:{...}})
	// -------------------------------------------------------------------------
	step("GET /content/topics/{topicCode}/subtopics")
	subPath := fmt.Sprintf("/content/topics/%s/subtopics?lang=en", topicCode)
	_, subJ := expectObj("GET", subPath, "GET /content/topics/{topicCode}/subtopics", token, nil, 200)
	subtopicsArr := assertFieldArrLen(subJ, "subtopics", 1, "subtopics response")
	sub0 := subtopicsArr[0].(map[string]any)
	subtopicCode := strField(sub0, "code")
	assertPosInt(sub0, "id", "subtopics[0]")
	fmt.Printf("  subtopic: code=%s id=%.0f\n", subtopicCode, numField(sub0, "id"))

	var finalQuizID float64
	if fq, ok := subJ["finalQuiz"].(map[string]any); ok && fq != nil {
		finalQuizID = numField(fq, "quizId")
		fmt.Printf("  finalQuizId=%.0f\n", finalQuizID)
	} else {
		fmt.Println("  no finalQuiz in subtopics response")
	}

	var subtopicQuizID float64
	if v, ok := sub0["quizId"]; ok && v != nil {
		subtopicQuizID, _ = v.(float64)
		fmt.Printf("  subtopicQuizId=%.0f\n", subtopicQuizID)
	}

	// -------------------------------------------------------------------------
	// Content — lesson
	// -------------------------------------------------------------------------
	step("GET /content/subtopics/{subtopicCode}/lesson")
	lessonPath := fmt.Sprintf("/content/subtopics/%s/lesson?lang=en", subtopicCode)
	_, lessonJ := expectObj("GET", lessonPath, "GET /content/subtopics/{subtopicCode}/lesson", token, nil, 200)
	assertExists(lessonJ, "lessonId", "lesson")
	assertExists(lessonJ, "steps", "lesson")
	fmt.Printf("  lessonId=%.0f  steps=%d\n", numField(lessonJ, "lessonId"), len(assertFieldArrLen(lessonJ, "steps", 0, "lesson")))

	// -------------------------------------------------------------------------
	// Content — mark subtopic read
	// -------------------------------------------------------------------------
	step("POST /content/subtopics/{subtopicCode}/complete")
	completePath := fmt.Sprintf("/content/subtopics/%s/complete", subtopicCode)
	expectStatus("POST", completePath, "POST /content/subtopics/{subtopicCode}/complete", token, nil, 204)

	step("POST /content/subtopics/{subtopicCode}/complete (idempotent)")
	expectStatus("POST", completePath, "POST /content/subtopics/{subtopicCode}/complete (idempotent)", token, nil, 204)

	// -------------------------------------------------------------------------
	// Assessment — subtopic quiz
	// -------------------------------------------------------------------------
	var quizID float64
	if subtopicQuizID > 0 {
		step("GET /assessment/quizzes/{quizId} (from subtopic)")
		quizPath := fmt.Sprintf("/assessment/quizzes/%.0f?lang=en", subtopicQuizID)
		expectObj("GET", quizPath, "GET /assessment/quizzes/{quizId}", token, nil, 200)
		quizID = subtopicQuizID
	} else {
		step("Find first valid quiz (scanning 1..300)")
		quizID = findFirstQuiz(token)
		pass("GET /assessment/quizzes/{quizId}", 200)
	}

	step("GET /assessment/quizzes/{quizId}/latest-attempt (before start)")
	latestPath := fmt.Sprintf("/assessment/quizzes/%.0f/latest-attempt", quizID)
	_, laB := expectObj("GET", latestPath, "GET /assessment/quizzes/{quizId}/latest-attempt (before)", token, nil, 200)
	assertBool(laB, "has_attempt", false, "latest-attempt before start")

	step("POST /assessment/quizzes/{quizId}/start")
	startPath := fmt.Sprintf("/assessment/quizzes/%.0f/start?lang=en", quizID)
	_, startJ := expectObj("POST", startPath, "POST /assessment/quizzes/{quizId}/start", token, nil, 201)
	attemptID := numField(startJ, "attempt_id")
	questions := assertFieldArrLen(startJ, "questions", 1, "start quiz")
	fmt.Printf("  attempt_id=%.0f  questions=%d\n", attemptID, len(questions))

	step("POST /assessment/attempts/{attemptId}/submit")
	submitJ := submitAttempt(token, attemptID, questions)
	if numField(submitJ, "attempt_id") != attemptID {
		fatalf("submit: attempt_id mismatch")
	}
	assertExists(submitJ, "score_percent", "submit")
	assertExists(submitJ, "passed", "submit")

	step("GET /assessment/quizzes/{quizId}/latest-attempt (after submit)")
	_, laA := expectObj("GET", latestPath, "GET /assessment/quizzes/{quizId}/latest-attempt (after)", token, nil, 200)
	assertBool(laA, "has_attempt", true, "latest-attempt after submit")

	step("GET /assessment/attempts/{attemptId}")
	detailPath := fmt.Sprintf("/assessment/attempts/%.0f?lang=en", attemptID)
	_, detailJ := expectObj("GET", detailPath, "GET /assessment/attempts/{attemptId}", token, nil, 200)
	assertFieldArrLen(detailJ, "answers", 1, "attempt detail")

	// -------------------------------------------------------------------------
	// Assessment — topic final quiz (questions sampled from subtopic pools)
	// -------------------------------------------------------------------------
	if finalQuizID > 0 {
		step("POST /assessment/quizzes/{finalQuizId}/start (topic final quiz)")
		fStartPath := fmt.Sprintf("/assessment/quizzes/%.0f/start?lang=en", finalQuizID)
		_, fStartJ := expectObj("POST", fStartPath, "POST /assessment/quizzes/{finalQuizId}/start", token, nil, 201)
		fAttemptID := numField(fStartJ, "attempt_id")
		fQuestions := assertFieldArrLen(fStartJ, "questions", 1, "final quiz start")
		fmt.Printf("  attempt_id=%.0f  questions=%d\n", fAttemptID, len(fQuestions))

		step("POST /assessment/attempts/{finalAttemptId}/submit")
		fSubmitJ := submitAttempt(token, fAttemptID, fQuestions)
		if numField(fSubmitJ, "attempt_id") != fAttemptID {
			fatalf("final quiz submit: attempt_id mismatch")
		}
		assertExists(fSubmitJ, "score_percent", "final quiz submit")
	} else {
		fmt.Println("  skipping topic final quiz test (no finalQuiz in response)")
	}

	// -------------------------------------------------------------------------
	// Progress — assert TopicProgressDetail shape
	// -------------------------------------------------------------------------
	step("GET /progress/me")
	_, progJ := expectObj("GET", "/progress/me", "GET /progress/me", token, nil, 200)
	progObj := objField(progJ, "progress", "GET /progress/me")
	assertExists(progJ, "stats", "GET /progress/me")

	if topicsMap, ok := progObj["topics"].(map[string]any); ok && topicsMap != nil {
		if topicDetail, ok := topicsMap[topicCode].(map[string]any); ok {
			ctx := fmt.Sprintf("topics[%s]", topicCode)
			assertExists(topicDetail, "subtopics_read", ctx)
			assertExists(topicDetail, "total_subtopics", ctx)
			assertExists(topicDetail, "quiz_passed", ctx)
			assertExists(topicDetail, "is_complete", ctx)
			assertGe(topicDetail, "subtopics_read", 1, ctx+" after complete")
			fmt.Printf("  subtopics_read=%.0f  total=%.0f  quiz_passed=%v  is_complete=%v\n",
				numField(topicDetail, "subtopics_read"),
				numField(topicDetail, "total_subtopics"),
				topicDetail["quiz_passed"],
				topicDetail["is_complete"],
			)
		} else {
			fmt.Printf("  topic [%s] not in topics map yet (no quiz attempts for it — OK)\n", topicCode)
		}
	} else {
		fmt.Println("  progress.topics is null (no quiz attempts yet)")
	}

	// -------------------------------------------------------------------------
	// Auth — DELETE /auth/me (secondary throwaway user)
	// -------------------------------------------------------------------------
	step("Register secondary user for DELETE /auth/me test")
	stamp2 := time.Now().UnixMilli() + 1
	_, delRegJ := expectObj("POST", "/auth/register", "", "", map[string]any{
		"email":    fmt.Sprintf("del.%d@example.com", stamp2),
		"username": fmt.Sprintf("dl%06d", stamp2%1_000_000),
		"password": fmt.Sprintf("delpass%d1", stamp2),
	}, 201)
	delToken := strField(delRegJ, "access_token")
	delEmail := strField(objField(delRegJ, "user", "del register"), "email")
	delPass := fmt.Sprintf("delpass%d1", stamp2)

	step("DELETE /auth/me")
	expectStatus("DELETE", "/auth/me", "DELETE /auth/me", delToken, nil, 204)

	step("POST /auth/login (after delete — must fail)")
	status, _ := do("POST", "/auth/login", "", map[string]any{
		"email": delEmail, "password": delPass,
	})
	if status == 200 {
		fatalf("login after account deletion returned 200 — user was not deleted")
	}
	pass("POST /auth/login (after delete)", status)

	// -------------------------------------------------------------------------
	// Auth — logout main session
	// -------------------------------------------------------------------------
	step("POST /auth/logout (final)")
	_, flogJ := expectObj("POST", "/auth/logout", "POST /auth/logout (final)", "", map[string]any{
		"refresh_token": refresh,
	}, 200)
	assertStr(flogJ, "message", "LOGGED_OUT", "final logout")

	// -------------------------------------------------------------------------
	// Done
	// -------------------------------------------------------------------------
	printResults()
	fmt.Printf("\nAll %d checks passed.\n", len(results))
}
