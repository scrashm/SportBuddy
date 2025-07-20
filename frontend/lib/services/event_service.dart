import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получение всех событий
  Stream<List<Event>> fetchEvents() {
    return _firestore
        .collection('events')
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }

  // Получение событий по типу спорта
  Stream<List<Event>> fetchEventsBySport(String sportType) {
    return _firestore
        .collection('events')
        .where('sportType', isEqualTo: sportType)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }

  // Получение событий поблизости
  Stream<List<Event>> fetchNearbyEvents(GeoPoint userLocation, double radiusKm) {
    // Простая реализация - в реальном проекте нужно использовать
    // геопространственные запросы Firestore
    return _firestore
        .collection('events')
        .where('dateTime', isGreaterThan: Timestamp.now())
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .where((event) => _isWithinRadius(event.location, userLocation, radiusKm))
            .toList());
  }

  // Создание нового события
  Future<String> createEvent(Event event) async {
    try {
      final docRef = await _firestore.collection('events').add(event.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания события: $e');
    }
  }

  // Обновление события
  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('events').doc(eventId).update(updates);
    } catch (e) {
      throw Exception('Ошибка обновления события: $e');
    }
  }

  // Удаление события
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления события: $e');
    }
  }

  // Присоединение к событию
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Ошибка присоединения к событию: $e');
    }
  }

  // Выход из события
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Ошибка выхода из события: $e');
    }
  }

  // Получение событий пользователя
  Stream<List<Event>> fetchUserEvents(String userId) {
    return _firestore
        .collection('events')
        .where('creatorId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }

  // Получение событий, в которых участвует пользователь
  Stream<List<Event>> fetchUserParticipatingEvents(String userId) {
    return _firestore
        .collection('events')
        .where('participants', arrayContains: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }

  // Проверка, находится ли точка в радиусе
  bool _isWithinRadius(GeoPoint point1, GeoPoint point2, double radiusKm) {
    const double earthRadius = 6371; // радиус Земли в км
    
    final lat1 = point1.latitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLon = (point2.longitude - point1.longitude) * (pi / 180);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    return distance <= radiusKm;
  }
}

// Импорт для математических функций
import 'dart:math' show sin, cos, sqrt, atan2, pi; 