import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String nim;
  final String email;
  final String role;
  final String photoUrl;
  final String prodi;
  final String phone;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.nim,
    required this.email,
    this.role = 'mahasiswa',
    this.photoUrl = '',
    this.prodi = '',
    this.phone = '',
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      nim: map['nim'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'mahasiswa',
      photoUrl: map['photoUrl'] ?? '',
      prodi: map['prodi'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'nim': nim,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'prodi': prodi,
      'phone': phone,
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? prodi,
    String? phone,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      nim: nim,
      email: email,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      prodi: prodi ?? this.prodi,
      phone: phone ?? this.phone,
    );
  }
}

class PhotoModel {
  final String id;
  final String uid;
  final String url;
  final String description;
  final DateTime? createdAt;

  PhotoModel({
    required this.id,
    required this.uid,
    required this.url,
    this.description = '',
    this.createdAt,
  });

  factory PhotoModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      url: data['url'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class NewsModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final String imageUrl;
  final DateTime? createdAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl = '',
    this.createdAt,
  });

  factory NewsModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'Lainnya',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class VideoModel {
  final String id;
  final String title;
  final String videoUrl;
  final String description;
  final String thumbnailUrl;
  final DateTime? createdAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.description = '',
    this.thumbnailUrl = '',
    this.createdAt,
  });

  factory VideoModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
