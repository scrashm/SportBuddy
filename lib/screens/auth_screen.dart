import 'package:flutter/material.dart';

/// Экран авторизации
/// TODO: Реализовать настоящую авторизацию через OAuth (Яндекс, VK, Telegram)
class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthorized;
  const AuthScreen({super.key, required this.onAuthorized});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  double _greetingOpacity = 0.0;
  double _menuOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Сначала появляется приветствие
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _greetingOpacity = 1.0);
      // Через 1.5 сек затухает приветствие и появляется меню
      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() => _greetingOpacity = 0.0);
        Future.delayed(const Duration(milliseconds: 700), () {
          setState(() => _menuOpacity = 1.0);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход в Sport Buddy')),
      body: Stack(
        children: [
          // Градиентный фон
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFa8e063), // светло-зелёный
                  Color(0xFF56ab2f), // насыщенный зелёный
                ],
              ),
            ),
          ),
          // Лёгкий белый overlay для читаемости
          Container(
            color: Colors.white24,
          ),
          // Анимированное приветствие
          Center(
            child: AnimatedOpacity(
              opacity: _greetingOpacity,
              duration: const Duration(milliseconds: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.sports_soccer, size: 56, color: Colors.white70),
                  SizedBox(height: 24),
                  Text(
                    'Добро пожаловать!',
                    style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          // Анимированное меню авторизации
          Center(
            child: AnimatedOpacity(
              opacity: _menuOpacity,
              duration: const Duration(milliseconds: 700),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_soccer, size: 56, color: Colors.white70),
                  const SizedBox(height: 24),
                  const Text('Войдите через удобный сервис', style: TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 32),
                  // Кнопка входа через Яндекс (кастомная иконка)
                  ElevatedButton.icon(
                    icon: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // Жёлтый круг с аватаром
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFEB3B), // Ярко-жёлтый
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        // Красный бейдж "Я"
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF44336), // Красный
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'Я',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    label: const Text('Войти через Яндекс'),
                    onPressed: widget.onAuthorized, // TODO: Добавить логику OAuth
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      foregroundColor: Colors.black,
                      minimumSize: const Size(220, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Кнопка входа через VK (кастомная иконка)
                  ElevatedButton.icon(
                    icon: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // Синий круг с аватаром
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4C75A3), // VK blue
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        // Иконка VK в правом нижнем углу
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.vpn_lock, color: Color(0xFF4C75A3), size: 12), // Используем подходящий Material-икон
                          ),
                        ),
                      ],
                    ),
                    label: const Text('Через ВК'),
                    onPressed: widget.onAuthorized, // TODO: Добавить логику OAuth
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4C75A3),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(220, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Кнопка входа через Telegram (кастомная иконка)
                  ElevatedButton.icon(
                    icon: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // Синий круг с аватаром
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF229ED9), // Telegram blue
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        // Иконка Telegram в правом нижнем углу
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.send, color: Color(0xFF229ED9), size: 12),
                          ),
                        ),
                      ],
                    ),
                    label: const Text('Войти через Telegram'),
                    onPressed: widget.onAuthorized, // TODO: Добавить логику OAuth
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(220, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 