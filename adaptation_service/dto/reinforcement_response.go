package dto

type ReinforcementResponse struct {
	NeedsReinforcement bool    `json:"needs_reinforcement"`
	Prediction         int     `json:"prediction"`
	Probability        float64 `json:"probability"`
	Confidence         float64 `json:"confidence"`
	DecisionSource     string  `json:"decision_source"`
	ModelName          string  `json:"model_name,omitempty"`
}
