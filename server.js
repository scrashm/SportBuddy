const express = require('express');
const { Pool } = require('pg');
const TelegramBot = require('node-telegram-bot-api');

const app = express();
const port = process.env.PORT || 3000;

// --- Конфигурация ---
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
});

const token = process.env.TELEGRAM_BOT_TOKEN;
if (!token) {
  console.error('TELEGRAM_BOT_TOKEN не найден! Пожалуйста, добавьте его в переменные окружения.');
  process.exit(1);
}
const bot = new TelegramBot(token, { polling: false });

// Хранилище для кодов (в реальном приложении лучше использовать Redis)
const otpStore = new Map();

// --- Инициализация БД ---
async function initializeDatabase() {
  const client = await pool.connect();
  try {
    await client.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');
    const createUserTableQuery = `
      DROP TABLE IF EXISTS users; -- Удаляем старую таблицу для чистоты
      CREATE TABLE users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        telegram_id BIGINT UNIQUE,
        telegram_username VARCHAR(255) UNIQUE,
        name VARCHAR(255),
        avatar_url TEXT,
        bio TEXT,
        work VARCHAR(255),
        study VARCHAR(255),
        pet VARCHAR(255),
        sports TEXT[],
        location VARCHAR(255),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `;
    await client.query(createUserTableQuery);
    console.log('Таблица "users" пересоздана для работы с Telegram.');
  } catch (err) {
    console.error('Ошибка инициализации базы данных:', err);
  } finally {
    client.release();
  }
}
initializeDatabase().catch(console.error);

app.use(express.json());

// --- Маршруты API ---

// 1. Запрос кода для входа
app.post('/login/telegram/request', async (req, res) => {
  const { telegram_id } = req.body;
  if (!telegram_id) {
    return res.status(400).json({ success: false, error: 'Необходим ID пользователя Telegram' });
  }

  const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6-значный код
  otpStore.set(telegram_id.toString(), { code: otp, expires: Date.now() + 300000 }); // Код живет 5 минут

  try {
    await bot.sendMessage(telegram_id, `Ваш код для входа в Sport Buddy: ${otp}`);
    res.json({ success: true, message: 'Код отправлен.' });
  } catch (error) {
    console.error("Ошибка отправки сообщения от Telegram API:", JSON.stringify(error, null, 2));
    res.status(500).json({ 
      success: false, 
      error: 'Не удалось отправить код. Убедитесь, что пользователь начал диалог с ботом.',
      details: error.response ? error.response.body : 'No response body'
    });
  }
});

// 2. Проверка кода и вход/регистрация
app.post('/login/telegram/verify', async (req, res) => {
  const { telegram_id, code, telegram_username } = req.body;
  if (!telegram_id || !code) {
    return res.status(400).json({ success: false, error: 'Необходимы ID и код' });
  }

  const storedOtp = otpStore.get(telegram_id.toString());
  if (!storedOtp || storedOtp.code !== code || Date.now() > storedOtp.expires) {
    return res.status(401).json({ success: false, error: 'Неверный или просроченный код' });
  }

  otpStore.delete(telegram_id.toString()); // Удаляем код после использования

  const client = await pool.connect();
  try {
    // Ищем пользователя по telegram_id
    let result = await client.query('SELECT * FROM users WHERE telegram_id = $1', [telegram_id]);
    
    if (result.rows.length > 0) {
      // Пользователь найден, возвращаем его данные
      res.json({ success: true, user: result.rows[0] });
    } else {
      // Пользователь не найден, создаем нового
      const newUserResult = await client.query(
        'INSERT INTO users (telegram_id, telegram_username, name) VALUES ($1, $2, $3) RETURNING *',
        [telegram_id, telegram_username, telegram_username] // По умолчанию имя = ник
      );
      res.status(201).json({ success: true, user: newUserResult.rows[0] });
    }
  } catch (err) {
    console.error('Ошибка базы данных при входе/регистрации:', err);
    res.status(500).json({ success: false, error: 'Внутренняя ошибка сервера' });
  } finally {
    client.release();
  }
});

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
  console.log(`Сервер запущен на порту ${port} и готов к Telegram-аутентификации.`);
}); 