import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/app_theme.dart';

class UploadFotoScreen extends StatefulWidget {
  const UploadFotoScreen({super.key});

  @override
  State<UploadFotoScreen> createState() => _UploadFotoScreenState();
}

class _UploadFotoScreenState extends State<UploadFotoScreen> {
  File? _selectedImage;
  bool _isUploading = false;
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        _showSnackBar('Izin kamera ditolak. Harap aktifkan di pengaturan.', isError: true);
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
        return;
      }
    }
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) {
      _showSnackBar('Pilih foto terlebih dahulu!', isError: true);
      return;
    }
    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final fileName =
          'photos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final supabase = Supabase.instance.client;
      await supabase.storage.from('mycampushub-storage').upload(
        fileName,
        _selectedImage!,
        fileOptions: const FileOptions(upsert: true),
      );

      final downloadUrl = supabase.storage.from('mycampushub-storage').getPublicUrl(fileName);

      // Save to Firestore
      await FirebaseFirestore.instance.collection('photos').add({
        'uid': user.uid,
        'url': downloadUrl,
        'description': _descController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'fileName': fileName,
      });

      _showSnackBar('Foto berhasil diupload! 🎉');
      setState(() {
        _selectedImage = null;
        _descController.clear();
      });
    } catch (e) {
      _showSnackBar('Upload gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Foto'),
        backgroundColor: AppTheme.uploadFotoColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image preview
            GestureDetector(
              onTap: () => _showPickerOptions(),
              child: Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.uploadFotoColor.withValues(alpha: 0.4),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 70,
                            color: AppTheme.uploadFotoColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ketuk untuk memilih foto',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Kamera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.uploadFotoColor,
                      side: BorderSide(color: AppTheme.uploadFotoColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.uploadFotoColor,
                      side: BorderSide(color: AppTheme.uploadFotoColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Deskripsi foto (opsional)',
                hintText: 'Tambahkan deskripsi...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Upload progress
            if (_isUploading) ...[
              LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.uploadFotoColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Mengupload...',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadPhoto,
                icon: const Icon(Icons.cloud_upload_rounded),
                label: Text(
                    _isUploading ? 'Mengupload...' : 'Upload Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.uploadFotoColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppTheme.uploadFotoColor),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppTheme.uploadFotoColor),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
