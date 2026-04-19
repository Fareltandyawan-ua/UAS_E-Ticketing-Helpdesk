import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerHelper {
  FilePickerHelper._();

  static final ImagePicker _imagePicker = ImagePicker();

  static Future<File?> pickImageFromGallery() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (picked != null) return File(picked.path);
    return null;
  }

  static Future<File?> pickImageFromCamera() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (picked != null) return File(picked.path);
    return null;
  }

  static Future<List<File>> pickMultipleImages() async {
    final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: 80,
    );
    return pickedFiles.map((f) => File(f.path)).toList();
  }

  static Future<File?> pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  static Future<List<File>> pickMultipleFiles() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      return result.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();
    }
    return [];
  }

  static Future<File?> showPickerDialog(BuildContext context) async {
    File? selected;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Lampiran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () async {
                Navigator.pop(context);
                selected = await pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () async {
                Navigator.pop(context);
                selected = await pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('File'),
              onTap: () async {
                Navigator.pop(context);
                selected = await pickFile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    return selected;
  }

  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String getFileName(File file) {
    return file.path.split('/').last;
  }

  static bool isImage(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }
}
