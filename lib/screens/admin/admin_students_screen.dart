import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';

class AdminStudentsScreen extends StatelessWidget {
  const AdminStudentsScreen({super.key});

  void _addStudentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final nimCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final uidCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Mahasiswa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: uidCtrl, decoration: const InputDecoration(labelText: 'UID (Manual)')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama')),
              TextField(controller: nimCtrl, decoration: const InputDecoration(labelText: 'NIM')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (uidCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                await FirebaseService.addStudentData(
                  uid: uidCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                  nim: nimCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
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
      appBar: AppBar(title: const Text('Kelola Mahasiswa'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addStudentDialog(context),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.getAllStudents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada mahasiswa.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text('${data['nim'] ?? ''} - ${data['email'] ?? ''}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseService.deleteStudentData(docs[index].id);
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
