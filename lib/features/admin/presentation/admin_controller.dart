import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/admin_api.dart';
import '../../auth/data/auth_model.dart';

class AdminController extends GetxController {
  final AdminApi _api = AdminApi();

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxString searchQuery = ''.obs;
  final RxMap<String, int> userStats = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    debounce(searchQuery, (_) => fetchUsers(),
        time: const Duration(milliseconds: 400));
  }

  List<UserModel> get filteredUsers {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return users;
    return users
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q))
        .toList();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      users.assignAll(await _api.getAllUsers());
      final stats = await _api.getUserStats();
      userStats.assignAll(stats);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateRole(String userId, String newRole) async {
    isUpdating.value = true;
    try {
      final updated = await _api.updateUserRole(userId, newRole);
      final idx = users.indexWhere((u) => u.id == userId);
      if (idx >= 0) users[idx] = updated;
      Get.snackbar('Berhasil', 'Role user diperbarui menjadi $newRole',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      // Refresh stats setelah perubahan role
      final stats = await _api.getUserStats();
      userStats.assignAll(stats);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isUpdating.value = false;
    }
  }
}
