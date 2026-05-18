package bot

import (
	"log"
	"strings"

	"github.com/bwmarrin/discordgo"
)

const cmd = "!q"

// hasPrefix は !q の後に半角スペース・全角スペース・タブが続くか確認する
func hasPrefix(s string) bool {
	if !strings.HasPrefix(s, cmd) {
		return false
	}
	rest := s[len(cmd):]
	return strings.HasPrefix(rest, " ") || strings.HasPrefix(rest, "　") || strings.HasPrefix(rest, "\t")
}

// trimPrefix は !q と直後の区切り文字を除いた本文を返す
func trimPrefix(s string) string {
	return strings.TrimPrefix(strings.TrimPrefix(strings.TrimPrefix(s[len(cmd):], " "), "　"), "\t")
}


func (b *Bot) messageCreate(s *discordgo.Session, m *discordgo.MessageCreate) {
	if m.Author.ID == s.State.User.ID {
		return
	}

	ch, err := s.Channel(m.ChannelID)
	if err != nil || ch.Type != discordgo.ChannelTypeDM {
		return
	}

	if !hasPrefix(m.Content) {
		s.ChannelMessageSend(m.ChannelID, "使い方: `!q <質問内容>`")
		return
	}

	content := strings.TrimSpace(trimPrefix(m.Content))
	if content == "" {
		s.ChannelMessageSend(m.ChannelID, "エラー: 質問内容を入力してください。")
		return
	}

	_, err = s.ChannelMessageSend(b.config.TargetChannelID, "【匿名の質問】"+content)
	if err != nil {
		s.ChannelMessageSend(m.ChannelID, "エラー: 質問を投稿できませんでした。しばらくしてから再試行してください。")
		log.Printf("チャンネル %s への投稿に失敗: %v", b.config.TargetChannelID, err)
		return
	}

	s.ChannelMessageSend(m.ChannelID, "✅ 質問を匿名で投稿しました！")
}
