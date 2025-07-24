// Cloud Function для логирования создания события в Firestore
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const Sentry = require('@sentry/node');
const { nodeProfilingIntegration } = require('@sentry/integrations');

// Initialize Sentry for error monitoring
Sentry.init({
  dsn: process.env.SENTRY_DSN || functions.config().sentry?.dsn,
  environment: process.env.NODE_ENV || 'production',
  integrations: [
    nodeProfilingIntegration(),
  ],
  tracesSampleRate: 0.1,
  profilesSampleRate: 0.1,
});

admin.initializeApp();

// Health check endpoint for Railway monitoring
exports.health = functions.https.onRequest((req, res) => {
  try {
    // Basic health checks
    const healthData = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      firebase: 'connected'
    };
    
    // Test Firestore connection
    admin.firestore().settings({ ignoreUndefinedProperties: true });
    
    res.status(200).json(healthData);
  } catch (error) {
    Sentry.captureException(error);
    res.status(500).json({ 
      status: 'unhealthy', 
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Enhanced error handling wrapper
const withErrorHandling = (handler) => {
  return async (data, context) => {
    try {
      return await handler(data, context);
    } catch (error) {
      console.error('Function error:', error);
      Sentry.withScope((scope) => {
        scope.setTag('function', context.eventType || 'unknown');
        scope.setContext('functionData', {
          data: typeof data === 'object' ? JSON.stringify(data) : data,
          context: {
            eventId: context.eventId,
            timestamp: context.timestamp,
            resource: context.resource
          }
        });
        Sentry.captureException(error);
      });
      throw error;
    }
  };
};

// Telegram auth endpoints with monitoring
exports.telegramAuthStart = functions.https.onRequest(async (req, res) => {
  const transaction = Sentry.startTransaction({
    op: 'function',
    name: 'telegramAuthStart'
  });
  
  try {
    // Generate unique token for auth session
    const token = admin.firestore().collection('temp').doc().id;
    const authUrl = `https://t.me/your_bot?start=${token}`;
    
    // Store pending auth in Firestore with TTL
    await admin.firestore().collection('auth_sessions').doc(token).set({
      status: 'pending',
      created: admin.firestore.FieldValue.serverTimestamp(),
      expires: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    });
    
    res.status(200).json({ url: authUrl, token });
  } catch (error) {
    Sentry.captureException(error);
    res.status(500).json({ error: 'Failed to start auth process' });
  } finally {
    transaction.finish();
  }
});

exports.telegramAuthStatus = functions.https.onRequest(async (req, res) => {
  const token = req.params[0].split('/').pop();
  
  try {
    const authDoc = await admin.firestore().collection('auth_sessions').doc(token).get();
    
    if (!authDoc.exists) {
      return res.status(404).json({ error: 'Invalid token' });
    }
    
    const authData = authDoc.data();
    
    // Check if token expired
    if (authData.expires && authData.expires.toDate() < new Date()) {
      await authDoc.ref.delete();
      return res.status(410).json({ error: 'Token expired' });
    }
    
    res.status(200).json({ 
      status: authData.status,
      telegram_id: authData.telegram_id 
    });
  } catch (error) {
    Sentry.captureException(error);
    res.status(500).json({ error: 'Failed to check auth status' });
  }
});

// User data endpoints with error handling
exports.getUser = functions.https.onRequest(async (req, res) => {
  const telegramId = req.params[0].split('/').pop();
  
  try {
    const userDoc = await admin.firestore().collection('users').doc(telegramId).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.status(200).json(userDoc.data());
  } catch (error) {
    Sentry.captureException(error);
    res.status(500).json({ error: 'Failed to fetch user data' });
  }
});

exports.updateUser = functions.https.onRequest(async (req, res) => {
  const telegramId = req.params[0].split('/').pop();
  
  try {
    const updateData = {
      ...req.body,
      updated: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await admin.firestore().collection('users').doc(telegramId).set(updateData, { merge: true });
    
    const updatedDoc = await admin.firestore().collection('users').doc(telegramId).get();
    res.status(200).json(updatedDoc.data());
  } catch (error) {
    Sentry.captureException(error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// Enhanced event logging with error monitoring
exports.logEventCreate = functions.firestore
  .document('events/{eventId}')
  .onCreate(withErrorHandling(async (snap, context) => {
    const newEvent = snap.data();
    console.log('Новое событие создано:', newEvent);
    
    // Add analytics tracking
    Sentry.addBreadcrumb({
      message: 'Event created',
      category: 'firestore',
      data: {
        eventId: context.params.eventId,
        eventType: newEvent.type,
        location: newEvent.location
      }
    });
    
    // Send to analytics service (placeholder)
    // await sendToAnalytics(newEvent);
    
    return null;
  }));

// Error monitoring for user updates
exports.logUserUpdate = functions.firestore
  .document('users/{userId}')
  .onUpdate(withErrorHandling(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    console.log('User profile updated:', {
      userId: context.params.userId,
      changes: Object.keys(after).filter(key => before[key] !== after[key])
    });
    
    return null;
  }));
