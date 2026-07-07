import '../../domain/entities/user.dart';

/// Data Transfer Object yang merepresentasikan User dari/ke JSON Supabase.
/// Extends domain entity [User] supaya bisa dilewatkan ke layer mana pun
/// tanpa konversi tambahan.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.username,
    required super.role,
    super.avatar,
    super.phone,
    super.isActive,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
      // Supabase menyimpan kolom sebagai avatar_url
      avatar: json['avatar_url'] ?? json['avatar'],
      phone: json['phone'],
      // Default true agar backward compatible jika kolom belum ada
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Buat UserModel dari domain User (untuk caching ke local storage).
  factory UserModel.fromEntity(User user) => UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        username: user.username,
        role: user.role,
        avatar: user.avatar,
        phone: user.phone,
        isActive: user.isActive,
        createdAt: user.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'role': role,
        'avatar': avatar,
        'avatar_url': avatar,
        'phone': phone,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? email,
    String? avatar,
    String? phone,
    bool? isActive,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        username: username,
        role: role,
        avatar: avatar ?? this.avatar,
        phone: phone ?? this.phone,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
