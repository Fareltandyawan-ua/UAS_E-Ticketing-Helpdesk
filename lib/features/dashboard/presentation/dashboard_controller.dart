import 'package:get/get.dart';
import '../data/dashboard_api.dart';
import '../data/dashboard_model.dart';
import '../../auth/presentation/auth_controller.dart';

class DashboardController extends GetxController {
  final DashboardApi _api = DashboardApi();

  final Rx<DashboardStats> stats = DashboardStats.empty().obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStats();
  }

  Future<void> fetchStats() async {
    isLoading.value = true;
    try {
      final authCtrl = Get.find<AuthController>();
      final isUserRole = authCtrl.currentUser.value?.isUser ?? true;

      // User biasa hanya lihat statistik tiketnya sendiri
      // Admin/Helpdesk lihat semua tiket
      final userId =
          isUserRole ? authCtrl.currentUser.value?.id : null;

      stats.value = await _api.getStats(userId: userId);
    } catch (_) {}
    isLoading.value = false;
  }
}
