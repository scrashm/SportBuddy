const express = require('express');
const { Pool } = require('pg');
const TelegramBot = require('node-telegram-bot-api');
const crypto = require('crypto');

const app = express();
const port = process.env.PORT || 3000;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const token = process.env.TELEGRAM_BOT_TOKEN;
if (!token) {
  console.error('TELEGRAM_BOT_TOKEN не найден!');
  process.exit(1);
}
const bot = new TelegramBot(token, { polling: true });

app.use(express.json());

// --- Хранилище токенов (в реальном проекте лучше Redis или БД) ---
const loginTokens = new Map(); // token: { status, telegram_id, telegram_username, createdAt }

// --- Генерация токена и выдача ссылки ---
app.post('/auth/telegram/start', async (req, res) => {
  // Можно добавить user_agent/ip для защиты от спама
  const loginToken = crypto.randomBytes(16).toString('hex');
  loginTokens.set(loginToken, { status: 'pending', createdAt: Date.now() });
  const url = `https://t.me/SportBuddyAuthBot?start=token_${loginToken}`;
  res.json({ url, token: loginToken });
});

// --- Проверка статуса токена ---
app.get('/auth/telegram/status/:token', (req, res) => {
  const { token } = req.params;
  const entry = loginTokens.get(token);
  if (!entry) return res.json({ status: 'not_found' });
  if (entry.status === 'confirmed') {
    res.json({ status: 'confirmed', telegram_id: entry.telegram_id, telegram_username: entry.telegram_username });
  } else {
    res.json({ status: entry.status });
  }
});

// --- Интеграция с Telegram Bot ---
bot.onText(/\/start (token_[a-f0-9]+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const username = msg.from.username;
  const token = match[1].replace('token_', '');
  const entry = loginTokens.get(token);
  if (!entry) {
    bot.sendMessage(chatId, 'Ссылка устарела или неверна. Попробуйте войти снова из приложения.');
    return;
  }
  if (entry.status === 'confirmed') {
    bot.sendMessage(chatId, 'Этот токен уже подтвержден.');
    return;
  }
  // Сохраняем Telegram ID и username, но не подтверждаем до нажатия кнопки
  entry.telegram_id = chatId;
  entry.telegram_username = username;
  entry.status = 'waiting_confirm';
  loginTokens.set(token, entry);
  bot.sendMessage(chatId, 'Подтвердите вход в приложение Sport Buddy:', {
    reply_markup: {
      inline_keyboard: [[{ text: 'Подтвердить вход', callback_data: `confirm_${token}` }]]
    }
  });
});

bot.on('callback_query', async (query) => {
  const chatId = query.message.chat.id;
  const data = query.data;
  if (data.startsWith('confirm_')) {
    const token = data.replace('confirm_', '');
    const entry = loginTokens.get(token);
    if (!entry) {
      bot.sendMessage(chatId, 'Токен не найден или устарел.');
      return;
    }
    entry.status = 'confirmed';
    loginTokens.set(token, entry);
    bot.sendMessage(chatId, 'Вход подтвержден! Теперь вы можете вернуться в приложение.');
  }
});

// --- Тестовый маршрут ---
app.get('/test-db', async (req, res) => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    res.json({ success: true, time: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.listen(port, () => {
  console.log(`Сервер запущен на порту ${port} и готов к Telegram deep linking.`);
}); 