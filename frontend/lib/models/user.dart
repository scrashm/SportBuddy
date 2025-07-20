import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final String? work;
  final String? study;
  final String? pet;
  final List<String> sports;
  final GeoPoint? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.work,
    this.study,
    this.pet,
    required this.sports,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  // Создание из Firestore документа
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      avatarUrl: data['avatarUrl'],
      bio: data['bio'],
      work: data['work'],
      study: data['study'],
      pet: data['pet'],
      sports: List<String>.from(data['sports'] ?? []),
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Конвертация в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'work': work,
      'study': study,
      'pet': pet,
      'sports': sports,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Копирование с изменениями
  User copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? bio,
    String? work,
    String? study,
    String? pet,
    List<String>? sports,
    GeoPoint? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      work: work ?? this.work,
      study: study ?? this.study,
      pet: pet ?? this.pet,
      sports: sports ?? this.sports,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 