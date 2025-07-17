import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:html' as html; // Для web загрузки файла

class AvatarBioOnboardingScreen extends StatefulWidget {
  final void Function(String? avatarPath, String bio, String work, String study, String? pet) onComplete;
  const AvatarBioOnboardingScreen({super.key, required this.onComplete});

  @override
  State<AvatarBioOnboardingScreen> createState() => _AvatarBioOnboardingScreenState();
}

class _AvatarBioOnboardingScreenState extends State<AvatarBioOnboardingScreen> {
  Uint8List? _avatarBytes;
  String _bio = '';
  String _work = '';
  String _study = '';
  int? _selectedPet;
  bool _avatarHighlight = false;

  static const List<Map<String, String>> pets = [
    {'emoji': '🐶', 'label': 'Собака'},
    {'emoji': '🐱', 'label': 'Кот'},
    {'emoji': '🐦', 'label': 'Птица'},
    {'emoji': '🐢', 'label': 'Черепаха'},
    {'emoji': '🐠', 'label': 'Рыбка'},
    {'emoji': '🐰', 'label': 'Кролик'},
    {'emoji': '🦜', 'label': 'Попугай'},
    {'emoji': 'img', 'label': 'Капибара'}, // img - специальная метка
  ];

  void _pickImage() async {
    setState(() => _avatarHighlight = true);
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((event) {
          setState(() {
            _avatarBytes = reader.result as Uint8List;
            _avatarHighlight = false;
          });
        });
      } else {
        setState(() => _avatarHighlight = false);
      }
    });
  }

  void _submit() {
    if (_bio.trim().isEmpty && _avatarBytes == null) return;
    widget.onComplete(
      _avatarBytes != null ? 'user_uploaded' : null,
      _bio.trim(),
      _work.trim(),
      _study.trim(),
      _selectedPet != null ? pets[_selectedPet!]['emoji'] : null,
    );
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
              Color(0xFFFFFDE4),
              Color(0xFFFFE680),
              Color(0xFFFFC371),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                // Фото профиля с эффектом выделения
                GestureDetector(
                  onTap: _pickImage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                    padding: _avatarHighlight ? const EdgeInsets.all(6) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _avatarHighlight
                        ? [BoxShadow(color: Colors.orangeAccent.withOpacity(0.5), blurRadius: 16, spreadRadius: 2)]
                        : [],
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                      backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                      child: _avatarBytes == null
                          ? const Icon(Icons.add_a_photo, size: 40, color: Colors.orangeAccent)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // О себе
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (_bio.isEmpty)
                      const Opacity(
                        opacity: 0.5,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text('О себе', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    TextField(
                      maxLines: 3,
                      maxLength: 120,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        fillColor: Colors.white,
                        filled: true,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        // labelText убираем, чтобы не мешал кастомному placeholder
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (v) => setState(() => _bio = v),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Место работы
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (_work.isEmpty)
                      const Opacity(
                        opacity: 0.5,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text('Место работы', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (v) => setState(() => _work = v),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Место учёбы
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (_study.isEmpty)
                      const Opacity(
                        opacity: 0.5,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text('Место учёбы', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (v) => setState(() => _study = v),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Домашнее животное
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Домашний питомец:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < pets.length; i++)
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (pets[i]['emoji'] == 'img')
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Image.asset(
                                  'assets/images/capybara2.jpg',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Text(pets[i]['emoji']!, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Text(pets[i]['label']!, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        selected: _selectedPet == i,
                        onSelected: (_) => setState(() => _selectedPet = i),
                        selectedColor: Colors.orangeAccent,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: _selectedPet == i ? Colors.white : Colors.black87,
                          fontWeight: _selectedPet == i ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                            color: _selectedPet == i ? Colors.orangeAccent : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_bio.trim().isNotEmpty || _avatarBytes != null) ? _submit : null,
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