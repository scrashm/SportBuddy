import 'package:flutter_test/flutter_test.dart';
import 'package:sport_buddy_ru/services/auth_service.dart';
import 'package:sport_buddy_ru/models/user.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    tearDown(() {
      authService.dispose();
    });

    test('User can register successfully', () async {
      // Генерируем уникальный email, чтобы тест не падал при повторных запусках
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'testuser$timestamp@example.com';
      final password = 'password123';

      final User? user = await authService.register(email, password);

      // Проверяем, что регистрация (и последующий логин) прошли успешно
      expect(user, isNotNull);
      expect(user?.email, email);
    });
  });
} 