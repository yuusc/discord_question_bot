package bot

import (
	"fmt"
	"strings"

	"github.com/bwmarrin/discordgo"
)

// hasPrefix はメッセージが指定プレフィックスの後に区切り文字（半角/全角スペース・タブ）を持つか確認する
func hasPrefix(s, prefix string) bool {
	if !strings.HasPrefix(s, prefix) {
		return false
	}
	rest := s[len(prefix):]
	return strings.HasPrefix(rest, " ") || strings.HasPrefix(rest, "　") || strings.HasPrefix(rest, "\t")
}

// trimPrefix はプレフィックスと直後の区切り文字を除いた本文を返す
func trimPrefix(s, prefix string) string {
	rest := s[len(prefix):]
	return strings.TrimPrefix(strings.TrimPrefix(strings.TrimPrefix(rest, " "), "　"), "\t")
}

func (b *Bot) messageCreate(s *discordgo.Session, m *discordgo.MessageCreate) {
	if m.Author.ID == s.State.User.ID {
		return
	}

	ch, err := s.Channel(m.ChannelID)
	if err != nil || ch.Type != discordgo.ChannelTypeDM {
		return
	}

	for _, cmd := range b.commands {
		if hasPrefix(m.Content, cmd.prefix) {
			content := strings.TrimSpace(trimPrefix(m.Content, cmd.prefix))
			cmd.handler(s, m, content)
			return
		}
	}

	var lines []string
	for _, cmd := range b.commands {
		lines = append(lines, fmt.Sprintf("`%s` - %s", cmd.prefix, cmd.description))
	}
	s.ChannelMessageSend(m.ChannelID, "使い方:\n"+strings.Join(lines, "\n"))
}
