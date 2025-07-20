import 'package:flutter/material.dart';

/// Экран профиля пользователя
class ProfileScreen extends StatelessWidget {
  final List<String> sports;
  final String? avatar;
  final String? bio;
  const ProfileScreen({super.key, this.sports = const [], this.avatar, this.bio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    avatar ?? '🙂',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('О себе:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        (bio != null && bio!.isNotEmpty)
                          ? bio!
                          : 'Вы ещё не добавили заметку о себе.',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Ваши любимые виды спорта:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (sports.isEmpty)
              const Text('Вы ещё не выбрали любимые виды спорта.'),
            if (sports.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sports.map((sport) => Chip(label: Text(sport))).toList(),
              ),
          ],
        ),
      ),
    );
  }
} 