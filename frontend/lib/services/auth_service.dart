import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_model;

class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получение текущего пользователя
  app_model.User? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      return app_model.User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Пользователь',
        avatarUrl: firebaseUser.photoURL,
        sports: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return null;
  }

  // Stream для отслеживания изменений авторизации
  Stream<app_model.User?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser != null) {
        // Получаем дополнительные данные из Firestore
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          return app_model.User.fromFirestore(doc);
        } else {
          // Создаем нового пользователя
          return app_model.User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Пользователь',
            avatarUrl: firebaseUser.photoURL,
            sports: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }
      return null;
    });
  }

  // Вход через анонимную аутентификацию (для тестирования)
  Future<fb_auth.UserCredential> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      // Создаем запись в Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': 'Гость',
        'sports': [],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return credential;
    } catch (e) {
      throw Exception('Ошибка анонимного входа: $e');
    }
  }

  // Вход через VK (заглушка - нужно настроить VK SDK)
  Future<fb_auth.UserCredential> signInWithVK() async {
    // TODO: Реализовать вход через VK
    throw UnimplementedError('Вход через VK пока не реализован');
  }

  // Вход через Яндекс (заглушка - нужно настроить Яндекс OAuth)
  Future<fb_auth.UserCredential> signInWithYandex() async {
    // TODO: Реализовать вход через Яндекс
    throw UnimplementedError('Вход через Яндекс пока не реализован');
  }

  // Вход через Telegram (заглушка - нужно настроить Telegram Bot API)
  Future<fb_auth.UserCredential> signInWithTelegram() async {
    // TODO: Реализовать вход через Telegram
    throw UnimplementedError('Вход через Telegram пока не реализован');
  }

  // Обновление профиля пользователя
  Future<void> updateUserProfile({
    String? name,
    String? bio,
    String? work,
    String? study,
    String? pet,
    List<String>? sports,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final updates = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };

    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (work != null) updates['work'] = work;
    if (study != null) updates['study'] = study;
    if (pet != null) updates['pet'] = pet;
    if (sports != null) updates['sports'] = sports;

    await _firestore.collection('users').doc(user.uid).update(updates);
  }

  // Выход
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Ошибка выхода: $e');
    }
  }

  // Удаление аккаунта
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    try {
      // Удаляем данные из Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      // Удаляем аккаунт Firebase
      await user.delete();
    } catch (e) {
      throw Exception('Ошибка удаления аккаунта: $e');
    }
  }
} 