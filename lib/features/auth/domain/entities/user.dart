/// User entity di domain layer.
///
/// **Pure business object** — tidak punya dependency ke Supabase, JSON,
/// atau library lain. Hanya field + computed getter business rule.
///
/// Mapping ke/dari DTO database dilakukan oleh `UserModel`
/// (lihat `lib/features/auth/data/models/user_model.dart`).
class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String role;
  final String? avatar;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;

  const User({
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

  // ── Business rules ────────────────────────────────────────────────
  bool get isAdmin => role == 'admin';
  bool get isHelpdesk => role == 'helpdesk' || role == 'admin';
  bool get isUser => role == 'user';
}
