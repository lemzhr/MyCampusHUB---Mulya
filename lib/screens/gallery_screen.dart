import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_theme.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri Foto'),
        backgroundColor: AppTheme.galeriColor,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showAll = !_showAll),
            icon: Icon(
              _showAll ? Icons.person : Icons.people,
              color: Colors.white,
            ),
            label: Text(
              _showAll ? 'Saya' : 'Semua',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _showAll
            ? FirebaseFirestore.instance
                .collection('photos')
                .orderBy('createdAt', descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('photos')
                .where('uid', isEqualTo: currentUid)
                // Dihapus orderBy dari query agar tidak error Composite Index
                .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada foto',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload foto pertama Anda!',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // Sort manual client-side jika tidak showAll
          var photos = snapshot.data!.docs.toList();
          if (!_showAll) {
             photos.sort((a, b) {
                final da = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final db = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                if (da == null && db == null) return 0;
                if (da == null) return -1;
                if (db == null) return 1;
                return db.compareTo(da);
             });
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: photos.length,
            itemBuilder: (ctx, i) {
              final doc = photos[i];
              final data = doc.data() as Map<String, dynamic>;
              final url = data['url'] as String? ?? '';
              return GestureDetector(
                onTap: () => _openPhoto(context, doc.id, data),
                child: Hero(
                  tag: url,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (ctx, url, err) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openPhoto(BuildContext context, String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewScreen(docId: docId, data: data),
      ),
    );
  }
}

class _PhotoViewScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _PhotoViewScreen({required this.docId, required this.data});

  @override
  State<_PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<_PhotoViewScreen> {
  bool _isDeleting = false;

  Future<void> _deletePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: const Text('Apakah Anda yakin ingin menghapus foto ini secara permanen?'),
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

    setState(() => _isDeleting = true);
    try {
      final fileName = widget.data['fileName'] as String?;
      if (fileName != null && fileName.isNotEmpty) {
        await Supabase.instance.client.storage.from('mycampushub-storage').remove([fileName]);
      }
      await FirebaseFirestore.instance.collection('photos').doc(widget.docId).delete();
      if (mounted) {
         Navigator.pop(context); // Kembali setelah dihapus
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto berhasil dihapus')),
         );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
         );
         setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.data['url'] as String? ?? '';
    final desc = widget.data['description'] as String? ?? '';
    final isOwner = widget.data['uid'] == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
           if (isOwner)
             _isDeleting 
               ? const Padding(
                   padding: EdgeInsets.all(16.0),
                   child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2)),
                 )
               : IconButton(
                   icon: const Icon(Icons.delete, color: Colors.red),
                   onPressed: _deletePhoto,
                 ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Hero(
              tag: url,
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (ctx, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (ctx, url, err) =>
                      const Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
          ),
          if (desc.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.black87,
              child: Text(
                desc,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
