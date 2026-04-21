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
              child: Row(
                children: [
                  _StatChip(
                    label: 'Total',
                    value: '${stats['total'] ?? 0}',
                    icon: Icons.people_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'User',
                    value: '${stats['user'] ?? 0}',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Helpdesk',
                    value: '${stats['helpdesk'] ?? 0}',
                    icon: Icons.support_agent_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Admin',
                    value: '${stats['admin'] ?? 0}',
                    icon: Icons.admin_panel_settings_rounded,
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

  const _UserCard({required this.user, required this.onRoleChange});

  @override
  Widget build(BuildContext context) {
    final roleConfig = _getRoleConfig(user.role);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
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
                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (roleConfig['bg'] as Color).withOpacity(0.7),
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
              ],
            ),
          ),

          // Change role button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey500),
            tooltip: 'Ubah role',
            itemBuilder: (_) => [
              if (user.role != 'user')
                _roleMenuItem('user', Icons.person_rounded, 'Jadikan User'),
              if (user.role != 'helpdesk')
                _roleMenuItem('helpdesk', Icons.support_agent_rounded,
                    'Jadikan Helpdesk'),
              if (user.role != 'admin')
                _roleMenuItem('admin', Icons.admin_panel_settings_rounded,
                    'Jadikan Admin'),
            ],
            onSelected: onRoleChange,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _roleMenuItem(
      String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.grey600),
          const SizedBox(width: 12),
          Text(label),
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
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
