import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _prodiController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _photoUrl;
  File? _newPhoto;
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _nimController.text = data['nim'] ?? '';
          _prodiController.text = data['prodi'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _photoUrl = data['photoUrl'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _nameController.text = user.displayName ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickProfilePhoto() async {
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
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.profilColor),
              title: const Text('Ambil Foto (Kamera)'),
              onTap: () async {
                Navigator.pop(ctx);
                final status = await Permission.camera.request();
                if (!mounted) return;
                if (status.isDenied || status.isPermanentlyDenied) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin kamera ditolak. Harap aktifkan di pengaturan.')));
                  if (status.isPermanentlyDenied) openAppSettings();
                  return;
                }
                final picker = ImagePicker();
                final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                if (img != null && mounted) setState(() => _newPhoto = File(img.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.profilColor),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (img != null) setState(() => _newPhoto = File(img.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? photoUrl = _photoUrl;

      if (_newPhoto != null) {
        final supabase = Supabase.instance.client;
        final fileName = 'profiles/${user.uid}/avatar.jpg';
        await supabase.storage.from('mycampushub-storage').upload(
          fileName,
          _newPhoto!,
          fileOptions: const FileOptions(upsert: true),
        );
        photoUrl = supabase.storage.from('mycampushub-storage').getPublicUrl(fileName);
        await user.updatePhotoURL(photoUrl);
      }

      await user.updateDisplayName(_nameController.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': _nameController.text.trim(),
        'nim': _nimController.text.trim(),
        'prodi': _prodiController.text.trim(),
        'phone': _phoneController.text.trim(),
        'photoUrl': photoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _photoUrl = photoUrl;
        _newPhoto = null;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _prodiController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _deleteProfilePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Foto Profil'),
        content: const Text('Apakah Anda yakin ingin menghapus foto profil?'),
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

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final supabase = Supabase.instance.client;
      final fileName = 'profiles/'+user.uid+'/avatar.jpg';
      await supabase.storage.from('mycampushub-storage').remove([fileName]);
      await user.updatePhotoURL('');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoUrl': FieldValue.delete(),
      });
      setState(() {
        _photoUrl = null;
        _newPhoto = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil dihapus! ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus foto: '), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppTheme.profilColor,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.profilColor,
                          AppTheme.profilColor.withValues(alpha: 0.7)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _pickProfilePhoto : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: _newPhoto != null
                                      ? Image.file(_newPhoto!,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover)
                                      : (_photoUrl?.isNotEmpty == true
                                          ? CachedNetworkImage(
                                              imageUrl: _photoUrl!,
                                              width: 110,
                                              height: 110,
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(Icons.person_rounded,
                                              size: 60,
                                              color: AppTheme.profilColor)),
                                ),
                              ),
                              if (_isEditing && _photoUrl?.isNotEmpty == true && _newPhoto == null)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: GestureDetector(
                                    onTap: _deleteProfilePhoto,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                    ),
                                  ),
                                ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        size: 18,
                                        color: AppTheme.profilColor),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _nameController.text.isEmpty
                              ? 'Nama Mahasiswa'
                              : _nameController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // Profile form
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildProfileField(
                          label: 'Nama Lengkap',
                          controller: _nameController,
                          icon: Icons.person_outline,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          label: 'NIM',
                          controller: _nimController,
                          icon: Icons.badge_outlined,
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          label: 'Program Studi',
                          controller: _prodiController,
                          icon: Icons.school_outlined,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          label: 'No. Telepon',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          label: 'Email',
                          controller: TextEditingController(
                              text: user?.email ?? ''),
                          icon: Icons.email_outlined,
                          enabled: false,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text('Keluar',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
    );
  }
}
