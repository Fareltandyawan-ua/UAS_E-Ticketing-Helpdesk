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

  /// Aktifkan / nonaktifkan akun pengguna.
  /// User yang nonaktif tidak akan bisa login.
  Future<UserModel> setUserActive(String userId, bool isActive) async {
    final data = await _db
        .from('profiles')
        .update({'is_active': isActive})
        .eq('id', userId)
        .select()
        .single();
    return UserModel.fromJson(data);
  }

  /// Statistik user: total, per role, dan aktif/nonaktif
  Future<Map<String, int>> getUserStats() async {
    final data = await _db.from('profiles').select('role, is_active');
    final list = data as List;
    int users = 0, helpdesks = 0, admins = 0, inactive = 0;
    for (final r in list) {
      switch (r['role']) {
        case 'user':      users++;     break;
        case 'helpdesk':  helpdesks++; break;
        case 'admin':     admins++;    break;
      }
      if (r['is_active'] == false) inactive++;
    }
    return {
      'total':    list.length,
      'user':     users,
      'helpdesk': helpdesks,
      'admin':    admins,
      'inactive': inactive,
    };
  }
}
