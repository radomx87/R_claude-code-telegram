# Claude Code Telegram Bot

Telegram-бот для удалённого доступа к Claude Code через смартфон. Работает на базе вашей **Claude Pro/Max подписки** — без дополнительных расходов на API.

## Как это работает

```
Telegram → Python бот → Claude Code CLI → ваш сервер
```

Бот не обращается к Anthropic API напрямую. Он запускает `claude` CLI, который уже аутентифицирован через вашу подписку.

## Быстрая установка

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/radomx87/claude-code-telegram/main/install.sh)
```

Скрипт сам спросит токен бота, ваш Telegram ID и рабочую директорию.

## Ручная установка

### 1. Создайте бота

Напишите `@BotFather` в Telegram → `/newbot` → получите токен.

### 2. Узнайте ваш Telegram ID

Напишите `@userinfobot` → скопируйте числовой ID.

### 3. Установите бот

```bash
pip install git+https://github.com/radomx87/claude-code-telegram.git --break-system-packages
```

### 4. Настройте `.env`

```bash
mkdir ~/claude-tg-bot && cd ~/claude-tg-bot
```

Создайте файл `.env`:

```env
TELEGRAM_BOT_TOKEN=ваш_токен
TELEGRAM_BOT_USERNAME=имя_бота_без_собаки
APPROVED_DIRECTORY=/home/ваш_пользователь
ALLOWED_USERS=ваш_telegram_id

# Claude
CLAUDE_CLI_PATH=/usr/local/bin/claude
CLAUDE_MAX_TURNS=50
CLAUDE_TIMEOUT_SECONDS=600

# Для личного использования — снять ограничения bash
DISABLE_SECURITY_PATTERNS=true
DISABLE_TOOL_VALIDATION=true

# Rate limit
RATE_LIMIT_REQUESTS=60
RATE_LIMIT_WINDOW=60
```

```bash
chmod 600 .env
```

### 5. Запустите

```bash
# Разово
claude-telegram-bot --config-file .env

# Как systemd сервис (автозапуск)
sudo cp claude-tg-bot.service /etc/systemd/system/
sudo systemctl enable --now claude-tg-bot
```

## Команды бота

| Команда | Описание |
|---------|----------|
| `/start` | Начать работу |
| `/new` | Новая сессия |
| `/status` | Статус текущей сессии |
| `/verbose 0\|1\|2` | Уровень детализации вывода |
| `/repo` | Сменить рабочую директорию |

## Возможности

- Выполнение bash-команд
- Чтение, создание, редактирование файлов
- Веб-поиск и fetch
- Git-операции
- Загрузка файлов и изображений
- Память сессии (история диалога)
- Только вы как пользователь (whitelist по Telegram ID)

## Требования

- Python 3.11+
- [Claude Code CLI](https://claude.ai/code) (установленный и аутентифицированный)
- Claude Pro или Max подписка
- Linux/macOS сервер или VPS

## Безопасность

- Доступ ограничен списком Telegram ID (`ALLOWED_USERS`)
- Файловый доступ ограничен `APPROVED_DIRECTORY`
- Все команды логируются
- `.env` файл должен иметь права `600`

> `DISABLE_SECURITY_PATTERNS=true` и `DISABLE_TOOL_VALIDATION=true` рекомендуется только для личного сервера с одним пользователем.

## Отличия от оригинала

Этот форк основан на [RichardAtCT/claude-code-telegram](https://github.com/RichardAtCT/claude-code-telegram).

Изменения:
- `anthropic` SDK обновлён с `0.40` до `0.84`
- Лучшие дефолты: `CLAUDE_MAX_TURNS=50`, `TIMEOUT=600s`, `RATE_LIMIT=60/min`
- Скрипт быстрой установки `install.sh`
- Шаблон systemd сервиса
- Этот README на русском

## Лицензия

MIT
