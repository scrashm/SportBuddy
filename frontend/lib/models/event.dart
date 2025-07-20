import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String sportType;
  final DateTime dateTime;
  final GeoPoint location;
  final String creatorId;
  final List<String> participants;
  final int maxParticipants;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.sportType,
    required this.dateTime,
    required this.location,
    required this.creatorId,
    required this.participants,
    required this.maxParticipants,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Создание из Firestore документа
  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      sportType: data['sportType'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint,
      creatorId: data['creatorId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      maxParticipants: data['maxParticipants'] ?? 10,
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Конвертация в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'sportType': sportType,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'creatorId': creatorId,
      'participants': participants,
      'maxParticipants': maxParticipants,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Проверка, может ли пользователь присоединиться
  bool canJoin(String userId) {
    return !participants.contains(userId) && 
           participants.length < maxParticipants &&
           dateTime.isAfter(DateTime.now());
  }

  // Копирование с изменениями
  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? sportType,
    DateTime? dateTime,
    GeoPoint? location,
    String? creatorId,
    List<String>? participants,
    int? maxParticipants,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sportType: sportType ?? this.sportType,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      creatorId: creatorId ?? this.creatorId,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 