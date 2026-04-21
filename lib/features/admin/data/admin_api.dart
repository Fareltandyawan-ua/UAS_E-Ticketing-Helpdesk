import '../../../core/network/supabase_service.dart';
import '../../auth/data/auth_model.dart';

class AdminApi {
  final _db = SupabaseService.client;

  /// Ambil semua user (untuk admin)
  Future<List<UserModel>> getAllUsers() async {
    final data = await _db
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  /// Ubah role user
  Future<UserModel> updateUserRole(String userId, String newRole) async {
    final data = await _db
        .from('profiles')
        .update({'role': newRole})
        .eq('id', userId)
        .select()
        .single();
    return UserModel.fromJson(data);
  }

  /// Statistik user: total, per role
  Future<Map<String, int>> getUserStats() async {
    final data = await _db.from('profiles').select('role');
    final list = data as List;
    int users = 0, helpdesks = 0, admins = 0;
    for (final r in list) {
      switch (r['role']) {
        case 'user':      users++;     break;
        case 'helpdesk':  helpdesks++; break;
        case 'admin':     admins++;    break;
      }
    }
    return {
      'total':    list.length,
      'user':     users,
      'helpdesk': helpdesks,
      'admin':    admins,
    };
  }
}
