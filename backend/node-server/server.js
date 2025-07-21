const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const app = express();
const PORT = process.env.PORT || 3000;

// Попытка передеплоя с новыми настройками
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});

app.use(cors());
app.use(express.json());

// Временное хранилище событий (в памяти) - ПОКА ОСТАВИМ ДЛЯ ПРИМЕРА
const events = [];

// POST /log-event — логирование события
app.post('/log-event', (req, res) => {
  const event = req.body;
  events.push(event);
  console.log('Новое событие:', event);
  res.json({ status: 'ok', event });
});

// GET /events — получить все события
app.get('/events', (req, res) => {
  res.json(events);
});

// Новый тестовый маршрут для проверки подключения к БД
app.get('/test-db', async (req, res) => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    res.json({ success: true, time: result.rows[0] });
    client.release();
  } catch (err) {
    console.error('Ошибка подключения к базе данных', err);
    res.status(500).json({ success: false, error: 'Не удалось подключиться к базе данных' });
  }
});

// Корневой маршрут
app.get('/', (req, res) => {
  res.send('SportBuddy backend работает!');
});

app.listen(PORT, () => {
  console.log(`Сервер запущен на порту ${PORT}`);
}); 