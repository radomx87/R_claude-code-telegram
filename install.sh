#!/usr/bin/env bash
# Claude Code Telegram Bot — quick install script
# Usage: bash install.sh

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}Claude Code Telegram Bot — Installer${NC}"
echo "======================================"

# 1. Check Python
if ! python3 --version &>/dev/null; then
    echo -e "${RED}Error: python3 not found. Install Python 3.11+${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo -e "${GREEN}✓ Python $PYTHON_VERSION found${NC}"

# 2. Check Claude CLI
if ! command -v claude &>/dev/null; then
    echo -e "${YELLOW}Claude CLI not found. Installing...${NC}"
    npm install -g @anthropic-ai/claude-code 2>/dev/null || \
        { echo -e "${RED}Failed to install Claude CLI. Install Node.js first.${NC}"; exit 1; }
fi
echo -e "${GREEN}✓ Claude CLI found: $(which claude)${NC}"

# 3. Install bot
echo ""
echo -e "${BOLD}Installing claude-code-telegram...${NC}"
REPO_URL="https://github.com/$(git ls-remote --get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||' || echo 'YOUR_USERNAME/claude-code-telegram')"
pip install "git+${REPO_URL}.git" --break-system-packages 2>/dev/null || \
pip install "git+${REPO_URL}.git"

echo -e "${GREEN}✓ Bot installed${NC}"

# 4. Setup directory
BOT_DIR="$HOME/claude-tg-bot"
mkdir -p "$BOT_DIR"
cd "$BOT_DIR"

# 5. Create .env if not exists
if [ ! -f ".env" ]; then
    echo ""
    echo -e "${BOLD}Configuration setup${NC}"
    echo "-------------------"

    read -p "Telegram Bot Token (from @BotFather): " BOT_TOKEN
    read -p "Bot username (without @): " BOT_USERNAME
    read -p "Your Telegram User ID (from @userinfobot): " USER_ID
    read -p "Working directory [default: $HOME]: " WORK_DIR
    WORK_DIR="${WORK_DIR:-$HOME}"

    CLAUDE_PATH=$(which claude 2>/dev/null || echo "")

    cat > .env << EOF
TELEGRAM_BOT_TOKEN=$BOT_TOKEN
TELEGRAM_BOT_USERNAME=$BOT_USERNAME
APPROVED_DIRECTORY=$WORK_DIR
ALLOWED_USERS=$USER_ID

# Claude settings
CLAUDE_CLI_PATH=$CLAUDE_PATH
CLAUDE_MAX_TURNS=50
CLAUDE_TIMEOUT_SECONDS=600

# Security (set to true for personal single-user setup)
DISABLE_SECURITY_PATTERNS=true
DISABLE_TOOL_VALIDATION=true

# Rate limiting (60 req/min for personal use)
RATE_LIMIT_REQUESTS=60
RATE_LIMIT_WINDOW=60
RATE_LIMIT_BURST=20
EOF
    chmod 600 .env
    echo -e "${GREEN}✓ .env created${NC}"
else
    echo -e "${YELLOW}⚠ .env already exists, skipping${NC}"
fi

# 6. systemd service
echo ""
echo -e "${BOLD}Setting up systemd service...${NC}"

SERVICE_FILE="/etc/systemd/system/claude-tg-bot.service"
BOT_BIN=$(which claude-telegram-bot 2>/dev/null || echo "$HOME/.local/bin/claude-telegram-bot")

cat > /tmp/claude-tg-bot.service << EOF
[Unit]
Description=Claude Code Telegram Bot
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$BOT_DIR
EnvironmentFile=$BOT_DIR/.env
ExecStart=$BOT_BIN --config-file $BOT_DIR/.env
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

if sudo cp /tmp/claude-tg-bot.service "$SERVICE_FILE" 2>/dev/null; then
    sudo systemctl daemon-reload
    sudo systemctl enable --now claude-tg-bot
    echo -e "${GREEN}✓ systemd service enabled and started${NC}"
else
    echo -e "${YELLOW}⚠ No sudo access. Starting with nohup instead...${NC}"
    nohup "$BOT_BIN" --config-file "$BOT_DIR/.env" > "$BOT_DIR/bot.log" 2>&1 &
    echo -e "${GREEN}✓ Bot started (PID: $!)${NC}"
    echo -e "${YELLOW}  Note: bot will stop on server reboot. Add to crontab manually:${NC}"
    echo "  @reboot $BOT_BIN --config-file $BOT_DIR/.env >> $BOT_DIR/bot.log 2>&1 &"
fi

echo ""
echo -e "${GREEN}${BOLD}Done! Open Telegram and message your bot.${NC}"
echo "Logs: journalctl -u claude-tg-bot -f  (or: tail -f $BOT_DIR/bot.log)"
