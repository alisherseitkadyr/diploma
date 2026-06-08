package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

func TestFirstSubtopicSeedDecodes(t *testing.T) {
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("resolve test file path")
	}

	data, err := readFirstSubtopicSeed(filepath.Dir(file))
	if err != nil {
		t.Fatalf("read first subtopic seed: %v", err)
	}

	var seed jsonSeed
	if err := json.Unmarshal(data, &seed); err != nil {
		t.Fatalf("decode first subtopic seed: %v", err)
	}
	if err := seed.validate(); err != nil {
		t.Fatalf("validate first subtopic seed: %v", err)
	}

	if got := zeroBasedQuestionOffset(seed.Quiz.Questions); got != 1 {
		t.Fatalf("question order offset = %d, want 1", got)
	}

	for _, question := range seed.Quiz.Questions {
		if got := zeroBasedAnswerOffset(question.Answers); got != 1 {
			t.Fatalf("answer order offset for question %d = %d, want 1", question.ID, got)
		}
	}

	for _, step := range seed.Lesson.Steps {
		content, err := lessonStepContent(step, seed.Subtopic)
		if err != nil {
			t.Fatalf("build content for step %s: %v", step.ID, err)
		}
		if !json.Valid([]byte(content)) {
			t.Fatalf("content for step %s is not valid json", step.ID)
		}
	}
}

func readFirstSubtopicSeed(runnerDir string) ([]byte, error) {
	for _, name := range []string{"001_first_subtopic.json", "001_first_subtopic.sql"} {
		data, err := os.ReadFile(filepath.Join(runnerDir, "..", name))
		if err == nil {
			return data, nil
		}
		if !os.IsNotExist(err) {
			return nil, err
		}
	}
	return nil, os.ErrNotExist
}
