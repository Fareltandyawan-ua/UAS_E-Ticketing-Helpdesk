import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/data/auth_model.dart';
import 'admin_controller.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pastikan controller tersedia (bisa dipanggil baik via route maupun tab)
    final ctrl = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: ctrl.fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats Header ────────────────────────────────────────────────
          Obx(() {
            final stats = ctrl.userStats;
            if (stats.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _StatChip(
                    label: 'Total',
                    value: '${stats['total'] ?? 0}',
                    icon: Icons.people_rounded,
                  ),
                  _StatChip(
                    label: 'User',
                    value: '${stats['user'] ?? 0}',
                    icon: Icons.person_rounded,
                  ),
                  _StatChip(
                    label: 'Helpdesk',
                    value: '${stats['helpdesk'] ?? 0}',
                    icon: Icons.support_agent_rounded,
                  ),
                  _StatChip(
                    label: 'Admin',
                    value: '${stats['admin'] ?? 0}',
                    icon: Icons.admin_panel_settings_rounded,
                  ),
                  _StatChip(
                    label: 'Nonaktif',
                    value: '${stats['inactive'] ?? 0}',
                    icon: Icons.block_rounded,
                  ),
                ],
              ),
            );
          }),

          // ── Search Bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => ctrl.searchQuery.value = v,
              decoration: const InputDecoration(
                hintText: 'Cari nama, email, atau username...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // ── User List ──────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = ctrl.filteredUsers;
              if (list.isEmpty) {
                return const EmptyState(
                  title: 'Tidak ada user',
                  icon: Icons.people_outline,
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.fetchUsers,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _UserCard(
                    user: list[i],
                    onRoleChange: (newRole) =>
                        ctrl.updateRole(list[i].id, newRole),
                    onToggleActive: (active) =>
                        ctrl.toggleActive(list[i].id, active),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── User Card ─────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  final void Function(String) onRoleChange;
  final void Function(bool) onToggleActive;

  const _UserCard({
    required this.user,
    required this.onRoleChange,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final roleConfig = _getRoleConfig(user.role);
    final isInactive = !user.isActive;

    return Opacity(
      opacity: isInactive ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInactive
                ? AppColors.error.withOpacity(0.4)
                : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: roleConfig['bg'] as Color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                roleConfig['icon'] as IconData,
                color: roleConfig['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              (roleConfig['bg'] as Color).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _roleLabel(user.role),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: roleConfig['color'] as Color,
                          ),
                        ),
                      ),
                      if (isInactive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Nonaktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Menu aksi
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.grey500),
              tooltip: 'Aksi',
              itemBuilder: (_) => [
                if (user.role != 'user')
                  _menuItem(
                      'role:user', Icons.person_rounded, 'Jadikan User'),
                if (user.role != 'helpdesk')
                  _menuItem('role:helpdesk', Icons.support_agent_rounded,
                      'Jadikan Helpdesk'),
                if (user.role != 'admin')
                  _menuItem('role:admin',
                      Icons.admin_panel_settings_rounded, 'Jadikan Admin'),
                const PopupMenuDivider(),
                if (user.isActive)
                  _menuItem(
                    'deactivate',
                    Icons.block_rounded,
                    'Nonaktifkan Akun',
                    color: AppColors.error,
                  )
                else
                  _menuItem(
                    'activate',
                    Icons.check_circle_outline_rounded,
                    'Aktifkan Akun',
                    color: AppColors.success,
                  ),
              ],
              onSelected: (value) {
                if (value.startsWith('role:')) {
                  onRoleChange(value.substring(5));
                } else if (value == 'deactivate') {
                  onToggleActive(false);
                } else if (value == 'activate') {
                  onToggleActive(true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label,
      {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.grey600),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Map<String, dynamic> _getRoleConfig(String role) {
    switch (role) {
      case 'admin':
        return {
          'color': const Color(0xFF7B1FA2),
          'bg': const Color(0xFFF3E5F5),
          'icon': Icons.admin_panel_settings_rounded,
        };
      case 'helpdesk':
        return {
          'color': AppColors.primary,
          'bg': AppColors.primaryContainer,
          'icon': Icons.support_agent_rounded,
        };
      default:
        return {
          'color': AppColors.grey600,
          'bg': AppColors.grey100,
          'icon': Icons.person_rounded,
        };
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':    return 'Admin';
      case 'helpdesk': return 'Helpdesk';
      default:         return 'User';
    }
  }
}

// ── Stat chip di header ───────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
