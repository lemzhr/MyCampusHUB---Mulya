import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';

class AdminVideoScreen extends StatelessWidget {
  const AdminVideoScreen({super.key});

  void _addVideoDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final thumbCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Video'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul')),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL Video (YouTube)')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi')),
              TextField(controller: thumbCtrl, decoration: const InputDecoration(labelText: 'URL Thumbnail (Opsional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                await FirebaseService.addVideo(
                  title: titleCtrl.text.trim(),
                  videoUrl: urlCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  thumbnailUrl: thumbCtrl.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Video'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addVideoDialog(context),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.getVideos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada video.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? ''),
                subtitle: Text(data['videoUrl'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseService.deleteVideo(docs[index].id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
