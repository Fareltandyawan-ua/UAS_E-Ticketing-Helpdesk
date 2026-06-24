import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import 'auth_controller.dart';

/// Screen untuk set password baru.
///
/// Dua mode penggunaan:
/// 1. **Ganti Password** (`isRecovery=false`, default) — user sudah login,
///    diakses dari Settings. Setelah sukses kembali ke Settings.
/// 2. **Recovery** (`isRecovery=true`) — diakses dari deep link email recovery.
///    Setelah sukses, user di-logout & diarahkan ke login.
///
/// Mode ditentukan via `Get.arguments` (`bool`) saat navigasi.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _ctrl = Get.find<AuthController>();
  late final bool _isRecovery;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _isRecovery = args is bool ? args : false;
    _ctrl.errorMessage.value = '';
    _ctrl.currentPasswordController.clear();
    _ctrl.newPasswordController.clear();
    _ctrl.confirmNewPasswordController.clear();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _ctrl.updatePassword(
      currentPassword:
          _isRecovery ? null : _ctrl.currentPasswordController.text,
      newPassword: _ctrl.newPasswordController.text,
      isRecovery: _isRecovery,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecovery ? 'Set Password Baru' : 'Ganti Password'),
        leading: _isRecovery
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Get.back(),
              ),
        automaticallyImplyLeading: !_isRecovery,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        size: 40, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isRecovery
                      ? 'Buat Password Baru'
                      : 'Ganti Password Anda',
                  style: AppTextStyles.headingMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _isRecovery
                      ? 'Masukkan password baru untuk akun Anda. Setelah berhasil, Anda perlu login ulang.'
                      : 'Pastikan password baru Anda kuat dan berbeda dari sebelumnya.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey500),
                ),
                const SizedBox(height: 28),

                // Field 'Password Saat Ini' hanya untuk mode ganti password.
                // Pada mode recovery, user tidak ingat password lama.
                if (!_isRecovery) ...[
                  CustomTextField(
                    label: 'Password Saat Ini',
                    hint: 'Masukkan password lama Anda',
                    controller: _ctrl.currentPasswordController,
                    prefixIcon: Icons.lock_open_rounded,
                    isPassword: true,
                    validator: Validators.password,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                ],

                CustomTextField(
                  label: 'Password Baru',
                  hint: 'Minimal 8 karakter',
                  controller: _ctrl.newPasswordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password baru',
                  controller: _ctrl.confirmNewPasswordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) => Validators.confirmPassword(
                      v, _ctrl.newPasswordController.text),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),

                Obx(() {
                  if (_ctrl.errorMessage.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _ctrl.errorMessage.value,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                Obx(() => CustomButton(
                      text: _isRecovery
                          ? 'Simpan & Login Ulang'
                          : 'Simpan Password',
                      icon: Icons.check_rounded,
                      isLoading: _ctrl.isLoading.value,
                      onPressed: _submit,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
