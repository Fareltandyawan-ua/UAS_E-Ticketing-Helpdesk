import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, UserAttributes;
import '../data/auth_model.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/services/activity_logger.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/local_storage.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Form controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final resetEmailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  bool get isLoggedIn => currentUser.value != null;
  bool get isAdmin => currentUser.value?.isAdmin ?? false;
  bool get isHelpdesk => currentUser.value?.isHelpdesk ?? false;

  @override
  void onInit() {
    super.onInit();
    _loadUserFromStorage();
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    nameController.dispose();
    emailController.dispose();
    confirmPasswordController.dispose();
    resetEmailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.onClose();
  }

  Future<void> _loadUserFromStorage() async {
    final userData = await LocalStorage.getUserData();
    if (userData != null) {
      currentUser.value = UserModel.fromJson(jsonDecode(userData));
    }
  }

  Future<void> login() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.user == null) {
        errorMessage.value = 'Login gagal. Pastikan email dan password benar.';
        return;
      }

      final profile = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      final user = UserModel.fromJson({
        ...profile,
        'email': response.user!.email ?? '',
      });

      // Cek akun aktif — blokir login jika akun dinonaktifkan admin
      if (!user.isActive) {
        await SupabaseService.client.auth.signOut();
        errorMessage.value =
            'Akun Anda telah dinonaktifkan. Hubungi admin untuk informasi lebih lanjut.';
        return;
      }

      currentUser.value = user;

      final session = response.session;
      if (session != null) {
        await SecureStorage.saveToken(session.accessToken);
        await SecureStorage.saveRefreshToken(session.refreshToken ?? '');
      }
      await SecureStorage.saveUserId(response.user!.id);
      await SecureStorage.saveUserRole(currentUser.value!.role);

      await LocalStorage.saveUserData(jsonEncode(currentUser.value!.toJson()));
      _clearLoginForm();

      // Log aktivitas login (BR-005)
      unawaited(ActivityLogger.log(
        type: ActivityType.login,
        description: 'Login berhasil sebagai ${currentUser.value!.role}',
      ));

      Get.offAllNamed(AppRoutes.main);
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan. Coba lagi.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await SupabaseService.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {
          'name': nameController.text.trim(),
          'username': usernameController.text.trim(),
          'role': 'user',
        },
      );

      if (response.user == null) {
        errorMessage.value =
            'Registrasi berhasil, silakan cek email untuk verifikasi akun.';
        return;
      }

      // Profile dibuat oleh SQL trigger, beri jeda agar row siap diambil.
      await Future.delayed(const Duration(seconds: 1));
      final profile = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      currentUser.value = UserModel.fromJson({
        ...profile,
        'email': response.user!.email ?? '',
      });

      final session = response.session;
      if (session != null) {
        await SecureStorage.saveToken(session.accessToken);
        await SecureStorage.saveRefreshToken(session.refreshToken ?? '');
      }
      await SecureStorage.saveUserId(response.user!.id);
      await SecureStorage.saveUserRole(currentUser.value!.role);

      await LocalStorage.saveUserData(jsonEncode(currentUser.value!.toJson()));
      _clearRegisterForm();

      // Log aktivitas registrasi (BR-005)
      unawaited(ActivityLogger.log(
        type: ActivityType.register,
        description: 'Akun baru dibuat: ${currentUser.value!.email}',
      ));

      Get.offAllNamed(AppRoutes.main);
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan. Coba lagi.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // Log dulu sebelum signOut (BR-005) supaya masih authenticated saat insert
      await ActivityLogger.log(
        type: ActivityType.logout,
        description: 'Logout dari aplikasi',
      );

      await SupabaseService.client.auth.signOut();
      await SecureStorage.clearAll();
      await LocalStorage.clearUserData();
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.login);
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Terjadi kesalahan. Coba lagi.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(
        resetEmailController.text.trim(),
      );
      Get.back();
      Get.snackbar(
        'Berhasil',
        'Link reset password telah dikirim ke email Anda',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Terjadi kesalahan. Coba lagi.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Ubah password user yang sedang aktif.
  ///
  /// Mode penggunaan:
  /// - **Ganti password** (`isRecovery=false`): wajib isi [currentPassword],
  ///   akan diverifikasi via re-login. Dipanggil dari Settings.
  /// - **Recovery** (`isRecovery=true`): tidak perlu [currentPassword].
  ///   Session sudah diset via deep link dari email. Setelah sukses, user
  ///   di-logout & diarahkan ke login.
  Future<void> updatePassword({
    String? currentPassword,
    required String newPassword,
    bool isRecovery = false,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // Untuk mode ganti password biasa, verifikasi password lama dulu
      if (!isRecovery) {
        if (currentPassword == null || currentPassword.isEmpty) {
          errorMessage.value = 'Password saat ini wajib diisi';
          return;
        }
        final email =
            SupabaseService.client.auth.currentUser?.email ?? '';
        if (email.isEmpty) {
          errorMessage.value = 'Sesi tidak valid. Silakan login ulang.';
          return;
        }
        try {
          await SupabaseService.client.auth.signInWithPassword(
            email: email,
            password: currentPassword,
          );
        } on AuthException catch (_) {
          errorMessage.value = 'Password saat ini salah';
          return;
        }
        if (currentPassword == newPassword) {
          errorMessage.value =
              'Password baru harus berbeda dengan password saat ini';
          return;
        }
      }

      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmNewPasswordController.clear();

      // Log aktivitas ganti password (BR-005) — sebelum potensi logout di recovery
      await ActivityLogger.log(
        type: ActivityType.passwordChanged,
        description: isRecovery
            ? 'Password direset via email recovery'
            : 'Password diubah dari menu Pengaturan',
      );

      // Tampilkan dialog sukses — wajib di-tap OK biar user yakin berhasil
      await Get.dialog(
        AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF059669), size: 28),
              SizedBox(width: 12),
              Text('Berhasil'),
            ],
          ),
          content: Text(
            isRecovery
                ? 'Password Anda berhasil diperbarui. Silakan login kembali menggunakan password baru.'
                : 'Password Anda berhasil diperbarui. Gunakan password baru saat login berikutnya.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (isRecovery) {
        // Setelah recovery, paksa logout & login ulang dengan password baru
        await SupabaseService.client.auth.signOut();
        await SecureStorage.clearAll();
        await LocalStorage.clearUserData();
        currentUser.value = null;
        Get.offAllNamed(AppRoutes.login);
      } else {
        Get.back();
      }
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Terjadi kesalahan. Coba lagi.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final authUser = SupabaseService.client.auth.currentUser;
      if (authUser == null) return;

      final profile = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .single();

      final user = UserModel.fromJson({
        ...profile,
        'email': authUser.email ?? '',
      });
      currentUser.value = user;
      await LocalStorage.saveUserData(jsonEncode(user.toJson()));
    } catch (_) {}
  }

  void _clearLoginForm() {
    emailController.clear();
    passwordController.clear();
  }

  void _clearRegisterForm() {
    nameController.clear();
    emailController.clear();
    usernameController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }
}
