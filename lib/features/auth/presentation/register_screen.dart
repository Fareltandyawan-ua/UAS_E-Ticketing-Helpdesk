import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import 'auth_controller.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final AuthController _ctrl = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Akun Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daftar Akun', style: AppTextStyles.headingMedium),
                const SizedBox(height: 6),
                Text(
                  'Isi data diri Anda untuk membuat akun baru',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey500),
                ),
                const SizedBox(height: 28),

                CustomTextField(
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  controller: _ctrl.nameController,
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => Validators.minLength(v, 3, 'Nama'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Email',
                  hint: 'contoh@email.com',
                  controller: _ctrl.emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Username',
                  hint: 'Buat username unik',
                  controller: _ctrl.usernameController,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.username,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Password',
                  hint: 'Minimal 8 karakter',
                  controller: _ctrl.passwordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password',
                  controller: _ctrl.confirmPasswordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) => Validators.confirmPassword(
                      v, _ctrl.passwordController.text),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),

                // Error message
                Obx(() {
                  if (_ctrl.errorMessage.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _ctrl.errorMessage.value,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                Obx(() => CustomButton(
                      text: 'Daftar Sekarang',
                      isLoading: _ctrl.isLoading.value,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _ctrl.register();
                        }
                      },
                    )),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sudah punya akun?',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500)),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Masuk',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
