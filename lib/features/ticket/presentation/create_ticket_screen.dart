import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import 'ticket_controller.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _priority = 'medium';
  String _category = 'IT';
  bool _loading = false;
  final List<File> _attachments = [];

  final List<String> _categories = [
    'IT',
    'Hardware',
    'Software',
    'Jaringan',
    'Email',
    'Akun',
    'Printer',
    'Lainnya',
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'v': 'low', 'l': 'Rendah', 'c': AppColors.success},
    {'v': 'medium', 'l': 'Sedang', 'c': AppColors.info},
    {'v': 'high', 'l': 'Tinggi', 'c': AppColors.warning},
    {'v': 'critical', 'l': 'Kritis', 'c': AppColors.error},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (picked != null) {
        setState(() => _attachments.add(File(picked.path)));
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memilih gambar',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _pickFile() async {
    // Untuk file non-gambar, gunakan file_picker atau langsung gallery multi-pick
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        setState(() {
          for (final f in picked) {
            _attachments.add(File(f.path));
          }
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memilih file',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final ctrl = Get.find<TicketController>();
      await ctrl.createTicketDirect(
        title: _titleCtrl.text.trim(),
        desc: _descCtrl.text.trim(),
        priority: _priority,
        category: _category,
        attachments: _attachments.isEmpty ? null : _attachments,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Tiket Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Tiket',
                  hintText: 'Deskripsikan masalah secara singkat',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Judul wajib diisi';
                  if (v.trim().length < 5) return 'Judul minimal 5 karakter';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Deskripsi
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Jelaskan masalah secara detail...',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Deskripsi wajib diisi';
                  }
                  if (v.trim().length < 10) {
                    return 'Deskripsi minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategori
              Text('Kategori', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories
                    .map(
                      (cat) => ChoiceChip(
                        label: Text(cat),
                        selected: _category == cat,
                        onSelected: (_) => setState(() => _category = cat),
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          color: _category == cat ? AppColors.primary : null,
                          fontWeight: _category == cat
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Prioritas
              Text('Prioritas', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final sel = _priority == p['v'];
                  final col = p['c'] as Color;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p['v']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              sel ? col.withOpacity(0.12) : AppColors.grey50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? col : AppColors.borderLight,
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.flag_rounded, size: 18, color: col),
                            const SizedBox(height: 4),
                            Text(
                              p['l'],
                              style: TextStyle(
                                fontSize: 11,
                                color: sel ? col : AppColors.grey500,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Lampiran ────────────────────────────────────────────────────
              Row(
                children: [
                  Text('Lampiran', style: AppTextStyles.labelMedium),
                  const SizedBox(width: 8),
                  Text(
                    '(opsional)',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.grey400),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showAttachmentPicker,
                    icon: const Icon(Icons.attach_file_rounded, size: 16),
                    label: const Text('Tambah'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _AttachmentThumb(
                      file: _attachments[i],
                      onRemove: () =>
                          setState(() => _attachments.removeAt(i)),
                    ),
                  ),
                ),
              ] else ...[
                GestureDetector(
                  onTap: _showAttachmentPicker,
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderLight,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            color: AppColors.grey400, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          'Tap untuk upload gambar / file',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.grey400),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // Tombol kirim
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_loading ? 'Mengirim...' : 'Kirim Tiket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Preview thumbnail lampiran ─────────────────────────────────────────────
class _AttachmentThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _AttachmentThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            file,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: AppColors.grey100,
              child: const Icon(Icons.insert_drive_file_outlined,
                  color: AppColors.grey400),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
