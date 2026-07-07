import '../../../auth/domain/entities/user.dart';
import 'comment.dart';

/// Ticket entity di domain layer.
///
/// Pure business object — tidak punya dependency ke Supabase atau JSON.
/// Computed business rules (mis. `isOpen`, `canBeDeletedBy`) hidup di sini.
class Ticket {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  final User? createdBy;
  final User? assignedTo;
  final List<String> attachments;
  final List<Comment> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    this.createdBy,
    this.assignedTo,
    this.attachments = const [],
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Business rules ────────────────────────────────────────────────
  bool get isOpen => status == 'open';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isClosed => status == 'closed';

  /// Apakah user [user] boleh menghapus tiket ini.
  /// - Admin: selalu boleh
  /// - Pemilik tiket: hanya kalau status masih 'open'
  /// - Helpdesk: tidak (mereka close, bukan delete)
  bool canBeDeletedBy(User user) {
    if (user.isAdmin) return true;
    final isOwner = createdBy?.id == user.id;
    return isOwner && isOpen;
  }
}
