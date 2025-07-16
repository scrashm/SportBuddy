import 'package:flutter/material.dart';

/// Экран выбора аватара и заметки 'О себе' для нового пользователя
class AvatarBioOnboardingScreen extends StatefulWidget {
  final void Function(String avatar, String bio) onComplete;
  const AvatarBioOnboardingScreen({super.key, required this.onComplete});

  @override
  State<AvatarBioOnboardingScreen> createState() => _AvatarBioOnboardingScreenState();
}

class _AvatarBioOnboardingScreenState extends State<AvatarBioOnboardingScreen> {
  // Список аватаров (пути к локальным asset-картинкам или emoji)
  static const List<String> avatars = [
    '👦', '👧', '🧑', '👨‍🦰', '👩‍🦰', '👨‍🦱', '👩‍🦱', '👨‍🦳', '👩‍🦳', '🧔', '👱‍♂️', '👱‍♀️', '🧑‍🎤', '🧑‍🏫', '🧑‍💻', '🧑‍🔬', '🧑‍🚀', '🧑‍🎨', '🏃‍♂️', '🏃‍♀️', '🚴‍♂️', '🚴‍♀️', '🏊‍♂️', '🏊‍♀️'
  ];

  String? _selectedAvatar;
  final TextEditingController _bioController = TextEditingController();

  void _submit() {
    if (_selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите аватар.')),
      );
      return;
    }
    widget.onComplete(_selectedAvatar!, _bioController.text.trim());
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ваш аватар и о себе')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Выберите аватар:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: avatars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final avatar = avatars[index];
                  final selected = _selectedAvatar == avatar;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = avatar),
                    child: CircleAvatar(
                      radius: selected ? 32 : 28,
                      backgroundColor: selected ? Colors.blueAccent : Colors.grey[300],
                      child: Text(
                        avatar,
                        style: TextStyle(fontSize: 32, color: selected ? Colors.white : Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('О себе:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 120,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Коротко расскажите о себе...'
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Продолжить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 