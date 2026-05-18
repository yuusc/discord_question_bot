#!/bin/bash
set -e

# ─────────────────────────────────────────────
# 色・ユーティリティ
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET}   $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; exit 1; }
step()    { echo -e "\n${BOLD}━━━ $1 ━━━${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────
# ステップ 1: Go のインストール確認
# ─────────────────────────────────────────────
step "ステップ 1/5: Go のインストール確認"

if command -v go &>/dev/null; then
    GO_VER=$(go version | awk '{print $3}')
    success "Go はすでにインストールされています ($GO_VER)"
else
    info "Go が見つかりません。インストールします..."
    sudo apt-get update -qq
    sudo apt-get install -y golang
    success "Go をインストールしました ($(go version | awk '{print $3}'))"
fi

# ─────────────────────────────────────────────
# ステップ 2: 依存ライブラリの取得 & ビルド
# ─────────────────────────────────────────────
step "ステップ 2/5: 依存ライブラリの取得 & ビルド"

cd "$SCRIPT_DIR"

info "依存ライブラリを取得しています..."
go mod tidy
success "依存ライブラリの取得完了"

info "ビルドしています..."
go build -o discord-anon-bot .
success "ビルド完了 → discord-anon-bot"

# ─────────────────────────────────────────────
# ステップ 3: .env の作成（BOT_TOKEN / TARGET_CHANNEL_ID）
# ─────────────────────────────────────────────
step "ステップ 3/5: 設定ファイルの作成"

# すでに .env があれば上書き確認
if [ -f "$SCRIPT_DIR/.env" ]; then
    warn ".env ファイルがすでに存在します。"
    read -rp "上書きしますか？ (y/N): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        info ".env の上書きをスキップしました。"
        SKIP_ENV=true
    fi
fi

if [ "${SKIP_ENV}" != "true" ]; then
    echo ""
    echo -e "${BOLD}【1. ボットを作成してトークンをコピーする】${RESET}"
    echo "  1. https://discord.com/developers/applications を開く（Discordアカウントでログイン）"
    echo "  2. 右上の「新しいアプリケーション」→ 名前を入力 →「作成」"
    echo "  3. 左メニューの「Bot」→ユーザ名にボット名を入力"
    echo "  4. 「トークンをリセット」をクリックしてトークンをコピーし、メモ帳などに保存"
    echo "  ⚠️  重要: トークンは絶対に他人に見せないでください"
    echo "  5. 同じページを下にスクロールして「Privileged Gateway Intents」を探す"
    echo "  6. 「Message Content Intent」を ON にして「変更を保存」をクリック"
    echo "  ℹ️  これをONにしないと、ボットがDMのメッセージ内容を読めません"
    echo ""
    while true; do
        read -rp "ボットトークンを貼り付けてください: " BOT_TOKEN
        if [ -n "$BOT_TOKEN" ]; then
            break
        fi
        warn "トークンが空です。もう一度入力してください。"
    done

    echo ""
    echo -e "${BOLD}【2. ボットをサーバーに招待する】${RESET}"
    echo "  1. 左メニューの「OAuth2」→「OAuth2 URLジェネレーター」"
    echo "  2. 「スコープ」で「bot」にチェック"
    echo "  3. 「BOT PERMISSIONS」で以下にチェック:"
    echo "       - チャンネルを表示"
    echo "       - メッセージを送る"
    echo "  4. ページ下部の「生成されたURL」をコピーしてブラウザで開く"
    echo "  5. 招待するサーバーを選択して「認証」"
    echo ""
    read -rp "ボットをサーバーに招待できたら Enter を押してください..."

    echo ""
    echo -e "${BOLD}【3. チャンネルIDを取得する】${RESET}"
    echo "  1. Discordの設定（左下の歯車アイコン）→「<>開発者」→「開発者モード」を ON"
    echo "  2. 質問を投稿させたいチャンネルを右クリック →「チャンネルIDをコピー」"
    echo "  ⚠️  サーバー名ではなく、チャンネルを右クリックしてください（IDの数字が違います）"
    echo ""
    while true; do
        read -rp "チャンネルIDを貼り付けてください: " TARGET_CHANNEL_ID
        if [[ "$TARGET_CHANNEL_ID" =~ ^[0-9]+$ ]]; then
            break
        fi
        warn "チャンネルIDは数字のみです。もう一度入力してください。"
    done

    cat > "$SCRIPT_DIR/.env" <<EOF
BOT_TOKEN=${BOT_TOKEN}
TARGET_CHANNEL_ID=${TARGET_CHANNEL_ID}
EOF
    success ".env ファイルを作成しました"
fi

# ─────────────────────────────────────────────
# ステップ 4: systemd サービスの登録
# ─────────────────────────────────────────────
step "ステップ 4/5: 自動起動の設定（systemd）"

CURRENT_USER="$(whoami)"
SERVICE_NAME="discord-anon-bot"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# systemd が使えるか確認
if ! pidof systemd &>/dev/null && ! systemctl status &>/dev/null 2>&1; then
    warn "systemd が有効になっていません。"
    echo ""
    echo "  WSL2 で systemd を有効にするには:"
    echo "    sudo nano /etc/wsl.conf"
    echo "  以下を追加して保存してください:"
    echo "    [boot]"
    echo "    systemd=true"
    echo "  その後、PowerShell で「wsl --shutdown」を実行して再起動してください。"
    echo ""
    warn "自動起動の設定をスキップしました。手動起動は: ./discord-anon-bot"
else
    info "systemd サービスを登録しています..."

    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Anonymous Question Discord Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${CURRENT_USER}
WorkingDirectory=${SCRIPT_DIR}
ExecStart=${SCRIPT_DIR}/discord-anon-bot
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl restart "$SERVICE_NAME"

    success "systemd サービスを登録・起動しました"
fi

# ─────────────────────────────────────────────
# ステップ 5: 動作確認
# ─────────────────────────────────────────────
step "ステップ 5/5: 動作確認"

if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    success "ボットは正常に起動しています"
    echo ""
    echo -e "  ログを確認するには: ${CYAN}journalctl -u ${SERVICE_NAME} -f${RESET}"
    echo -e "  停止するには:       ${CYAN}sudo systemctl stop ${SERVICE_NAME}${RESET}"
    echo -e "  再起動するには:     ${CYAN}sudo systemctl restart ${SERVICE_NAME}${RESET}"
else
    info "ボットを手動で起動しています..."
    "$SCRIPT_DIR/discord-anon-bot" &
    BOT_PID=$!
    sleep 2
    if kill -0 "$BOT_PID" 2>/dev/null; then
        success "ボットが起動しました (PID: $BOT_PID)"
        echo -e "  停止するには: ${CYAN}kill $BOT_PID${RESET}"
    else
        error "ボットの起動に失敗しました。.env の内容を確認してください。"
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}セットアップ完了！${RESET}"
echo ""
echo "  使い方: DiscordでボットにDMを送ってください"
echo "  例)  !q なぜ空は青いの？"
echo ""
