import 'package:flutter/material.dart';

/// Экран авторизации
/// TODO: Реализовать настоящую авторизацию через OAuth (Яндекс, VK, Telegram)
class AuthScreen extends StatelessWidget {
  final VoidCallback onAuthorized;
  const AuthScreen({super.key, required this.onAuthorized});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход в Sport Buddy')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Войдите через удобный сервис', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            // Кнопка входа через Яндекс (заглушка)
            ElevatedButton.icon(
              icon: Image.asset('assets/yandex.png', height: 24),
              label: const Text('Войти через Яндекс'),
              onPressed: onAuthorized, // TODO: Добавить логику OAuth
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[700], foregroundColor: Colors.black),
            ),
            const SizedBox(height: 16),
            // Кнопка входа через VK (заглушка)
            ElevatedButton.icon(
              icon: Image.asset('assets/vk.png', height: 24),
              label: const Text('Войти через VK'),
              onPressed: onAuthorized, // TODO: Добавить логику OAuth
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
            ),
            const SizedBox(height: 16),
            // Кнопка входа через Telegram (заглушка)
            ElevatedButton.icon(
              icon: Image.asset('assets/telegram.png', height: 24),
              label: const Text('Войти через Telegram'),
              onPressed: onAuthorized, // TODO: Добавить логику OAuth
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
} 