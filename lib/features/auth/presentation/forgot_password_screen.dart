import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import 'auth_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final AuthController _ctrl = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.lock_reset_rounded,
                        size: 40, color: AppColors.warning),
                  ),
                ),
                const SizedBox(height: 28),
                Text('Lupa Password?', style: AppTextStyles.headingMedium),
                const SizedBox(height: 8),
                Text(
                  'Masukkan email terdaftar Anda. Kami akan mengirimkan link untuk reset password.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey500),
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  label: 'Email',
                  hint: 'contoh@email.com',
                  controller: _ctrl.resetEmailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),

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
                    child: Text(_ctrl.errorMessage.value,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                  );
                }),

                const SizedBox(height: 8),
                Obx(() => CustomButton(
                      text: 'Kirim Link Reset',
                      isLoading: _ctrl.isLoading.value,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _ctrl.resetPassword();
                        }
                      },
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
