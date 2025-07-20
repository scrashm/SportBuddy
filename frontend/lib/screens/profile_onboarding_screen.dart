import 'package:flutter/material.dart';

class ProfileOnboardingScreen extends StatefulWidget {
  final void Function(List<String> interests) onComplete;
  const ProfileOnboardingScreen({super.key, required this.onComplete});

  @override
  State<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  static const List<Map<String, String>> interestsList = [
    {'emoji': '🏃', 'label': 'Бег'},
    {'emoji': '🚴', 'label': 'Велосипед'},
    {'emoji': '🏊', 'label': 'Плавание'},
    {'emoji': '⚽', 'label': 'Футбол'},
    {'emoji': '🏀', 'label': 'Баскетбол'},
    {'emoji': '🎾', 'label': 'Теннис'},
    {'emoji': '🧘', 'label': 'Йога'},
    {'emoji': '⛷️', 'label': 'Лыжи'},
    {'emoji': '🛹', 'label': 'Скейтбординг'},
    {'emoji': '🏐', 'label': 'Волейбол'},
    {'emoji': '🏋️‍♂️', 'label': 'Фитнес'},
    {'emoji': '🏒', 'label': 'Хоккей'},
    {'emoji': '🛼', 'label': 'Ролики'},
    {'emoji': '🧗', 'label': 'Скалолазание'},
    {'emoji': '🏓', 'label': 'Наст. теннис'},
    {'emoji': '🥋', 'label': 'Единоборства'},
  ];

  final Set<int> _selected = {};
  static const int maxInterests = 5;
  static const int minInterests = 1;

  void _toggle(int idx) {
    setState(() {
      if (_selected.contains(idx)) {
        _selected.remove(idx);
      } else if (_selected.length < maxInterests) {
        _selected.add(idx);
      }
    });
  }

  void _submit() {
    if (_selected.length >= minInterests) {
      widget.onComplete(_selected.map((i) => interestsList[i]['label']!).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFDE4), // светло-жёлтый
              Color(0xFFFFE680), // жёлтый
              Color(0xFFFFC371), // оранжеватый
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Ваши любимые виды спорта',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('(${_selected.length}/$maxInterests)', style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Выберите, чем вы любите заниматься:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (int i = 0; i < interestsList.length; i++)
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(interestsList[i]['emoji']!, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(interestsList[i]['label']!, style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                        selected: _selected.contains(i),
                        onSelected: (_) => _toggle(i),
                        selectedColor: Colors.orangeAccent,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: _selected.contains(i) ? Colors.white : Colors.black87,
                          fontWeight: _selected.contains(i) ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                            color: _selected.contains(i) ? Colors.orangeAccent : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selected.length >= minInterests ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Продолжить', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// Для плавного перехода с экрана авторизации используйте:
// Navigator.of(context).push(PageRouteBuilder(
//   pageBuilder: (_, __, ___) => ProfileOnboardingScreen(...),
//   transitionsBuilder: (_, anim, __, child) => SlideTransition(
//     position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.ease)),
//     child: child,
//   ),
// )); 