// Cloud Function для логирования создания события в Firestore
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Логирование создания события
exports.logEventCreate = functions.firestore
  .document('events/{eventId}')
  .onCreate((snap, context) => {
    const newEvent = snap.data();
    console.log('Новое событие создано:', newEvent);
    // Здесь можно добавить отправку данных в BigQuery или другую аналитику
    return null;
  }); 