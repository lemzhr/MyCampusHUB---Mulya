import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';

class AdminKtmScreen extends StatelessWidget {
  const AdminKtmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi KTM Mahasiswa'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.getAllKTMs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data KTM yang diupload.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final verified = data['verified'] == true;
              final status = (data['status'] as String?) ?? (verified ? 'approved' : 'pending');
              final userName = data['userName'] as String?;
              final nim = data['nim'] as String?;
              final uid = data['uid'] ?? doc.id;
              final url = data['url'] ?? '';

              Color statusColor;
              String statusLabel;
              IconData statusIcon;

              if (status == 'approved' || status == 'verified' || verified) {
                statusColor = Colors.green;
                statusLabel = 'Terverifikasi';
                statusIcon = Icons.verified;
              } else if (status == 'rejected') {
                statusColor = Colors.red;
                statusLabel = 'Ditolak';
                statusIcon = Icons.cancel;
              } else {
                statusColor = Colors.orange;
                statusLabel = 'Menunggu Verifikasi';
                statusIcon = Icons.hourglass_top;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (url.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              child: InteractiveViewer(
                                child: Image.network(url, fit: BoxFit.contain),
                              ),
                            ),
                          );
                        },
                        child: Image.network(
                          url,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  userName != null && userName.isNotEmpty
                                      ? userName
                                      : 'Mahasiswa (UID: ${uid.substring(0, uid.length > 8 ? 8 : uid.length)}...)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 14, color: statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (nim != null && nim.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'NIM: $nim',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            'UID: $uid',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: status == 'approved'
                                      ? null
                                      : () async {
                                          await FirebaseService.verifyKTM(doc.id, 'approved');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('KTM disetujui & terverifikasi! ✅'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('Setujui'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: status == 'rejected'
                                      ? null
                                      : () async {
                                          await FirebaseService.verifyKTM(doc.id, 'rejected');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('KTM ditolak ❌'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                                  label: const Text('Tolak', style: TextStyle(color: Colors.red)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                tooltip: 'Pilihan Lain',
                                onSelected: (val) async {
                                  await FirebaseService.verifyKTM(doc.id, val);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'pending',
                                    child: Text('Reset ke Pending (Menunggu)'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
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
