import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:io';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── AUTH ───────────────────────────────────────────────────────────────────

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential> signInWithEmail(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  static Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String nim,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user?.updateDisplayName(name);
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'nim': nim,
      'email': email,
      'role': 'mahasiswa',
      'photoUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── USERS ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  static Future<void> updateUserData(
      String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).update(data);
  }

  // ─── STORAGE ────────────────────────────────────────────────────────────────

  /// Upload a file and return its download URL.
  static Future<String> uploadFile({
    required File file,
    required String storagePath,
    void Function(double)? onProgress,
  }) async {
    final supabase = Supabase.instance.client;
    await supabase.storage.from('mycampushub-storage').upload(
      storagePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return supabase.storage.from('mycampushub-storage').getPublicUrl(storagePath);
  }

  static Future<void> deleteFile(String storagePath) async {
    final supabase = Supabase.instance.client;
    await supabase.storage.from('mycampushub-storage').remove([storagePath]);
  }

  // ─── PHOTOS ─────────────────────────────────────────────────────────────────

  static Future<void> savePhotoMetadata({
    required String uid,
    required String url,
    required String description,
    required String fileName,
  }) async {
    await _db.collection('photos').add({
      'uid': uid,
      'url': url,
      'description': description,
      'fileName': fileName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getPhotos({String? uid}) {
    if (uid != null) {
      return _db
          .collection('photos')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    return _db
        .collection('photos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─── KTP ────────────────────────────────────────────────────────────────────

  static Future<void> saveKTP(String uid, String url, {String? userName, String? nim}) async {
    await _db.collection('ktp').doc(uid).set({
      'uid': uid,
      'url': url,
      'uploadedAt': FieldValue.serverTimestamp(),
      'verified': false,
      'status': 'pending',
      if (userName != null) 'userName': userName,
      if (nim != null) 'nim': nim,
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getKTP(String uid) async {
    final doc = await _db.collection('ktp').doc(uid).get();
    return doc.data();
  }

  static Stream<DocumentSnapshot> streamKTP(String uid) {
    return _db.collection('ktp').doc(uid).snapshots();
  }

  // ─── KTM ────────────────────────────────────────────────────────────────────

  static Future<void> saveKTM(String uid, String url, {String? userName, String? nim}) async {
    await _db.collection('ktm').doc(uid).set({
      'uid': uid,
      'url': url,
      'uploadedAt': FieldValue.serverTimestamp(),
      'verified': false,
      'status': 'pending',
      if (userName != null) 'userName': userName,
      if (nim != null) 'nim': nim,
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getKTM(String uid) async {
    final doc = await _db.collection('ktm').doc(uid).get();
    return doc.data();
  }

  static Stream<DocumentSnapshot> streamKTM(String uid) {
    return _db.collection('ktm').doc(uid).snapshots();
  }

  // ─── NEWS ───────────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot> getNews({String? category}) {
    if (category != null && category != 'Semua') {
      return _db
          .collection('news')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    return _db
        .collection('news')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> addNews({
    required String title,
    required String content,
    required String category,
    String imageUrl = '',
    String imageStoragePath = '',
    DateTime? publishedDate,
  }) async {
    await _db.collection('news').add({
      'title': title,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'imageStoragePath': imageStoragePath,
      'createdAt': FieldValue.serverTimestamp(),
      'publishedDate': publishedDate != null ? Timestamp.fromDate(publishedDate) : FieldValue.serverTimestamp(),
      'createdBy': currentUser?.uid,
    });
  }

  static Future<void> deleteNews(String docId) async {
    final doc = await _db.collection('news').doc(docId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final path = data['imageStoragePath'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          await deleteFile(path);
        } catch (_) {}
      }
    }
    await _db.collection('news').doc(docId).delete();
  }

  // ─── VIDEOS ─────────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot> getVideos() {
    return _db
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> addVideo({
    required String title,
    required String videoUrl,
    String description = '',
    String thumbnailUrl = '',
  }) async {
    await _db.collection('videos').add({
      'title': title,
      'videoUrl': videoUrl,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUser?.uid,
    });
  }

  static Future<void> deleteVideo(String docId) async {
    await _db.collection('videos').doc(docId).delete();
  }

  // ─── CONTACTS ───────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot> getContacts() {
    return _db.collection('contacts').orderBy('order').snapshots();
  }
  // ─── ADMIN FEATURES ─────────────────────────────────────────────────────────

  static Future<void> verifyKTP(String uid, String status) async {
    await _db.collection('ktp').doc(uid).update({
      'status': status,
      'verified': status == 'approved',
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> verifyKTM(String uid, String status) async {
    await _db.collection('ktm').doc(uid).update({
      'status': status,
      'verified': status == 'approved',
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getAllStudents() {
    return _db.collection('users').where('role', isEqualTo: 'mahasiswa').snapshots();
  }

  static Future<void> addStudentData({
    required String uid,
    required String name,
    required String nim,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'nim': nim,
      'email': email,
      'role': 'mahasiswa',
      'photoUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteStudentData(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  static Stream<QuerySnapshot> getAllKTPs() {
    return _db.collection('ktp').orderBy('uploadedAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot> getAllKTMs() {
    return _db.collection('ktm').orderBy('uploadedAt', descending: true).snapshots();
  }
}
