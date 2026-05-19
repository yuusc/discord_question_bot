package bot

import (
	"github.com/bwmarrin/discordgo"
	"github.com/yuusc/discord-anon-bot/config"
)

// CommandHandler はコマンドの処理関数。content はプレフィックスを除いたトリム済みの本文。
type CommandHandler func(s *discordgo.Session, m *discordgo.MessageCreate, content string)

type command struct {
	prefix      string
	description string
	handler     CommandHandler
}

type Bot struct {
	session  *discordgo.Session
	config   *config.Config
	commands []command
}

func New(cfg *config.Config) (*Bot, error) {
	s, err := discordgo.New("Bot " + cfg.BotToken)
	if err != nil {
		return nil, err
	}

	s.Identify.Intents = discordgo.IntentsDirectMessages

	b := &Bot{session: s, config: cfg}
	b.Register("!q", "匿名で質問を投稿", b.handleQuestion)
	s.AddHandler(b.messageCreate)

	return b, nil
}

// Register は新しいコマンドを登録する。
// 新しいコマンドを追加するには、対応する handleXxx メソッドを定義してここで呼び出す。
func (b *Bot) Register(prefix, description string, handler CommandHandler) {
	b.commands = append(b.commands, command{prefix: prefix, description: description, handler: handler})
}

func (b *Bot) Open() error {
	return b.session.Open()
}

func (b *Bot) Close() error {
	return b.session.Close()
}
