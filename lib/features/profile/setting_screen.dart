import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../routes/app_routes.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final saved = await LocalStorage.getThemeMode();
    setState(() {
      _themeMode = saved == 'dark'
          ? ThemeMode.dark
          : saved == 'light'
          ? ThemeMode.light
          : ThemeMode.system;
      _loading = false;
    });
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    Get.changeThemeMode(mode);
    final value = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light
        ? 'light'
        : 'system';
    await LocalStorage.saveThemeMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionTitle(title: 'Tampilan'),
                const SizedBox(height: 8),
                _Card(
                  children: [
                    _ThemeOption(
                      icon: Icons.brightness_auto_rounded,
                      label: 'Ikuti Sistem',
                      selected: _themeMode == ThemeMode.system,
                      onTap: () => _changeTheme(ThemeMode.system),
                    ),
                    const Divider(height: 1, indent: 56),
                    _ThemeOption(
                      icon: Icons.light_mode_rounded,
                      label: 'Tema Terang',
                      selected: _themeMode == ThemeMode.light,
                      onTap: () => _changeTheme(ThemeMode.light),
                    ),
                    const Divider(height: 1, indent: 56),
                    _ThemeOption(
                      icon: Icons.dark_mode_rounded,
                      label: 'Tema Gelap',
                      selected: _themeMode == ThemeMode.dark,
                      onTap: () => _changeTheme(ThemeMode.dark),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _SectionTitle(title: 'Akun'),
                const SizedBox(height: 8),
                _Card(
                  children: [
                    _NavRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Ganti Password',
                      onTap: () => Get.toNamed(AppRoutes.resetPassword),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _SectionTitle(title: 'Notifikasi'),
                const SizedBox(height: 8),
                _Card(
                  children: [
                    _NavRow(
                      icon: Icons.notifications_outlined,
                      label: 'Daftar Notifikasi',
                      onTap: () => Get.toNamed(AppRoutes.notifications),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _SectionTitle(title: 'Riwayat'),
                const SizedBox(height: 8),
                _Card(
                  children: [
                    _NavRow(
                      icon: Icons.history_rounded,
                      label: 'Riwayat Tiket',
                      onTap: () => Get.toNamed(AppRoutes.history),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _SectionTitle(title: 'Tentang'),
                const SizedBox(height: 8),
                _Card(
                  children: [
                    _InfoRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Versi Aplikasi',
                      value: '2.0.0',
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoRow(
                      icon: Icons.apps_rounded,
                      label: 'Nama Aplikasi',
                      value: 'E-Ticketing Helpdesk',
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.grey500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: AppColors.grey500),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 20,
            )
          : const Icon(
              Icons.radio_button_unchecked_rounded,
              color: AppColors.grey300,
              size: 20,
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
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}
