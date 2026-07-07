import 'package:image_picker/image_picker.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/comment.dart';
import '../entities/ticket.dart';
import '../entities/ticket_tracking.dart';

/// Kontrak repository ticket — domain layer hanya bergantung ke abstract ini.
///
/// Implementasi di `lib/features/ticket/data/repositories/ticket_repository_impl.dart`.
abstract class TicketRepository {
  /// Ambil list tiket dengan pagination. Filter opsional by userId / status.
  Future<List<Ticket>> getTickets({
    required int page,
    required int pageSize,
    String? filterByUserId,
    String? filterByStatus,
  });

  /// Ambil detail satu tiket lengkap (dengan comments & attachments).
  Future<Ticket> getTicketDetail(String ticketId);

  /// Buat tiket baru. Upload file attachment kalau ada.
  Future<Ticket> createTicket({
    required String title,
    required String description,
    required String priority,
    required String category,
    List<XFile>? attachments,
  });

  /// Update status tiket. Juga auto-create tracking record.
  Future<Ticket> updateTicketStatus(String ticketId, String newStatus);

  /// Assign tiket ke helpdesk tertentu.
  Future<Ticket> assignTicket(String ticketId, String assigneeId);

  /// Hapus tiket + cascade delete attachments dari storage.
  Future<void> deleteTicket(String ticketId);

  /// Tambah komentar di tiket.
  Future<Comment> addComment(String ticketId, String content);

  /// Ambil riwayat tracking (perubahan status) untuk satu tiket.
  Future<List<TicketTracking>> getTracking(String ticketId);

  /// Ambil list tiket dengan status 'closed' (untuk history screen).
  Future<List<Ticket>> getHistory();

  /// Ambil list user dengan role helpdesk/admin (untuk assign dropdown).
  Future<List<User>> getHelpdeskUsers();
}
