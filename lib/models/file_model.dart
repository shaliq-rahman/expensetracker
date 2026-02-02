import 'package:cloud_firestore/cloud_firestore.dart';

enum FileType { doc, image, video, other }

class FileModel {
  final String id;
  final String userId;
  final String folderId;
  final String name;
  final FileType type;
  final int sizeInBytes; // Replaces 'size' string
  final String? legacySize; // For backward compatibility
  final DateTime createdAt;
  final String? url;
  final String? iconAsset; // Optional custom icon path for specific file types
  final bool isStarred;

  FileModel({
    required this.id,
    required this.userId,
    required this.folderId,
    required this.name,
    required this.type,
    required this.sizeInBytes,
    this.legacySize,
    required this.createdAt,
    this.url,
    this.iconAsset,
    this.isStarred = false,
  });

  factory FileModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle backward compatibility
    int bytes = map['sizeInBytes'] ?? 0;
    String? oldSize;
    
    if (bytes == 0 && map['size'] != null && map['size'] is String) {
      oldSize = map['size'];
    }
    
    return FileModel(
      id: id,
      userId: map['userId'] ?? '',
      folderId: map['folderId'] ?? '',
      name: map['name'] ?? '',
      type: FileType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FileType.other,
      ),
      sizeInBytes: bytes,
      legacySize: oldSize,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      url: map['url'],
      iconAsset: map['iconAsset'],
      isStarred: map['isStarred'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'folderId': folderId,
      'name': name,
      'type': type.name, 
      'sizeInBytes': sizeInBytes,
      'size': legacySize, // Keep it if we strictly want to preserve it, or null
      'createdAt': Timestamp.fromDate(createdAt),
      'url': url,
      'iconAsset': iconAsset,
      'isStarred': isStarred,
    };
  }

  String get size {
    if (sizeInBytes > 0) {
       if (sizeInBytes < 1024) return '$sizeInBytes B';
       if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
       if (sizeInBytes < 1024 * 1024 * 1024) return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
       return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return legacySize ?? '0 B';
  }
}
