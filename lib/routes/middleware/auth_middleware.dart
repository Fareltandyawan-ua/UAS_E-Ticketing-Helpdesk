import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/storage/secure_storage.dart';
import '../app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final isLoggedIn = _checkLogin();
    if (!isLoggedIn) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }

  bool _checkLogin() {
    // Synchronous check using cached value
    // Full async check is done in SplashScreen
    return true;
  }
}

class RoleMiddleware extends GetMiddleware {
  final List<String> allowedRoles;

  RoleMiddleware({required this.allowedRoles});

  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    // Role check can be done here
    // For now, relies on UI-level checks in AuthController
    return null;
  }
}
