import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firebase_service.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  void _addNewsDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    
    File? selectedImage;
    DateTime selectedDate = DateTime.now();
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Tambah Berita'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul')),
                  TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Konten'), maxLines: 3),
                  TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Kategori')),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: const Text('Pilih Tanggal'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selectedImage != null)
                    Image.file(selectedImage!, height: 100, fit: BoxFit.cover),
                  TextButton.icon(
                    onPressed: isUploading ? null : () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setStateDialog(() {
                          selectedImage = File(pickedFile.path);
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Pilih Gambar (Opsional)'),
                  ),
                  if (isUploading) const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context), 
                child: const Text('Batal')
              ),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty || categoryCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Judul, konten, dan kategori tidak boleh kosong!'))
                    );
                    return;
                  }

                  setStateDialog(() => isUploading = true);

                  try {
                    String imageUrl = '';
                    String imageStoragePath = '';

                    if (selectedImage != null) {
                      final fileName = 'news_${DateTime.now().millisecondsSinceEpoch}.jpg';
                      imageStoragePath = 'news/\$fileName';
                      imageUrl = await FirebaseService.uploadFile(
                        file: selectedImage!,
                        storagePath: imageStoragePath,
                      );
                    }

                    await FirebaseService.addNews(
                      title: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      category: categoryCtrl.text.trim(),
                      imageUrl: imageUrl,
                      imageStoragePath: imageStoragePath,
                      publishedDate: selectedDate,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    setStateDialog(() => isUploading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal: \$e'))
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Berita'),
        content: const Text('Apakah Anda yakin ingin menghapus berita ini beserta gambarnya?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseService.deleteNews(docId);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: \$e'))
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Berita'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewsDialog(context),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.getNews(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada berita.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final imageUrl = data['imageUrl'] as String?;
              
              String dateStr = '';
              if (data['publishedDate'] != null) {
                final date = (data['publishedDate'] as Timestamp).toDate();
                dateStr = '${date.day}/${date.month}/${date.year}';
              } else if (data['createdAt'] != null) {
                final date = (data['createdAt'] as Timestamp).toDate();
                dateStr = '${date.day}/${date.month}/${date.year}';
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                      ),
                    ListTile(
                      title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${data['category'] ?? ''} • $dateStr"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, docs[index].id),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
