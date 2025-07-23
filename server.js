require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const TelegramBot = require('node-telegram-bot-api');
const crypto = require('crypto');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const AWS = require('aws-sdk');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors({
  origin: true,
  credentials: true,
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
}));
console.log('CORS enabled');
app.use(express.json());

// --- Подключение к базе данных PostgreSQL ---
if (!process.env.DATABASE_URL || process.env.DATABASE_URL === 'postgresql://username:password@localhost:5432/sportbuddy_db') {
  console.warn('DATABASE_URL не установлен или использует значение по умолчанию.');
  if (process.env.NODE_ENV === 'production') {
    console.error('В продакшене DATABASE_URL обязателен!');
    process.exit(1);
  }
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

// --- Инициализация Telegram-бота в режиме long polling ---
const token = process.env.TELEGRAM_BOT_TOKEN;
let bot = null;

if (!token || token === 'your_telegram_bot_token_here') {
  console.warn('TELEGRAM_BOT_TOKEN не установлен или использует значение по умолчанию. Telegram бот отключен.');
  if (process.env.NODE_ENV === 'production') {
    console.error('В продакшене TELEGRAM_BOT_TOKEN обязателен!');
    process.exit(1);
  }
} else {
  try {
    bot = new TelegramBot(token, { polling: true });
    console.log('Telegram бот инициализирован и запущен.');
  } catch (error) {
    console.error('Ошибка инициализации Telegram бота:', error.message);
    if (process.env.NODE_ENV === 'production') {
      process.exit(1);
    }
  }
}

// --- Инициализация таблицы токенов ---
async function initializeLoginTokensTable() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS login_tokens (
        token TEXT PRIMARY KEY,
        status VARCHAR(50) NOT NULL,
        telegram_id BIGINT,
        telegram_username VARCHAR(255),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    console.log('Таблица login_tokens готова.');
  } finally {
    client.release();
  }
}
initializeLoginTokensTable();

// --- Генерация токена и выдача ссылки ---
app.post('/auth/telegram/start', async (req, res) => {
  const loginToken = crypto.randomBytes(16).toString('hex');
  console.log(`[TOKEN] Создан новый токен: ${loginToken}`);
  const client = await pool.connect();
  try {
    await client.query('INSERT INTO login_tokens (token, status) VALUES ($1, $2)', [loginToken, 'pending']);
  } finally {
    client.release();
  }
  const url = `https://t.me/SportBuddyAuthBot?start=token_${loginToken}`;
  res.json({ url, token: loginToken });
});

// --- Проверка статуса токена ---
app.get('/auth/telegram/status/:token', async (req, res) => {
  const { token } = req.params;
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT * FROM login_tokens WHERE token = $1', [token]);
    if (result.rows.length === 0) {
      return res.json({ status: 'not_found' });
    }
    const entry = result.rows[0];
    if (entry.status === 'confirmed') {
      res.json({ status: 'confirmed', telegram_id: entry.telegram_id, telegram_username: entry.telegram_username });
    } else {
      res.json({ status: entry.status });
    }
  } finally {
    client.release();
  }
});

// --- Интеграция с Telegram Bot ---
if (bot) {
  bot.onText(/\/start (token_[a-f0-9]+)/, async (msg, match) => {
    const chatId = msg.chat.id;
    const username = msg.from.username;
    const token = match[1].replace('token_', '');

    const client = await pool.connect();
    try {
      const result = await client.query('SELECT * FROM login_tokens WHERE token = $1', [token]);
      if (result.rows.length === 0) {
        bot.sendMessage(chatId, 'Ссылка устарела или неверна. Попробуйте войти снова из приложения.');
        return;
      }
      const entry = result.rows[0];
      if (entry.status === 'confirmed') {
        bot.sendMessage(chatId, 'Этот токен уже подтвержден.');
        return;
      }
      
      await client.query(
        'UPDATE login_tokens SET telegram_id = $1, telegram_username = $2, status = $3 WHERE token = $4',
        [chatId, username, 'waiting_confirm', token]
      );

      bot.sendMessage(chatId, 'Подтвердите вход в приложение Sport Buddy:', {
        reply_markup: {
          inline_keyboard: [[{ text: 'Подтвердить вход', callback_data: `confirm_${token}` }]]
        }
      });
    } finally {
      client.release();
    }
  });
}

if (bot) {
  bot.on('callback_query', async (query) => {
    const chatId = query.message.chat.id;
    const data = query.data;
    if (data.startsWith('confirm_')) {
      const token = data.replace('confirm_', '');
      const client = await pool.connect();
      try {
        const result = await client.query('SELECT * FROM login_tokens WHERE token = $1', [token]);
        if (result.rows.length === 0) {
          bot.sendMessage(chatId, 'Токен не найден или устарел.');
          return;
        }
        const entry = result.rows[0];
        console.log(`[USER CREATE] entry из login_tokens:`, entry);
        await client.query('UPDATE login_tokens SET status = $1 WHERE token = $2', ['confirmed', token]);
        bot.sendMessage(chatId, 'Вход подтвержден! Теперь вы можете вернуться в приложение.');
        const userResult = await client.query('SELECT * FROM users WHERE telegram_id = $1', [chatId]);
        if (userResult.rows.length === 0) {
          try {
            await client.query(
              'INSERT INTO users (telegram_id, telegram_username, name) VALUES ($1, $2, $3)',
              [chatId, entry.telegram_username, entry.telegram_username]
            );
            console.log(`[USER CREATE] Пользователь успешно создан: telegram_id=${chatId}, username=${entry.telegram_username}`);
          } catch (err) {
            console.error(`[USER CREATE ERROR]`, err);
          }
        } else {
          console.log(`[USER CREATE] Пользователь уже существует: telegram_id=${chatId}`);
        }
      } finally {
        client.release();
      }
    }
  });
}

// --- Инициализация таблицы пользователей ---
async function initializeUsersTable() {
  const client = await pool.connect();
  try {
    await client.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        telegram_id BIGINT UNIQUE NOT NULL,
        telegram_username VARCHAR(255),
        name VARCHAR(255),
        avatar_url TEXT,
        bio TEXT,
        sports TEXT[],
        interests TEXT[],
        pet TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    console.log('Таблица users готова.');
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
  const { name, avatar_url, bio, sports, interests, pet } = req.body;
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT * FROM users WHERE telegram_id = $1', [telegram_id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    await client.query(
      `UPDATE users SET name = $1, avatar_url = $2, bio = $3, sports = $4, interests = $5, pet = $6, updated_at = NOW() WHERE telegram_id = $7`,
      [name, avatar_url, bio, sports, interests, pet, telegram_id]
    );
    const updated = await client.query('SELECT * FROM users WHERE telegram_id = $1', [telegram_id]);
    res.json(updated.rows[0]);
  } finally {
    client.release();
  }
});

// --- Конфигурируем S3 ---
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION,
});
const S3_BUCKET = process.env.AWS_S3_BUCKET;

// --- Новый эндпоинт для загрузки аватара в S3 ---
app.post('/user/:telegram_id/avatar', multer({ dest: 'uploads/' }).single('avatar'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'Файл не загружен.' });
  }
  const fileContent = fs.readFileSync(req.file.path);
  const fileName = `${req.params.telegram_id}-${Date.now()}${path.extname(req.file.originalname)}`;
  const params = {
    Bucket: S3_BUCKET,
    Key: fileName,
    Body: fileContent,
    ContentType: req.file.mimetype,
    ACL: 'public-read',
  };
  try {
    const data = await s3.upload(params).promise();
    res.json({ avatarUrl: data.Location });
  } catch (err) {
    res.status(500).json({ error: 'Ошибка загрузки в S3', details: err.message });
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