import '../../../auth/domain/entities/user.dart';

/// TicketTracking entity di domain layer — riwayat perubahan status tiket.
class TicketTracking {
  final String id;
  final String ticketId;
  final String status;
  final String description;
  final User? changedBy;
  final DateTime createdAt;

  const TicketTracking({
    required this.id,
    required this.ticketId,
    required this.status,
    required this.description,
    this.changedBy,
    required this.createdAt,
  });
}
