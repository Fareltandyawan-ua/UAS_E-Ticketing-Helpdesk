import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../data/auth_model.dart';
import '../../../core/network/supabase_service.dart';
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
      _clearLoginForm();
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
