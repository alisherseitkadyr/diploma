package mlclient

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

type Client interface {
	PredictReinforcement(ctx context.Context, req ReinforcementPredictRequest) (*ReinforcementPredictResponse, error)
	RankNextLessons(ctx context.Context, req NextLessonRankRequest) (*NextLessonRankResponse, error)
}

type HTTPClient struct {
	baseURL    string
	httpClient *http.Client
}

func NewHTTPClient(baseURL string) *HTTPClient {
	return &HTTPClient{
		baseURL: strings.TrimRight(baseURL, "/"),
		httpClient: &http.Client{
			Timeout: 2 * time.Second,
		},
	}
}

func (c *HTTPClient) PredictReinforcement(ctx context.Context, req ReinforcementPredictRequest) (*ReinforcementPredictResponse, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, err
	}

	httpReq, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+"/predict/reinforcement",
		bytes.NewReader(body),
	)
	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("ml service returned status %d", resp.StatusCode)
	}

	var result ReinforcementPredictResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}

func (c *HTTPClient) RankNextLessons(ctx context.Context, req NextLessonRankRequest) (*NextLessonRankResponse, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, err
	}

	httpReq, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+"/rank/next-lessons",
		bytes.NewReader(body),
	)

	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("ml service returned status %d", resp.StatusCode)
	}

	var result NextLessonRankResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}
