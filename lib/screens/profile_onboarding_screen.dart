import 'package:flutter/material.dart';

/// Экран заполнения профиля для новых пользователей
class ProfileOnboardingScreen extends StatefulWidget {
  final void Function(List<String> selectedSports) onComplete;
  const ProfileOnboardingScreen({super.key, required this.onComplete});

  @override
  State<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  // Список популярных видов спорта
  static const List<String> sportsList = [
    'Бег',
    'Кросс-фит',
    'Велосипед',
    'Плавание',
    'Футбол',
    'Баскетбол',
    'Теннис',
    'Йога',
    'Лыжи',
    'Скейтбординг',
    'Волейбол',
    'Фитнес',
    'Триатлон',
    'Хоккей',
    'Ролики',
    'Скалолазание',
    'Настольный теннис',
    'Единоборства',
    'Танцы',
    'Спортивное ориентирование',
    'Другое',
  ];

  // Выбранные виды спорта
  final Set<String> _selectedSports = {};

  void _toggleSport(String sport) {
    setState(() {
      if (_selectedSports.contains(sport)) {
        _selectedSports.remove(sport);
      } else {
        _selectedSports.add(sport);
      }
    });
  }

  void _submit() {
    if (_selectedSports.isNotEmpty) {
      widget.onComplete(_selectedSports.toList());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите хотя бы один вид спорта.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ваши любимые виды спорта')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите, чем вы любите заниматься:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: sportsList.map((sport) {
                  final selected = _selectedSports.contains(sport);
                  return GestureDetector(
                    onTap: () => _toggleSport(sport),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? Colors.blueAccent : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        sport,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 