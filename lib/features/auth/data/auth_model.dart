class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final String role;
  final String? avatar;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    this.avatar,
    this.phone,
    this.isActive = true,
    this.createdAt,
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

  bool get isAdmin => role == 'admin';
  bool get isHelpdesk => role == 'helpdesk' || role == 'admin';
  bool get isUser => role == 'user';

  UserModel copyWith({
    String? name,
    String? email,
    String? avatar,
    String? phone,
    bool? isActive,
  }) => UserModel(
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
