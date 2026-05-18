package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	BotToken        string
	TargetChannelID string
}

func Load() (*Config, error) {
	godotenv.Load()

	token := os.Getenv("BOT_TOKEN")
	channelID := os.Getenv("TARGET_CHANNEL_ID")

	if token == "" {
		return nil, fmt.Errorf("BOT_TOKEN が設定されていません")
	}
	if channelID == "" {
		return nil, fmt.Errorf("TARGET_CHANNEL_ID が設定されていません")
	}

	return &Config{
		BotToken:        token,
		TargetChannelID: channelID,
	}, nil
}
