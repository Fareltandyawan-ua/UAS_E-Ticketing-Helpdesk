import '../../../core/network/supabase_service.dart';
import 'dashboard_model.dart';

class DashboardApi {
  final _db = SupabaseService.client;

  /// [userId]  → Role user: hanya tiket miliknya sendiri.
  /// null      → Role admin/helpdesk: semua tiket.
  /// [helpdeskId] → Jika diisi, hitung tiket yang di-assign ke helpdesk ini.
  Future<DashboardStats> getStats({
    String? userId,
    String? helpdeskId,
  }) async {
    var query = _db.from('tickets').select('status, assigned_to');

    if (userId != null) {
      query = query.eq('created_by', userId);
    }

    final data = await query;

    int open = 0, inProgress = 0, resolved = 0, closed = 0;
    int assignedToMe = 0, unassigned = 0;

    for (final row in (data as List)) {
      final status = (row['status'] ?? '').toString();
      final assignedTo = row['assigned_to'];

      switch (status) {
        case 'open':          open++;          break;
        case 'in_progress':   inProgress++;    break;
        case 'resolved':      resolved++;      break;
        case 'closed':        closed++;        break;
      }

      if (helpdeskId != null && assignedTo == helpdeskId) {
        assignedToMe++;
      }
      if (assignedTo == null) {
        unassigned++;
      }
    }

    return DashboardStats(
      total:        data.length,
      open:         open,
      inProgress:   inProgress,
      resolved:     resolved,
      closed:       closed,
      assignedToMe: assignedToMe,
      unassigned:   unassigned,
    );
  }
}
