package bot

import (
	"log"

	"github.com/bwmarrin/discordgo"
)

func (b *Bot) handleQuestion(s *discordgo.Session, m *discordgo.MessageCreate, content string) {
	if content == "" {
		s.ChannelMessageSend(m.ChannelID, "エラー: 質問内容を入力してください。")
		return
	}

	_, err := s.ChannelMessageSend(b.config.TargetChannelID, "【匿名の質問】"+content)
	if err != nil {
		s.ChannelMessageSend(m.ChannelID, "エラー: 質問を投稿できませんでした。しばらくしてから再試行してください。")
		log.Printf("チャンネル %s への投稿に失敗: %v", b.config.TargetChannelID, err)
		return
	}

	s.ChannelMessageSend(m.ChannelID, "✅ 質問を匿名で投稿しました！")
}
