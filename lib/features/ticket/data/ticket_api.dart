import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../core/network/supabase_service.dart';
import '../../auth/data/auth_model.dart';
import 'ticket_model.dart';

class TicketApi {
  final _db = SupabaseService.client;

  Future<List<TicketModel>> getTickets({
    String? status,
    String? priority,
    String? search,
    int page = 1,
    String? createdBy, // filter by userId untuk role user biasa
  }) async {
    var query = _db.from('tickets').select('''
      *,
      created_by:profiles!tickets_created_by_fkey(id, name, username, role),
      assigned_to:profiles!tickets_assigned_to_fkey(id, name, username, role),
      comments(id)
    ''');

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (priority != null && priority.isNotEmpty) {
      query = query.eq('priority', priority);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }
    if (createdBy != null && createdBy.isNotEmpty) {
      query = query.eq('created_by', createdBy);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range((page - 1) * 20, page * 20 - 1);

    return (data as List).map((e) => TicketModel.fromJson(e)).toList();
  }

  Future<TicketModel> getTicketDetail(String id) async {
    final data = await _db
        .from('tickets')
        .select('''
      *,
      created_by:profiles!tickets_created_by_fkey(id, name, username, role),
      assigned_to:profiles!tickets_assigned_to_fkey(id, name, username, role),
      comments(id, content, created_at,
        author:profiles!comments_author_id_fkey(id, name, username, role)
      ),
      attachments(id, file_url, file_name)
    ''')
        .eq('id', id)
        .single();
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String priority,
    required String category,
    List<File>? attachments,
  }) async {
    final userId = SupabaseService.client.auth.currentUser!.id;
    final data = await _db
        .from('tickets')
        .insert({
          'title': title,
          'description': description,
          'priority': priority,
          'category': category,
          'created_by': userId,
          'status': 'open',
        })
        .select('''
          *,
          created_by:profiles!tickets_created_by_fkey(id, name, username, role)
        ''')
        .single();

    final ticket = TicketModel.fromJson(data);

    // Upload lampiran ke Supabase Storage jika ada
    if (attachments != null && attachments.isNotEmpty) {
      for (final file in attachments) {
        try {
          final fileName =
              '${ticket.id}/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
          await _db.storage.from('attachments').upload(fileName, file);
          final fileUrl =
              _db.storage.from('attachments').getPublicUrl(fileName);
          await _db.from('attachments').insert({
            'ticket_id': ticket.id,
            'file_url': fileUrl,
            'file_name': p.basename(file.path),
          });
        } catch (_) {
          // Jika satu file gagal, lanjutkan upload file berikutnya
        }
      }
    }

    return ticket;
  }

  Future<TicketModel> updateTicketStatus(String id, String status) async {
    final data = await _db
        .from('tickets')
        .update({'status': status})
        .eq('id', id)
        .select()
        .single();
    return TicketModel.fromJson(data);
  }

  /// Assign tiket ke helpdesk/admin tertentu
  Future<TicketModel> assignTicket(String ticketId, String assigneeId) async {
    final data = await _db
        .from('tickets')
        .update({'assigned_to': assigneeId})
        .eq('id', ticketId)
        .select('''
          *,
          created_by:profiles!tickets_created_by_fkey(id, name, username, role),
          assigned_to:profiles!tickets_assigned_to_fkey(id, name, username, role)
        ''')
        .single();
    return TicketModel.fromJson(data);
  }

  /// Ambil daftar user helpdesk & admin untuk dropdown assign tiket
  Future<List<UserModel>> getHelpdeskUsers() async {
    final data = await _db
        .from('profiles')
        .select()
        .inFilter('role', ['helpdesk', 'admin'])
        .order('name');
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<CommentModel> addComment(String ticketId, String content) async {
    final userId = SupabaseService.client.auth.currentUser!.id;
    final data = await _db
        .from('comments')
        .insert({
          'ticket_id': ticketId,
          'author_id': userId,
          'content': content,
        })
        .select('''
      *, author:profiles!comments_author_id_fkey(id, name, username, role)
    ''')
        .single();
    return CommentModel.fromJson(data);
  }

  Future<List<TicketTrackingModel>> getTracking(String ticketId) async {
    final data = await _db
        .from('ticket_tracking')
        .select('*, changed_by:profiles(id, name, username, role)')
        .eq('ticket_id', ticketId)
        .order('created_at');
    return (data as List).map((e) => TicketTrackingModel.fromJson(e)).toList();
  }

  Future<List<TicketModel>> getHistory({String? userId}) async {
    final uid =
        userId ?? SupabaseService.client.auth.currentUser!.id;
    final data = await _db
        .from('tickets')
        .select(
          '*, created_by:profiles!tickets_created_by_fkey(id, name, username, role)',
        )
        .eq('created_by', uid)
        .inFilter('status', ['resolved', 'closed'])
        .order('updated_at', ascending: false);
    return (data as List).map((e) => TicketModel.fromJson(e)).toList();
  }
}
