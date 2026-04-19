import '../../../core/network/supabase_service.dart';
import 'dashboard_model.dart';

class DashboardApi {
  final _db = SupabaseService.client;

  /// [userId] — jika diisi, hanya hitung tiket milik user tersebut (role: user).
  /// Jika null, hitung semua tiket (role: admin/helpdesk).
  Future<DashboardStats> getStats({String? userId}) async {
    var query = _db.from('tickets').select('status');

    // Filter berdasarkan role: user biasa hanya lihat tiket miliknya
    if (userId != null) {
      query = query.eq('created_by', userId);
    }

    final data = await query;

    int open = 0;
    int inProgress = 0;
    int resolved = 0;
    int closed = 0;

    for (final row in (data as List)) {
      final status = (row['status'] ?? '').toString();
      switch (status) {
        case 'open':
          open++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'resolved':
          resolved++;
          break;
        case 'closed':
          closed++;
          break;
      }
    }

    return DashboardStats(
      total: data.length,
      open: open,
      inProgress: inProgress,
      resolved: resolved,
      closed: closed,
    );
  }
}
