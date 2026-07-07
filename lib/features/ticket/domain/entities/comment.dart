import '../../../auth/domain/entities/user.dart';

/// Comment entity di domain layer.
class Comment {
  final String id;
  final String ticketId;
  final String content;
  final User? author;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.ticketId,
    required this.content,
    this.author,
    required this.createdAt,
  });
}
