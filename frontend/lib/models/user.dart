class User {
  final String id;
  final String telegramId;
  final String? telegramUsername;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final List<String>? sports;
  final List<String>? interests;
  final String? pet;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.telegramId,
    this.telegramUsername,
    this.name,
    this.avatarUrl,
    this.bio,
    this.sports,
    this.interests,
    this.pet,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      telegramId: json['telegram_id'].toString(),
      telegramUsername: json['telegram_username'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      sports: json['sports'] != null ? List<String>.from(json['sports']) : null,
      interests: json['interests'] != null ? List<String>.from(json['interests']) : null,
      pet: json['pet'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'telegram_id': telegramId,
      'telegram_username': telegramUsername,
      'name': name,
      'avatar_url': avatarUrl,
      'bio': bio,
      'sports': sports,
      'interests': interests,
      'pet': pet,
    };
  }
} 