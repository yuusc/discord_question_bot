package bot

import (
	"github.com/bwmarrin/discordgo"
	"github.com/yuusc/discord-anon-bot/config"
)

type Bot struct {
	session *discordgo.Session
	config  *config.Config
}

func New(cfg *config.Config) (*Bot, error) {
	s, err := discordgo.New("Bot " + cfg.BotToken)
	if err != nil {
		return nil, err
	}

	s.Identify.Intents = discordgo.IntentsDirectMessages

	b := &Bot{session: s, config: cfg}
	s.AddHandler(b.messageCreate)

	return b, nil
}

func (b *Bot) Open() error {
	return b.session.Open()
}

func (b *Bot) Close() error {
	return b.session.Close()
}
