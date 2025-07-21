const express = require('express');
const { Pool } = require('pg');
const TelegramBot = require('node-telegram-bot-api');
const crypto = require('crypto');

const app = express();
const port = process.env.PORT || 3000;

// --- Подключение к базе данных PostgreSQL ---
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// --- Инициализация Telegram-бота в режиме long polling ---
const token = process.env.TELEGRAM_BOT_TOKEN;
if (!token) {
  console.error('TELEGRAM_BOT_TOKEN не найден!');
  process.exit(1);
}
const bot = new TelegramBot(token, { polling: true });

app.use(express.json());

// --- Хранилище токенов для входа через Telegram (лучше использовать Redis или БД в проде) ---
// loginTokens: token -> { status, telegram_id, telegram_username, createdAt }
const loginTokens = new Map();

/**
 * Эндпоинт для генерации токена и выдачи deep link для входа через Telegram
 * POST /auth/telegram/start
 * Ответ: { url, token }
 */
app.post('/auth/telegram/start', async (req, res) => {
  const loginToken = crypto.randomBytes(16).toString('hex');
  console.log(`[TOKEN] Создан новый токен: ${loginToken}`);
  loginTokens.set(loginToken, { status: 'pending', createdAt: Date.now() });
  const url = `https://t.me/SportBuddyAuthBot?start=token_${loginToken}`;
  res.json({ url, token: loginToken });
});

/**
 * Эндпоинт для проверки статуса токена (используется фронтом для polling)
 * GET /auth/telegram/status/:token
 * Ответ: { status, telegram_id?, telegram_username? }
 */
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

/**
 * Обработка команды /start с deep link (бот получает /start token_xxx)
 * Сохраняет Telegram ID и username, отправляет пользователю кнопку подтверждения
 */
bot.onText(/\/start (token_[a-f0-9]+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const username = msg.from.username;
  const token = match[1].replace('token_', '');

  console.log(`[TOKEN] Бот получил /start с токеном: ${token}`);
  console.log(`[TOKEN] Текущие токены в хранилище:`, Array.from(loginTokens.keys()));

  const entry = loginTokens.get(token);
  if (!entry) {
    console.log(`[TOKEN] Ошибка: токен ${token} не найден в хранилище.`);
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

/**
 * Обработка нажатия кнопки "Подтвердить вход" в Telegram-боте
 * Помечает токен как подтвержденный, сообщает пользователю об успешном входе
 */
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
    // --- Создание пользователя в БД, если его нет ---
    const client = await pool.connect();
    try {
      const res = await client.query('SELECT * FROM users WHERE telegram_id = $1', [chatId]);
      if (res.rows.length === 0) {
        console.log(`[CREATE USER] Новый пользователь: telegram_id=${chatId}, username=${entry.telegram_username}`);
        await client.query(
          'INSERT INTO users (telegram_id, telegram_username, name) VALUES ($1, $2, $3)',
          [chatId, entry.telegram_username, entry.telegram_username]
        );
        console.log(`[CREATE USER] Пользователь успешно создан.`);
      } else {
        console.log(`[CREATE USER] Пользователь уже существует: telegram_id=${chatId}`);
      }
    } catch (err) {
      console.error(`[CREATE USER ERROR]`, err);
    } finally {
      client.release();
    }
  }
});

// --- Инициализация таблицы пользователей ---
async function initializeUsersTable() {
  const client = await pool.connect();
  try {
    await client.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');
    await client.query('DROP TABLE IF EXISTS users');
    await client.query(`
      CREATE TABLE users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        telegram_id BIGINT UNIQUE NOT NULL,
        telegram_username VARCHAR(255),
        name VARCHAR(255),
        avatar_url TEXT,
        bio TEXT,
        sports TEXT[],
        interests TEXT[],
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    console.log('Таблица users пересоздана.');
  } finally {
    client.release();
  }
}
initializeUsersTable();

// --- Получить профиль пользователя ---
app.get('/user/:telegram_id', async (req, res) => {
  const { telegram_id } = req.params;
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT * FROM users WHERE telegram_id = $1', [telegram_id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    res.json(result.rows[0]);
  } finally {
    client.release();
  }
});

// --- Создать/обновить профиль пользователя ---
app.post('/user/:telegram_id', async (req, res) => {
  const { telegram_id } = req.params;
  const { name, avatar_url, bio, sports, interests } = req.body;
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT * FROM users WHERE telegram_id = $1', [telegram_id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    await client.query(
      `UPDATE users SET name = $1, avatar_url = $2, bio = $3, sports = $4, interests = $5, updated_at = NOW() WHERE telegram_id = $6`,
      [name, avatar_url, bio, sports, interests, telegram_id]
    );
    const updated = await client.query('SELECT * FROM users WHERE telegram_id = $1', [telegram_id]);
    res.json(updated.rows[0]);
  } finally {
    client.release();
  }
});

// --- Тестовый маршрут для проверки БД ---
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

// --- Запуск сервера ---
app.listen(port, () => {
  console.log(`Сервер запущен на порту ${port} и готов к Telegram deep linking.`);
}); 