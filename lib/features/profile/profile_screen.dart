import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_widgets.dart';
import '../auth/presentation/auth_controller.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Get.toNamed(AppRoutes.editProfile),
          ),
        ],
      ),
      body: Obx(() {
        final user = ctrl.currentUser.value;
        if (user == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Avatar ───────────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryContainer,
                      backgroundImage: user.avatar != null
                          ? NetworkImage(user.avatar!)
                          : null,
                      child: user.avatar == null
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(user.name, style: AppTextStyles.headingSmall),
              const SizedBox(height: 4),
              _RoleBadge(role: user.role),
              const SizedBox(height: 24),

              // ── Info card ─────────────────────────────────────────────────
              _Card(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Username',
                    value: user.username,
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    const Divider(height: 1, indent: 56),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Telepon',
                      value: user.phone!,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // ── Settings card ─────────────────────────────────────────────
              _Card(
                children: [
                  // Dark mode — ROW MANUAL agar tidak overflow
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.dark_mode_outlined,
                          color: AppColors.grey500,
                          size: 20,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Tema Gelap',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        StatefulBuilder(
                          builder: (context, setLocal) => Switch(
                            value: Get.isDarkMode,
                            onChanged: (_) {
                              final newMode = Get.isDarkMode
                                  ? ThemeMode.light
                                  : ThemeMode.dark;
                              Get.changeThemeMode(newMode);
                              setLocal(() {}); // rebuild switch agar langsung update
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _NavRow(
                    icon: Icons.notifications_outlined,
                    label: 'Notifikasi',
                    onTap: () => Get.toNamed(AppRoutes.notifications),
                  ),
                  const Divider(height: 1, indent: 56),
                  _NavRow(
                    icon: Icons.history_rounded,
                    label: 'Riwayat Tiket',
                    onTap: () => Get.toNamed(AppRoutes.history),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Logout button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context, ctrl),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda yakin ingin keluar dari aplikasi?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey400),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.grey400,
                ),
              ),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.grey500, size: 20),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.grey400,
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    final isHelpdesk = role == 'helpdesk';
    final color = isAdmin
        ? AppColors.error
        : isHelpdesk
        ? AppColors.secondary
        : AppColors.primary;
    final label = isAdmin
        ? 'Admin'
        : isHelpdesk
        ? 'Helpdesk'
        : 'User';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: color),
      ),
    );
  }
}
