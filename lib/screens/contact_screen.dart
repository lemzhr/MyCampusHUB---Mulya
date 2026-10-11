import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontak Person'),
        backgroundColor: AppTheme.kontakColor,
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            color: AppTheme.kontakColor.withValues(alpha: 0.1),
            child: Column(
              children: [
                const Icon(
                  Icons.contact_phone_rounded,
                  size: 50,
                  color: AppTheme.kontakColor,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hubungi Kami',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kontakColor,
                  ),
                ),
                Text(
                  'Tim akademik siap membantu Anda',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Contact list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('contacts')
                  .orderBy('order')
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Map<String, dynamic>> contacts;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  contacts = snapshot.data!.docs
                      .map((d) => d.data() as Map<String, dynamic>)
                      .toList();
                } else {
                  // Default contacts when Firestore is empty
                  contacts = [
                    {
                      'name': 'Bagian Akademik',
                      'phone': '+628123456789',
                      'whatsapp': '+628123456789',
                      'email': 'akademik@kampus.ac.id',
                      'department': 'Administrasi Akademik',
                      'avatar': 'A',
                      'color': 0xFF1565C0,
                    },
                    {
                      'name': 'Bagian Kemahasiswaan',
                      'phone': '+628234567890',
                      'whatsapp': '+628234567890',
                      'email': 'kemahasiswaan@kampus.ac.id',
                      'department': 'Kemahasiswaan',
                      'avatar': 'K',
                      'color': 0xFF43A047,
                    },
                    {
                      'name': 'Bagian Keuangan',
                      'phone': '+628345678901',
                      'whatsapp': '+628345678901',
                      'email': 'keuangan@kampus.ac.id',
                      'department': 'Keuangan & Beasiswa',
                      'avatar': 'U',
                      'color': 0xFFF57C00,
                    },
                    {
                      'name': 'Perpustakaan',
                      'phone': '+628456789012',
                      'whatsapp': '',
                      'email': 'perpustakaan@kampus.ac.id',
                      'department': 'Layanan Perpustakaan',
                      'avatar': 'P',
                      'color': 0xFF7B1FA2,
                    },
                    {
                      'name': 'IT Support',
                      'phone': '+628567890123',
                      'whatsapp': '+628567890123',
                      'email': 'itsupport@kampus.ac.id',
                      'department': 'Teknologi Informasi',
                      'avatar': 'IT',
                      'color': 0xFFE53935,
                    },
                  ];
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: contacts.length,
                  itemBuilder: (ctx, i) => _ContactCard(data: contacts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ContactCard({required this.data});

  Future<void> _callPhone(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(data['color'] as int? ?? 0xFF1565C0);
    final phone = data['phone'] as String? ?? '';
    final whatsapp = data['whatsapp'] as String? ?? '';
    final email = data['email'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Text(
                data['avatar'] as String? ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] as String? ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['department'] as String? ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                if (phone.isNotEmpty)
                  _actionButton(
                    icon: Icons.phone_rounded,
                    color: Colors.green,
                    onTap: () => _callPhone(context, phone),
                  ),
                if (whatsapp.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _actionButton(
                    icon: Icons.chat_rounded,
                    color: Colors.green.shade700,
                    onTap: () => _openWhatsApp(context, whatsapp),
                  ),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _actionButton(
                    icon: Icons.email_rounded,
                    color: Colors.blue,
                    onTap: () => _sendEmail(context, email),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
