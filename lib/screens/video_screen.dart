import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "../services/firebase_service.dart";
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../utils/app_theme.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  bool _isAdmin = false;
  bool _adminChecked = false; // ← flag: sudah selesai cek role atau belum

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _adminChecked = true);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _isAdmin = doc.exists && doc.data()?['role'] == 'admin';
          _adminChecked = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _adminChecked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video'),
        backgroundColor: AppTheme.videoColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: !_adminChecked
          ? null // masih loading role dari Firestore
          : _isAdmin
              ? FloatingActionButton.extended(
                  backgroundColor: AppTheme.videoColor,
                  onPressed: () => _showAddVideoDialog(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Tambah Video',
                      style: TextStyle(color: Colors.white)),
                )
              : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.getVideos(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada video',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final videos = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: videos.length,
            itemBuilder: (ctx, i) {
              final data = videos[i].data() as Map<String, dynamic>;
              return _VideoCard(
                title: data['title'] ?? 'Video',
                description: data['description'] ?? '',
                videoUrl: data['videoUrl'] ?? '',
                thumbnailUrl: data['thumbnailUrl'] ?? '',
                docId: videos[i].id,
                isAdmin: _isAdmin,
              );
            },
          );
        },
      ),
    );
  }

  void _showAddVideoDialog() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Video'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Judul Video'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL Video (mp4)',
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Deskripsi'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('videos')
                    .add({
                  'title': titleCtrl.text,
                  'videoUrl': urlCtrl.text,
                  'description': descCtrl.text,
                  'thumbnailUrl': '',
                  'createdAt': FieldValue.serverTimestamp(),
                  'createdBy':
                      FirebaseAuth.instance.currentUser?.uid,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.videoColor,
                foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String docId;
  final bool isAdmin;

  const _VideoCard({
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.docId,
    required this.isAdmin,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  bool _isInitializing = false;

  Future<void> _initVideo() async {
    if (_isInitializing) return;
    setState(() => _isInitializing = true);
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        placeholder: Container(color: Colors.black),
      );
      setState(() => _isPlaying = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat video: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video player area
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: _isPlaying && _chewieController != null
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Chewie(controller: _chewieController!),
                  )
                : GestureDetector(
                    onTap: _initVideo,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.grey.shade900,
                        child: _isInitializing
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white))
                            : Center(
                                child: Icon(
                                  Icons.play_circle_filled_rounded,
                                  size: 60,
                                  color: AppTheme.videoColor,
                                ),
                              ),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
                if (widget.isAdmin) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await FirebaseService.deleteVideo(widget.docId);
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                      label: const Text('Hapus',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
