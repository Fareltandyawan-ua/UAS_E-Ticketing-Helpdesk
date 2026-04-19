import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/network/supabase_service.dart';
import '../../core/storage/local_storage.dart';
import '../auth/data/auth_model.dart';
import '../auth/presentation/auth_controller.dart';

class EditProfileController extends GetxController {
  final AuthController _authCtrl = Get.find<AuthController>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final user = _authCtrl.currentUser.value;
    if (user != null) {
      nameController.text = user.name;
      phoneController.text = user.phone ?? '';
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> save() async {
    isLoading.value = true;
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User tidak ditemukan');

      await SupabaseService.client
          .from('profiles')
          .update({
            'name': nameController.text.trim(),
            'phone': phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
          })
          .eq('id', userId);

      // Refresh currentUser
      final profile = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final email = SupabaseService.client.auth.currentUser?.email ?? '';
      final updated = UserModel.fromJson({...profile, 'email': email});
      _authCtrl.currentUser.value = updated;
      await LocalStorage.saveUserData(jsonEncode(updated.toJson()));

      Get.back();
      Get.snackbar(
        'Berhasil',
        'Profil berhasil diperbarui',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  final EditProfileController _ctrl = Get.put(EditProfileController());
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Obx(() {
                final user = authCtrl.currentUser.value;
                return Center(
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: user?.avatar != null
                        ? NetworkImage(user!.avatar!) as ImageProvider
                        : null,
                    child: user?.avatar == null
                        ? Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 28),

              TextFormField(
                controller: _ctrl.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ctrl.phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  hintText: 'Contoh: 08123456789',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _ctrl.isLoading.value
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _ctrl.save();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _ctrl.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan Perubahan'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
