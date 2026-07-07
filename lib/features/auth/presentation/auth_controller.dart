import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../../core/services/activity_logger.dart';
import '../../../routes/app_routes.dart';
import '../data/auth_model.dart'; // re-exports User entity & UserModel
import '../domain/auth_exceptions.dart';
import '../domain/usecases/get_cached_user_usecase.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/logout_usecase.dart';
import '../domain/usecases/refresh_profile_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/send_password_reset_email_usecase.dart';
import '../domain/usecases/update_password_usecase.dart';

/// AuthController — UI orchestrator untuk fitur auth.
///
/// Setelah refactor Clean Architecture, controller TIDAK lagi memanggil
/// Supabase langsung. Semua operasi business lewat use cases yang
/// di-inject via constructor.
///
/// Tanggung jawab controller:
/// - State UI (loading, error, currentUser)
/// - Form controllers
/// - Panggil use case + handle exception → tampilkan snackbar/dialog
/// - Navigasi setelah aksi sukses
/// - Activity logging (cross-cutting concern di layer presentation)
class AuthController extends GetxController {
  // ── Dependencies (injected via DI) ────────────────────────────────
  final LoginUseCase _loginUC;
  final RegisterUseCase _registerUC;
  final LogoutUseCase _logoutUC;
  final SendPasswordResetEmailUseCase _resetEmailUC;
  final UpdatePasswordUseCase _updatePasswordUC;
  final RefreshProfileUseCase _refreshProfileUC;
  final GetCachedUserUseCase _getCachedUserUC;

  AuthController({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase,
    required UpdatePasswordUseCase updatePasswordUseCase,
    required RefreshProfileUseCase refreshProfileUseCase,
    required GetCachedUserUseCase getCachedUserUseCase,
  })  : _loginUC = loginUseCase,
        _registerUC = registerUseCase,
        _logoutUC = logoutUseCase,
        _resetEmailUC = sendPasswordResetEmailUseCase,
        _updatePasswordUC = updatePasswordUseCase,
        _refreshProfileUC = refreshProfileUseCase,
        _getCachedUserUC = getCachedUserUseCase;

  // ── State ─────────────────────────────────────────────────────────
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // ── Form controllers ──────────────────────────────────────────────
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final resetEmailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  // ── Computed ──────────────────────────────────────────────────────
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
    final user = await _getCachedUserUC();
    if (user != null) {
      currentUser.value = UserModel.fromEntity(user);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────

  Future<void> login() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _loginUC(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      currentUser.value = UserModel.fromEntity(user);
      _clearLoginForm();

      unawaited(ActivityLogger.log(
        type: ActivityType.login,
        description: 'Login berhasil sebagai ${user.role}',
      ));

      Get.offAllNamed(AppRoutes.main);
    } on AccountDeactivatedException catch (e) {
      errorMessage.value = e.message;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Terjadi kesalahan. Coba lagi.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _registerUC(
        email: emailController.text.trim(),
        password: passwordController.text,
        name: nameController.text.trim(),
        username: usernameController.text.trim(),
      );
      currentUser.value = UserModel.fromEntity(user);
      _clearRegisterForm();

      unawaited(ActivityLogger.log(
        type: ActivityType.register,
        description: 'Akun baru dibuat: ${user.email}',
      ));

      Get.offAllNamed(AppRoutes.main);
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Terjadi kesalahan. Coba lagi.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // Log sebelum signOut supaya masih authenticated
      await ActivityLogger.log(
        type: ActivityType.logout,
        description: 'Logout dari aplikasi',
      );

      await _logoutUC();
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
      await _resetEmailUC(resetEmailController.text.trim());
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

  Future<void> updatePassword({
    String? currentPassword,
    required String newPassword,
    bool isRecovery = false,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _updatePasswordUC(
        currentPassword: currentPassword,
        newPassword: newPassword,
        isRecovery: isRecovery,
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmNewPasswordController.clear();

      await ActivityLogger.log(
        type: ActivityType.passwordChanged,
        description: isRecovery
            ? 'Password direset via email recovery'
            : 'Password diubah dari menu Pengaturan',
      );

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
        await _logoutUC();
        currentUser.value = null;
        Get.offAllNamed(AppRoutes.login);
      } else {
        Get.back();
      }
    } on WrongCurrentPasswordException catch (e) {
      errorMessage.value = e.message;
    } on SamePasswordException catch (e) {
      errorMessage.value = e.message;
    } on InvalidSessionException catch (e) {
      errorMessage.value = e.message;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Terjadi kesalahan. Coba lagi.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    final user = await _refreshProfileUC();
    if (user != null) currentUser.value = UserModel.fromEntity(user);
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
