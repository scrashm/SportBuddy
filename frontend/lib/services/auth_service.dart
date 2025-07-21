import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';

class AuthService with ChangeNotifier {
  // TODO: Вынести в конфигурацию
  static const String _baseUrl = 'https://sportbuddy-production.up.railway.app';

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Добавляем конструктор для отправки начального события
  AuthService() {
    // Initial state is null, as no user is logged in
  }

  Future<void> signInWithTelegram() async {
    // 1. Запрос на начало входа
    final startResponse = await http.post(Uri.parse('$_baseUrl/auth/telegram/start'));
    if (startResponse.statusCode != 200) {
      throw Exception('Не удалось начать процесс входа.');
    }
    final startData = jsonDecode(startResponse.body);
    final String url = startData['url'];
    final String token = startData['token'];

    // 2. Открытие ссылки в Telegram
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Не удалось открыть Telegram.');
    }

    // 3. Polling статуса токена
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      final statusResponse = await http.get(Uri.parse('$_baseUrl/auth/telegram/status/$token'));
      if (statusResponse.statusCode != 200) {
        // Можно добавить обработку, если сервер упал
        continue;
      }
      final statusData = jsonDecode(statusResponse.body);
      if (statusData['status'] == 'confirmed') {
        final String telegramId = statusData['telegram_id'].toString();
        await _fetchAndSetUser(telegramId);
        break;
      }
      // Можно добавить таймаут, если пользователь долго не подтверждает
    }
  }

  Future<void> _fetchAndSetUser(String telegramId) async {
    print('[AUTH] Получение данных пользователя для telegramId: $telegramId');
    final userResponse = await http.get(Uri.parse('$_baseUrl/user/$telegramId'));
    if (userResponse.statusCode == 200) {
      _currentUser = User.fromJson(jsonDecode(userResponse.body));
      print('[AUTH] Пользователь получен и установлен: ${_currentUser?.name}');
      notifyListeners();
    } else {
      print('[AUTH ERROR] Не удалось получить данные пользователя: ${userResponse.body}');
      throw Exception('Не удалось получить данные пользователя.');
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String bio,
    required List<String> interests,
    required String pet,
    // TODO: Add avatarUrl later
  }) async {
    if (_currentUser == null) return;

    final response = await http.post(
      Uri.parse('$_baseUrl/user/${_currentUser!.telegramId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'bio': bio,
        'interests': interests,
        'pet': pet,
      }),
    );

    if (response.statusCode == 200) {
      _currentUser = User.fromJson(jsonDecode(response.body));
      notifyListeners();
    } else {
      // TODO: Handle error properly
      print('Failed to update profile: ${response.body}');
      throw Exception('Не удалось обновить профиль.');
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    print('[AUTH] Пользователь вышел из системы.');
    notifyListeners();
  }
} 