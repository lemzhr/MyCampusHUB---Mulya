import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_news_screen.dart';
import 'admin_students_screen.dart';
import 'admin_ktp_screen.dart';
import 'admin_ktm_screen.dart';
import 'admin_video_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildCard(context, 'Kelola Berita', Icons.article, const AdminNewsScreen()),
          _buildCard(context, 'Kelola Mahasiswa', Icons.people, const AdminStudentsScreen()),
          _buildCard(context, 'Verifikasi KTP', Icons.credit_card, const AdminKtpScreen()),
          _buildCard(context, 'Verifikasi KTM', Icons.badge, const AdminKtmScreen()),
          _buildCard(context, 'Kelola Video', Icons.video_library, const AdminVideoScreen()),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.indigo),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
