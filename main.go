package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/yuusc/discord-anon-bot/bot"
	"github.com/yuusc/discord-anon-bot/config"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}

	b, err := bot.New(cfg)
	if err != nil {
		log.Fatal("ボットの初期化に失敗しました:", err)
	}

	if err = b.Open(); err != nil {
		log.Fatal("Discord接続に失敗しました:", err)
	}

	log.Println("ボットが起動しました。CTRL-C で終了します。")

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop

	b.Close()
	log.Println("シャットダウン完了。")
}
