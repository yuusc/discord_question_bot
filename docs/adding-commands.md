# コマンドの追加方法

## 概要

コマンドは以下の2ステップで追加できます。

1. `bot/cmd_<コマンド名>.go` にハンドラーを実装する
2. `bot/bot.go` の `New()` 内でコマンドを登録する

---

## ステップ 1: ハンドラーを実装する

`bot/cmd_<コマンド名>.go` を新規作成し、`Bot` のメソッドとしてハンドラーを定義します。

```go
package bot

import "github.com/bwmarrin/discordgo"

func (b *Bot) handleFeedback(s *discordgo.Session, m *discordgo.MessageCreate, content string) {
    if content == "" {
        s.ChannelMessageSend(m.ChannelID, "エラー: 内容を入力してください。")
        return
    }

    // content にはプレフィックスを除いたテキストが入る
    s.ChannelMessageSend(m.ChannelID, "✅ フィードバックを送信しました！")
}
```

### ハンドラーのシグネチャ

```go
func (b *Bot) handleXxx(s *discordgo.Session, m *discordgo.MessageCreate, content string)
```

| 引数 | 型 | 説明 |
|---|---|---|
| `s` | `*discordgo.Session` | Discord セッション。メッセージ送信などに使用 |
| `m` | `*discordgo.MessageCreate` | 受信メッセージ。`m.ChannelID` などで送信元チャンネルを参照できる |
| `content` | `string` | プレフィックスと区切り文字を除いた本文（トリム済み） |

`b.config` 経由で設定値（`TargetChannelID` など）にもアクセスできます。

---

## ステップ 2: コマンドを登録する

`bot/bot.go` の `New()` 内にある `b.Register(...)` の呼び出しを1行追加します。

```go
func New(cfg *config.Config) (*Bot, error) {
    // ...
    b := &Bot{session: s, config: cfg}
    b.Register("!q", "匿名で質問を投稿", b.handleQuestion)
    b.Register("!f", "フィードバックを送信", b.handleFeedback) // ← 追加
    // ...
}
```

### Register の引数

```go
b.Register(prefix, description string, handler CommandHandler)
```

| 引数 | 説明 | 例 |
|---|---|---|
| `prefix` | コマンドのプレフィックス | `"!f"` |
| `description` | ヘルプに表示する説明 | `"フィードバックを送信"` |
| `handler` | ハンドラーメソッド | `b.handleFeedback` |

---

## ディスパッチの仕組み

メッセージを受信すると `handler.go` の `messageCreate` が登録済みコマンドを順に検索します。
プレフィックスの後に半角スペース・全角スペース・タブのいずれかが続く場合にマッチします。

- マッチしたコマンドのハンドラーが呼ばれる
- いずれもマッチしない場合、登録済みコマンドの一覧をヘルプとして返す

---

## ファイル構成の例

```
bot/
├── bot.go           # Bot 構造体、Register、New
├── handler.go       # messageCreate（ディスパッチャー）
├── cmd_question.go  # !q コマンド
└── cmd_feedback.go  # !f コマンド（追加例）
```
