import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'config_service.dart';
import 'error_service.dart';

class AuthService with ChangeNotifier {
  String get _baseUrl => ConfigService.baseUrl;

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Добавляем конструктор для отправки начального события
  AuthService() {
    // Initial state is null, as no user is logged in
  }

  Future<void> signInWithTelegram() async {
    // Check connectivity first
    if (!await ErrorService.isConnected()) {
      ErrorService.showErrorToast('Нет подключения к интернету. Проверьте сетевые настройки.');
      throw Exception('No internet connection');
    }

    try {
      // 1. Запрос на начало входа с таймаутом
      final startResponse = await http.post(
        Uri.parse('$_baseUrl/auth/telegram/start'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timeout', const Duration(seconds: 30));
        },
      );
      
      if (startResponse.statusCode != 200) {
        if (startResponse.statusCode == 500) {
          ErrorService.handleServerMaintenance();
        } else {
          ErrorService.showErrorToast('Сервер временно недоступен (${startResponse.statusCode})');
        }
        throw Exception('Failed to start auth process: ${startResponse.statusCode}');
      }
      
      final Map<String, dynamic> startData;
      try {
        startData = jsonDecode(startResponse.body);
      } catch (e) {
        ErrorService.showErrorToast('Получены некорректные данные от сервера');
        throw Exception('Invalid response format');
      }
      
      // Validate response
      ErrorService.validateTelegramAuthResponse(startData);
      
      final String url = startData['url'];
      final String token = startData['token'];

      // 2. Открытие ссылки в Telegram
      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          ErrorService.showErrorToast('Не удалось открыть Telegram. Убедитесь, что приложение установлено.');
          throw Exception('Failed to launch Telegram');
        }
      } catch (e) {
        ErrorService.handleTelegramAuthError(e);
        rethrow;
      }

      // 3. Polling статуса токена с таймаутом
      const int maxAttempts = 40; // 2 minutes with 3-second intervals
      int attempts = 0;
      
      while (attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 3));
        attempts++;
        
        try {
          final statusResponse = await http.get(
            Uri.parse('$_baseUrl/auth/telegram/status/$token'),
          ).timeout(const Duration(seconds: 10));
          
          if (statusResponse.statusCode == 404) {
            ErrorService.showErrorToast('Сессия авторизации не найдена. Попробуйте еще раз.');
            throw Exception('Auth session not found');
          }
          
          if (statusResponse.statusCode == 410) {
            ErrorService.showErrorToast('Время авторизации истекло. Попробуйте еще раз.');
            throw Exception('Auth session expired');
          }
          
          if (statusResponse.statusCode != 200) {
            // Log error but continue polling
            debugPrint('Status check failed: ${statusResponse.statusCode}');
            continue;
          }
          
          final Map<String, dynamic> statusData;
          try {
            statusData = jsonDecode(statusResponse.body);
          } catch (e) {
            debugPrint('Failed to parse status response: $e');
            continue;
          }
          
          if (statusData['status'] == 'confirmed') {
            final String telegramId = statusData['telegram_id'].toString();
            await _fetchAndSetUser(telegramId);
            ErrorService.showSuccessToast('Успешная авторизация!');
            break;
          } else if (statusData['status'] == 'failed') {
            ErrorService.showErrorToast('Авторизация отклонена. Попробуйте еще раз.');
            throw Exception('Auth failed');
          }
          
        } on TimeoutException {
          // Continue polling on timeout
          debugPrint('Status check timeout, attempt $attempts');
          continue;
        } on SocketException {
          // Network error during polling
          if (attempts % 5 == 0) { // Show warning every 5 attempts
            ErrorService.showWarningToast('Проблемы с сетью, продолжаем попытки...');
          }
          continue;
        }
      }
      
      if (attempts >= maxAttempts) {
        ErrorService.showErrorToast(
          'Время ожидания авторизации истекло. Попробуйте еще раз.',
        );
        throw Exception('Auth timeout');
      }
      
    } on TimeoutException {
      ErrorService.showErrorToast('Превышено время ожидания. Проверьте подключение.');
      rethrow;
    } on SocketException catch (e) {
      ErrorService.handleNetworkError(e);
      rethrow;
    } on FormatException {
      ErrorService.showErrorToast('Получены некорректные данные от сервера');
      rethrow;
    } catch (e) {
      // Handle any other unexpected errors
      if (e.toString().contains('Failed to launch')) {
        ErrorService.handleTelegramAuthError(e);
      } else {
        ErrorService.handleGenericError(e, fallbackMessage: 'Ошибка при авторизации через Telegram');
      }
      rethrow;
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
    XFile? avatarXFile,
  }) async {
    if (_currentUser == null) return;

    String? avatarUrl;
    if (avatarXFile != null) {
      // Загрузка аватара на сервер
      final uri = Uri.parse('$_baseUrl/user/${_currentUser!.telegramId}/avatar');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('avatar', avatarXFile.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        avatarUrl = data['avatarUrl'] as String?;
      } else {
        print('Failed to upload avatar: ${response.body}');
        throw Exception('Не удалось загрузить аватар.');
      }
    }

    final profileBody = {
      'name': name,
      'bio': bio,
      'interests': interests,
      'pet': pet,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/user/${_currentUser!.telegramId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profileBody),
    );

    if (response.statusCode == 200) {
      _currentUser = User.fromJson(jsonDecode(response.body));
      notifyListeners();
    } else {
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