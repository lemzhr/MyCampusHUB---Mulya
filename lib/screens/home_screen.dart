import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'gallery_screen.dart';
import 'ktp_screen.dart';
import 'ktm_screen.dart';
import 'profile_screen.dart';
import 'video_screen.dart';
import 'news_screen.dart';
import 'contact_screen.dart';
import 'upload_foto_screen.dart';
import 'admin/admin_dashboard.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = 'Mahasiswa';
  String _userRole = 'mahasiswa';
  String _userEmail = '';
  final int _notifCount = 3;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? user.displayName ?? 'Mahasiswa';
          _userEmail = user.email ?? '';
          _userRole = doc.data()?['role'] ?? 'mahasiswa';
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Upload Foto',
      'icon': Icons.camera_alt_rounded,
      'color': AppTheme.uploadFotoColor,
      'screen': 'upload_foto',
    },
    {
      'title': 'Galeri',
      'icon': Icons.photo_library_rounded,
      'color': AppTheme.galeriColor,
      'screen': 'gallery',
    },
    {
      'title': 'Upload KTP',
      'icon': Icons.credit_card_rounded,
      'color': AppTheme.uploadKTPColor,
      'screen': 'ktp',
    },
    {
      'title': 'Upload KTM',
      'icon': Icons.badge_rounded,
      'color': AppTheme.uploadKTMColor,
      'screen': 'ktm',
    },
    {
      'title': 'Profil',
      'icon': Icons.person_rounded,
      'color': AppTheme.profilColor,
      'screen': 'profile',
    },
    {
      'title': 'Video',
      'icon': Icons.play_circle_filled_rounded,
      'color': AppTheme.videoColor,
      'screen': 'video',
    },
    {
      'title': 'Berita',
      'icon': Icons.newspaper_rounded,
      'color': AppTheme.beritaColor,
      'screen': 'news',
    },
    {
      'title': 'Kontak Person',
      'icon': Icons.phone_rounded,
      'color': AppTheme.kontakColor,
      'screen': 'contact',
    },
  ];

  void _navigateTo(String screen) {
    Widget destination;
    switch (screen) {
      case 'upload_foto':
        destination = const UploadFotoScreen();
        break;
      case 'gallery':
        destination = const GalleryScreen();
        break;
      case 'ktp':
        destination = const KTPScreen();
        break;
      case 'ktm':
        destination = const KTMScreen();
        break;
      case 'profile':
        destination = const ProfileScreen();
        break;
      case 'video':
        destination = const VideoScreen();
        break;
      case 'news':
        destination = const NewsScreen();
        break;
      case 'contact':
        destination = const ContactScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const NewsScreen(),
          const GalleryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                const Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuGrid(),
                const SizedBox(height: 20),
                if (_userRole == 'admin') ...[
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildLatestNewsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: AppTheme.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              const Text(
                'MY CAMPUS HUB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                  if (_notifCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_notifCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'logout') _logout();
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Keluar'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${_userName.split(' ').first}! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selamat datang kembali!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                if (_userEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _userEmail,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _menuItems.length,
      itemBuilder: (ctx, i) {
        final item = _menuItems[i];
        return _buildMenuCard(
          title: item['title'],
          icon: item['icon'],
          color: item['color'],
          onTap: () => _navigateTo(item['screen']),
        );
      },
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Berita Terbaru',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            TextButton(
              onPressed: () => _navigateTo('news'),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getNews(),
          builder: (ctx, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final docs = snapshot.data!.docs.take(5).toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildNewsChip(
                      data['title'] ?? 'Berita PNL',
                      data['category'] ?? 'Berita',
                    );
                  }).toList(),
                ),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildNewsChip('Penerimaan Mahasiswa Baru PNL', 'Akademik'),
                  _buildNewsChip('Pelaksanaan UTS Semester Genap', 'Informasi'),
                  _buildNewsChip('Kunjungan Industri Jurusan TI', 'Kampus'),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNewsChip(String title, String category) {
    return GestureDetector(
      onTap: () => _navigateTo('news'),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.beritaColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.beritaColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title.length > 25 ? '${title.substring(0, 25)}...' : title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded), label: 'Home'),
      BottomNavigationBarItem(
          icon: Icon(Icons.newspaper_rounded), label: 'Berita'),
      BottomNavigationBarItem(
          icon: Icon(Icons.photo_library_rounded), label: 'Galeri'),
      BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded), label: 'Profil'),
    ];

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryBlue,
      unselectedItemColor: Colors.grey,
      items: items,
    );
  }
}
