import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_user;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _interestsController;
  late TextEditingController _petController;
  XFile? _avatarXFile;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _interestsController = TextEditingController(text: user?.interests?.join(', ') ?? '');
    _petController = TextEditingController(text: user?.pet ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    _petController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final interests = _interestsController.text.split(',').map((e) => e.trim()).toList();
      
      await authService.updateUserProfile(
        name: _nameController.text,
        bio: _bioController.text,
        interests: interests,
        pet: _petController.text,
        avatarXFile: _avatarXFile,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль успешно сохранен!')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _avatarXFile = pickedFile;
        _avatarBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          if (user == null) {
            return const Center(child: Text('Пользователь не найден.'));
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _avatarBytes != null
                                ? MemoryImage(_avatarBytes!)
                                : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                            child: (_avatarBytes == null && (user.avatarUrl == null || user.avatarUrl!.isEmpty))
                                ? Image.asset('assets/images/capybara.png', width: 50, height: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: _pickImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Имя'),
                      validator: (value) => value!.isEmpty ? 'Введите имя' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'О себе (био)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _interestsController,
                      decoration: const InputDecoration(labelText: 'Интересы (через запятую)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _petController,
                      decoration: const InputDecoration(labelText: 'Домашнее животное'),
                    ),
                    // TODO: Add location picker
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 