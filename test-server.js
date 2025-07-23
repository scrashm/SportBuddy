const express = require('express');
const cors = require('cors');
const crypto = require('crypto');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors({
  origin: true,
  credentials: true,
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
}));
console.log('CORS enabled');
app.use(express.json());

// In-memory storage for testing (don't use this in production)
const loginTokens = new Map();
const users = new Map();

// --- Health check endpoint for Railway ---
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

// --- Root endpoint ---
app.get('/', (req, res) => {
  res.json({ 
    message: 'SportBuddy Test Backend API', 
    status: 'Running',
    mode: 'test',
    endpoints: {
      health: '/health',
      testDb: '/test-db',
      telegramAuth: '/auth/telegram/start'
    }
  });
});

// --- Test database connection ---
app.get('/test-db', (req, res) => {
  res.json({ success: true, time: new Date().toISOString(), message: 'Test server is running' });
});

// --- Generate token and provide link ---
app.post('/auth/telegram/start', (req, res) => {
  const loginToken = crypto.randomBytes(16).toString('hex');
  console.log(`[TOKEN] Created token: ${loginToken}`);
  
  loginTokens.set(loginToken, {
    status: 'pending',
    telegram_id: null,
    telegram_username: null,
    created_at: new Date()
  });
  
  const url = `https://t.me/SportBuddyAuthBot?start=token_${loginToken}`;
  res.json({ url, token: loginToken });
});

// --- Check token status ---
app.get('/auth/telegram/status/:token', (req, res) => {
  const { token } = req.params;
  const entry = loginTokens.get(token);
  
  if (!entry) {
    return res.json({ status: 'not_found' });
  }
  
  if (entry.status === 'confirmed') {
    res.json({ 
      status: 'confirmed', 
      telegram_id: entry.telegram_id, 
      telegram_username: entry.telegram_username 
    });
  } else {
    res.json({ status: entry.status });
  }
});

// --- Simulate token confirmation (for testing) ---
app.post('/auth/telegram/confirm/:token', (req, res) => {
  const { token } = req.params;
  const { telegram_id, telegram_username } = req.body;
  
  const entry = loginTokens.get(token);
  if (!entry) {
    return res.status(404).json({ error: 'Token not found' });
  }
  
  entry.status = 'confirmed';
  entry.telegram_id = telegram_id || 123456789;
  entry.telegram_username = telegram_username || 'testuser';
  
  // Create a test user
  users.set(entry.telegram_id, {
    id: crypto.randomUUID(),
    telegram_id: entry.telegram_id,
    telegram_username: entry.telegram_username,
    name: entry.telegram_username,
    avatar_url: null,
    bio: null,
    sports: [],
    interests: [],
    pet: null,
    created_at: new Date(),
    updated_at: new Date()
  });
  
  console.log(`[TEST] Token ${token} confirmed for user ${entry.telegram_id}`);
  res.json({ success: true, message: 'Token confirmed' });
});

// --- Get user profile ---
app.get('/user/:telegram_id', (req, res) => {
  const { telegram_id } = req.params;
  const user = users.get(parseInt(telegram_id));
  
  if (!user) {
    return res.status(404).json({ error: 'Пользователь не найден' });
  }
  
  res.json(user);
});

// --- Update user profile ---
app.post('/user/:telegram_id', (req, res) => {
  const { telegram_id } = req.params;
  const { name, avatar_url, bio, sports, interests, pet } = req.body;
  
  const user = users.get(parseInt(telegram_id));
  if (!user) {
    return res.status(404).json({ error: 'Пользователь не найден' });
  }
  
  // Update user data
  user.name = name || user.name;
  user.avatar_url = avatar_url || user.avatar_url;
  user.bio = bio || user.bio;
  user.sports = sports || user.sports;
  user.interests = interests || user.interests;
  user.pet = pet || user.pet;
  user.updated_at = new Date();
  
  res.json(user);
});

// --- Start server ---
app.listen(port, '0.0.0.0', () => {
  console.log(`Test server running on port ${port}`);
  console.log('');
  console.log('=== TESTING INSTRUCTIONS ===');
  console.log('1. Start your Flutter app');
  console.log('2. Click "Login with Telegram"');
  console.log('3. To simulate confirmation, make a POST request to:');
  console.log(`   ${process.env.RAILWAY_PUBLIC_DOMAIN || 'http://localhost:' + port}/auth/telegram/confirm/[TOKEN]`);
  console.log('   with body: {"telegram_id": 123456789, "telegram_username": "testuser"}');
  console.log('4. Or use the provided test endpoint in another terminal');
  console.log('=============================');
});
