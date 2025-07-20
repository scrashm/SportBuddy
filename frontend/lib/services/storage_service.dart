import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Загрузка аватара пользователя
  Future<String> uploadUserAvatar(String userId, File imageFile) async {
    try {
      final ref = _storage.ref('avatars/$userId.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Ошибка загрузки аватара: $e');
    }
  }

  // Загрузка изображения события
  Future<String> uploadEventImage(String eventId, File imageFile) async {
    try {
      final ref = _storage.ref('events/$eventId.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Ошибка загрузки изображения события: $e');
    }
  }

  // Загрузка изображения из галереи
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Ошибка выбора изображения: $e');
    }
  }

  // Съемка фото
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Ошибка съемки фото: $e');
    }
  }

  // Удаление файла
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Ошибка удаления файла: $e');
    }
  }

  // Получение размера файла
  Future<int> getFileSize(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();
      return metadata.size;
    } catch (e) {
      throw Exception('Ошибка получения размера файла: $e');
    }
  }

  // Проверка существования файла
  Future<bool> fileExists(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }
} 