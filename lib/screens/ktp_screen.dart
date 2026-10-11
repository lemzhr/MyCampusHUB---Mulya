import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../utils/app_theme.dart';
import '../services/firebase_service.dart';

class KTPScreen extends StatefulWidget {
  const KTPScreen({super.key});

  @override
  State<KTPScreen> createState() => _KTPScreenState();
}

class _KTPScreenState extends State<KTPScreen> {
  File? _ktpFile;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickKTP() async {
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
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.uploadKTPColor),
              title: const Text('Foto KTP dengan Kamera'),
              onTap: () async {
                Navigator.pop(ctx);
                final status = await Permission.camera.request();
                if (!mounted) return;
                if (status.isDenied || status.isPermanentlyDenied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Izin kamera ditolak. Harap aktifkan di pengaturan.')),
                  );
                  if (status.isPermanentlyDenied) openAppSettings();
                  return;
                }
                final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
                if (img != null && mounted) setState(() => _ktpFile = File(img.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.uploadKTPColor),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
                if (img != null && mounted) setState(() => _ktpFile = File(img.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadKTP() async {
    if (_ktpFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto KTP terlebih dahulu!')),
      );
      return;
    }
    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final supabase = Supabase.instance.client;
      final fileName = 'ktp/${user.uid}/ktp.jpg';
      await supabase.storage.from('mycampushub-storage').upload(
        fileName,
        _ktpFile!,
        fileOptions: const FileOptions(upsert: true),
      );

      final url = supabase.storage.from('mycampushub-storage').getPublicUrl(fileName);

      // Get user name and nim for metadata
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? user.displayName ?? '';
      final nim = userDoc.data()?['nim'] ?? '';

      await FirebaseService.saveKTP(
        user.uid,
        url,
        userName: userName,
        nim: nim,
      );

      if (mounted) {
        setState(() => _ktpFile = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KTP berhasil diupload! Menunggu verifikasi admin. ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteKTP() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus KTP'),
        content: const Text('Apakah Anda yakin ingin menghapus foto KTP secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final supabase = Supabase.instance.client;
      final fileName = 'ktp/${user.uid}/ktp.jpg';
      await supabase.storage.from('mycampushub-storage').remove([fileName]);
      await FirebaseFirestore.instance.collection('ktp').doc(user.uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KTP berhasil dihapus! ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus KTP: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildStatusBanner(String status, bool verified) {
    final isApproved = status == 'approved' || status == 'verified' || verified;
    final isRejected = status == 'rejected';

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String description;

    if (isApproved) {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade400;
      textColor = Colors.green.shade800;
      icon = Icons.verified_rounded;
      title = 'KTP Terverifikasi ✅';
      description = 'KTP Anda telah berhasil diverifikasi oleh admin.';
    } else if (isRejected) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade400;
      textColor = Colors.red.shade800;
      icon = Icons.cancel_rounded;
      title = 'Verifikasi KTP Ditolak ❌';
      description = 'KTP Anda belum memenuhi persyaratan atau ditolak oleh admin. Silakan upload ulang foto KTP yang jelas.';
    } else {
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade400;
      textColor = Colors.orange.shade800;
      icon = Icons.hourglass_top_rounded;
      title = 'Menunggu Verifikasi ⏳';
      description = 'Foto KTP Anda sudah tersimpan dan sedang dalam proses peninjauan oleh admin.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upload KTP'),
          backgroundColor: AppTheme.uploadKTPColor,
        ),
        body: const Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload KTP'),
        backgroundColor: AppTheme.uploadKTPColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService.streamKTP(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final existingUrl = data?['url'] as String?;
          final verified = data?['verified'] == true;
          final status = (data?['status'] as String?) ?? (verified ? 'approved' : 'pending');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real-time verification status banner
                if (existingUrl != null) ...[
                  _buildStatusBanner(status, verified),
                  const SizedBox(height: 20),
                ] else ...[
                  // Info card when not uploaded yet
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Upload foto KTP Anda yang jelas dan terbaca. '
                            'Data KTP akan diverifikasi oleh admin.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Existing KTP Card
                if (existingUrl != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'KTP Tersimpan:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isUploading ? null : _deleteKTP,
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: existingUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Perbarui KTP:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // New file preview / picker
                GestureDetector(
                  onTap: _pickKTP,
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.uploadKTPColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: _ktpFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_ktpFile!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.credit_card_rounded,
                                size: 60,
                                color: AppTheme.uploadKTPColor.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Ketuk untuk memilih foto KTP',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_isUploading) ...[
                  LinearProgressIndicator(
                    color: AppTheme.uploadKTPColor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mengupload...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadKTP,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(_isUploading ? 'Mengupload...' : 'Upload KTP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.uploadKTPColor,
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
          );
        },
      ),
    );
  }
}
