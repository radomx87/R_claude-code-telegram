# Claude Code Telegram Bot

Telegram-бот для удалённого доступа к Claude Code с телефона.
Работает на базе **Claude Pro/Max подписки** — без дополнительных расходов на API.

```
Телефон (Telegram) → Бот → Claude Code CLI → Ваш сервер
```

---

## Что умеет бот

- Выполнять bash-команды на сервере
- Читать, создавать, редактировать файлы
- Искать в интернете
- Работать с git-репозиториями
- Принимать и анализировать файлы и изображения
- Помнить историю диалога в рамках сессии

---

## Требования

Перед установкой убедитесь, что у вас есть:

- [ ] Linux/macOS сервер или VPS
- [ ] Python 3.11 или новее
- [ ] Node.js (для установки Claude CLI)
- [ ] Подписка Claude Pro или Max на [claude.ai](https://claude.ai)

---

## Пошаговая установка

### Шаг 1 — Установите Claude CLI

Claude CLI — это основной инструмент, через который бот общается с Claude.

```bash
npm install -g @anthropic-ai/claude-code
```

После установки войдите в аккаунт:

```bash
claude auth login
```

Откроется браузер — войдите через ваш аккаунт claude.ai. После этого проверьте:

```bash
claude --version
# Должно показать версию, например: 2.x.x (Claude Code)
```

---

### Шаг 2 — Создайте Telegram-бота

1. Откройте Telegram, найдите `@BotFather`
2. Напишите `/newbot`
3. Придумайте **имя** бота (например: `Мой Ассистент`)
4. Придумайте **username** — должен заканчиваться на `bot` (например: `my_assistant_bot`)
5. BotFather пришлёт токен вида: `1234567890:AAF...`

> Сохраните токен — он понадобится на следующем шаге.

---

### Шаг 3 — Узнайте свой Telegram ID

1. Найдите в Telegram бота `@userinfobot`
2. Напишите ему любое сообщение
3. Он пришлёт ваш числовой ID, например: `123456789`

> Это нужно для того, чтобы только вы могли управлять ботом.

---

### Шаг 4 — Установите бот

```bash
pip install git+https://github.com/YOUR_GITHUB_USERNAME/claude-code-telegram.git --break-system-packages
```

Если `pip` не найден, попробуйте:

```bash
python3 -m pip install git+https://github.com/YOUR_GITHUB_USERNAME/claude-code-telegram.git --break-system-packages
```

---

### Шаг 5 — Создайте файл настроек

Создайте папку для бота и перейдите в неё:

```bash
mkdir ~/claude-tg-bot && cd ~/claude-tg-bot
```

Создайте файл `.env` (замените значения на свои):

```bash
cat > .env << 'EOF'
# Telegram
TELEGRAM_BOT_TOKEN=сюда_вставьте_токен_от_BotFather
TELEGRAM_BOT_USERNAME=имя_бота_без_символа_@
ALLOWED_USERS=сюда_вставьте_ваш_Telegram_ID

# Рабочая директория (к чему бот будет иметь доступ)
APPROVED_DIRECTORY=/home/ваш_пользователь

# Путь к Claude CLI (узнать: which claude)
CLAUDE_CLI_PATH=/usr/local/bin/claude

# Лимиты
CLAUDE_MAX_TURNS=50
CLAUDE_TIMEOUT_SECONDS=600

# Для личного сервера — снять ограничения bash
DISABLE_SECURITY_PATTERNS=true
DISABLE_TOOL_VALIDATION=true

# Rate limit
RATE_LIMIT_REQUESTS=60
RATE_LIMIT_WINDOW=60
EOF
```

Защитите файл (в нём токены):

```bash
chmod 600 .env
```

---

### Шаг 6 — Запустите бот

**Вариант А: запуск вручную** (для теста)

```bash
claude-telegram-bot --config-file ~/claude-tg-bot/.env
```

Откройте Telegram, напишите своему боту `/start` — если ответил, всё работает.
Остановить: `Ctrl+C`

---

**Вариант Б: автозапуск через systemd** (для постоянной работы)

Скачайте шаблон сервиса:

```bash
cp ~/claude-tg-bot/../claude-tg-bot.service /tmp/claude-tg-bot.service
```

Откройте файл и замените `YOUR_USERNAME` на ваш логин пользователя:

```bash
nano /tmp/claude-tg-bot.service
```

Установите сервис:

```bash
sudo cp /tmp/claude-tg-bot.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now claude-tg-bot
```

Проверить статус:

```bash
sudo systemctl status claude-tg-bot
```

Смотреть логи в реальном времени:

```bash
journalctl -u claude-tg-bot -f
```

---

## Команды бота

| Команда | Что делает |
|---------|-----------|
| `/start` | Начать работу, показать справку |
| `/new` | Начать новую сессию (сбросить контекст) |
| `/status` | Показать статус текущей сессии |
| `/verbose 0` | Тихий режим — только финальный ответ |
| `/verbose 1` | Обычный режим — видны инструменты (по умолчанию) |
| `/verbose 2` | Подробный режим — видны все действия |
| `/repo` | Сменить рабочую директорию |

---

## Частые вопросы

**Бот не отвечает**
→ Проверьте, что `ALLOWED_USERS` содержит ваш правильный Telegram ID (из `@userinfobot`)

**Ошибка "Conflict: terminated by other getUpdates"**
→ Запущено несколько копий бота. Остановите все и запустите одну:
```bash
pkill -f claude-telegram-bot
sudo systemctl restart claude-tg-bot
```

**Claude не выполняет команды с `|` или `>`**
→ Убедитесь, что в `.env` установлено `DISABLE_SECURITY_PATTERNS=true`

**Сессия обрывается на середине**
→ Увеличьте `CLAUDE_MAX_TURNS` и `CLAUDE_TIMEOUT_SECONDS` в `.env`

**Нет доступа к файлам**
→ Проверьте путь в `APPROVED_DIRECTORY` — он должен существовать и быть абсолютным

---

## Безопасность

- Доступ только с вашего Telegram ID — чужие сообщения игнорируются
- Файловый доступ ограничен папкой `APPROVED_DIRECTORY`
- Все команды пишутся в audit-лог
- Файл `.env` должен иметь права `600` — только вы читаете

> ⚠️ `DISABLE_SECURITY_PATTERNS=true` и `DISABLE_TOOL_VALIDATION=true` рекомендуется только на личном сервере с одним пользователем.

---

## Основан на

[RichardAtCT/claude-code-telegram](https://github.com/RichardAtCT/claude-code-telegram)

Изменения в этом форке:
- `anthropic` SDK обновлён с `^0.40` до `^0.84`
- Лучшие дефолты: `MAX_TURNS=50`, `TIMEOUT=600s`, `RATE_LIMIT=60/min`
- Скрипт быстрой установки `install.sh`
- Шаблон systemd сервиса `claude-tg-bot.service`
- Подробная документация на русском (этот файл)

---

## Лицензия

MIT
