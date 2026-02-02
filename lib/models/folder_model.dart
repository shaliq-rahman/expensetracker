import 'package:cloud_firestore/cloud_firestore.dart';

class FolderModel {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final String color; // Hex string
  final String iconAsset;
  final int itemCount;
  final int sizeInBytes;
  final String? parentId;

  FolderModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    this.color = '0xFF90CAF9', // Default light blue
    this.iconAsset = 'assets/icons/folder_icon_v2.png',
    this.itemCount = 0,
    this.sizeInBytes = 0,
    this.parentId,
  });

  factory FolderModel.fromMap(Map<String, dynamic> map, String id) {
    return FolderModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      color: map['color'] ?? '0xFF90CAF9',
      iconAsset: map['iconAsset'] ?? 'assets/icons/folder_icon_v2.png',
      itemCount: map['itemCount'] ?? 0,
      sizeInBytes: map['sizeInBytes'] ?? 0,
      parentId: map['parentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'color': color,
      'iconAsset': iconAsset,
      'itemCount': itemCount,
      'sizeInBytes': sizeInBytes,
      'parentId': parentId,
    };
  }

  String get totalSize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeInBytes < 1024 * 1024 * 1024) return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
