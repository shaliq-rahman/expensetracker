import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/folder_model.dart';
import 'package:expense_tracker/models/file_model.dart';

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _foldersCollection = 'folders';
  final String _filesCollection = 'files';

  // --- Folders ---

  // Create a new folder
  Future<void> createFolder(FolderModel folder) async {
    try {
      print("StorageService: Creating folder in Firestore (Root Collection): ${folder.toMap()}");
      // Use root collection, but model has userId
      await _firestore.collection(_foldersCollection).add(folder.toMap());
      print("StorageService: Folder added successfully");
    } catch (e) {
      print('Error creating folder: $e');
      rethrow;
    }
  }

  // Get folders for a specific user and parent (null parent = root folders)
  Stream<List<FolderModel>> getFolders(String userId, {String? parentId}) {
    print("StorageService: getFolders called for user: $userId, parentId: $parentId");
    Query query = _firestore
        .collection(_foldersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true); // Newest first

    if (parentId == null) {
      query = query.where('parentId', isNull: true);
    } else {
      query = query.where('parentId', isEqualTo: parentId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FolderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // --- Files ---

  // Get recent files for a user (across all folders)
  Stream<List<FileModel>> getRecentFiles(String userId, {int limit = 5}) {
    return _firestore
        .collection(_filesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get files in a specific folder
  // Note: We don't strictly need userId here if folderId is unique globally, 
  // but adding it is good for security rules if needed. 
  // For now, let's just query by folderId as that's the primary look-up.
  Stream<List<FileModel>> getFilesInFolder(String userId, String _folderId) {
    print("StorageService: Listening to files in folder: $_folderId");
    return _firestore
        .collection(_filesCollection)
        .where('folderId', isEqualTo: _folderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print("StorageService: Stream received ${snapshot.docs.length} files");
      final List<FileModel> files = [];
      for (var doc in snapshot.docs) {
        try {
          final file = FileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          files.add(file);
          print("StorageService: Successfully parsed file: ${file.name}");
        } catch (e, stack) {
          print("StorageService: ERROR parsing file ${doc.id}: $e");
          print("StorageService: Data: ${doc.data()}");
          print("StorageService: Stack: $stack");
        }
      }
      print("StorageService: Returning ${files.length} successfully parsed files");
      return files;
    });
  }

  // Create a file entry (metadata only for now) and update folder stats
  Future<void> createFile(FileModel file) async {
     try {
       await _firestore.runTransaction((transaction) async {
         // 1. Create a new document reference
         final fileRef = _firestore.collection(_filesCollection).doc();
         
         // 2. Write file metadata
         transaction.set(fileRef, file.toMap());

         // 3. Update parent folder stats if applicable
         if (file.folderId.isNotEmpty) {
           final folderRef = _firestore.collection(_foldersCollection).doc(file.folderId);
           final folderDoc = await transaction.get(folderRef);

           if (folderDoc.exists) {
             final data = folderDoc.data() as Map<String, dynamic>;
             final currentCount = data['itemCount'] ?? 0;
             final currentSize = data['sizeInBytes'] ?? 0;

             transaction.update(folderRef, {
               'itemCount': currentCount + 1,
               'sizeInBytes': currentSize + file.sizeInBytes,
             });
             print("StorageService: Updated folder ${file.folderId} stats: count=${currentCount + 1}, size=${currentSize + file.sizeInBytes}");
           }
         }
       });
       print("StorageService: File created and folder stats updated successfully");
      
    } catch (e) {
      print('Error creating file: $e');
      rethrow;
    }
  }

  // Delete a file (both metadata and storage) and update folder stats
  Future<void> deleteFile(String fileId, String? fileUrl, String folderId, int sizeInBytes) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Get folder ref first in transaction (reads must come before writes usually, but for delete/update order matters less if we don't read the file again)
        // But we need to read the folder to update it.
        
        DocumentSnapshot? folderDoc;
        DocumentReference? folderRef;
        
        if (folderId.isNotEmpty) {
          folderRef = _firestore.collection(_foldersCollection).doc(folderId);
          folderDoc = await transaction.get(folderRef);
        }

        // 2. Delete File Document
        final fileRef = _firestore.collection(_filesCollection).doc(fileId);
        transaction.delete(fileRef);

        // 3. Update Folder Stats
        if (folderRef != null && folderDoc != null && folderDoc.exists) {
           final data = folderDoc.data() as Map<String, dynamic>;
           final currentCount = data['itemCount'] ?? 0;
           final currentSize = data['sizeInBytes'] ?? 0;

           // Ensure we don't go below zero
           final newCount = (currentCount - 1) < 0 ? 0 : (currentCount - 1);
           final newSize = (currentSize - sizeInBytes) < 0 ? 0 : (currentSize - sizeInBytes);

           transaction.update(folderRef, {
             'itemCount': newCount,
             'sizeInBytes': newSize,
           });
           print("StorageService: Updated folder $folderId stats: count=$newCount, size=$newSize");
        }
      });
      
      print('StorageService: Deleted file metadata: $fileId');
      
      // 4. Delete from Storage if URL exists (Outside transaction as it's Storage, not Firestore)
      if (fileUrl != null && fileUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(fileUrl);
          await ref.delete();
          print('StorageService: Deleted file from storage: ${ref.fullPath}');
        } catch (e) {
          print('StorageService: Warning - Could not delete storage file: $e');
          // Don't rethrow - metadata deletion succeeded
        }
      }
    } catch (e) {
      print('StorageService: Error deleting file: $e');
      rethrow;
    }
  }

  // Recalculate stats for all folders of a user
  Future<void> recalculateFolderStats(String userId) async {
    print("StorageService: Recalculating stats for user $userId");
    try {
      // 1. Get all folders
      final folderSnapshot = await _firestore
          .collection(_foldersCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      var batchCount = 0;

      for (var folderDoc in folderSnapshot.docs) {
        final folderId = folderDoc.id;

        // 2. Get all files for this folder
        final fileSnapshot = await _firestore
            .collection(_filesCollection)
            .where('folderId', isEqualTo: folderId)
            .get();

        int count = 0;
        int size = 0;

        for (var fileDoc in fileSnapshot.docs) {
          final data = fileDoc.data();
          count++;
          
          int fileBytes = data['sizeInBytes'] ?? 0;
          
          // Fallback: parse legacy 'size' string if bytes is 0
          if (fileBytes == 0 && data['size'] != null && data['size'] is String) {
            fileBytes = _parseSizeString(data['size']);
             // Optionally update the file doc with bytes for future (commented out to save writes, but good practice)
             // batch.update(fileDoc.reference, {'sizeInBytes': fileBytes});
          }
          
          size += fileBytes;
        }

        // 3. Update folder doc
        batch.update(folderDoc.reference, {
          'itemCount': count,
          'sizeInBytes': size,
        });
        batchCount++;

        // Commit in chunks of 500 if needed
        if (batchCount >= 450) {
          await batch.commit();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }
      print("StorageService: Recalculation complete.");

    } catch (e) {
      print("StorageService: Error recalculating stats: $e");
      rethrow;
    }
  }

  int _parseSizeString(String sizeStr) {
    try {
      final parts = sizeStr.split(' ');
      if (parts.length != 2) return 0;
      
      final number = double.tryParse(parts[0]);
      final unit = parts[1].toUpperCase();
      
      if (number == null) return 0;
      
      switch (unit) {
        case 'B': return number.toInt();
        case 'KB': return (number * 1024).toInt();
        case 'MB': return (number * 1024 * 1024).toInt();
        case 'GB': return (number * 1024 * 1024 * 1024).toInt();
        default: return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  // Upload file to Firebase Storage and return URL
  Future<String> uploadFileToStorage(File file, String userId) async {
    print("StorageService: Starting upload for user $userId");
    
    if (!file.existsSync()) {
      print("StorageService: Local file not found: ${file.path}");
      throw Exception("Local file missing");
    }

    try {
      // 1. Read bytes first (more reliable than putFile in some envs)
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw Exception("Empty file bytes");
      print("StorageService: Read ${bytes.length} bytes");

      // 2. Prepare Reference
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final Reference ref = _storage.ref().child('users/$userId/files/$fileName');
      print("StorageService: Uploading to ${ref.fullPath}");

      // 3. Upload Data
      final UploadTask uploadTask = ref.putData(bytes);
      
      // Monitor Progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('StorageService: Progress ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      }, onError: (e) {
        print("StorageService: Upload Stream Error: $e");
      });

      // 4. Await Completion
      final TaskSnapshot snapshot = await uploadTask;
      print("StorageService: Upload State: ${snapshot.state}");

      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        print("StorageService: Upload URL retrieved: $downloadUrl");
        return downloadUrl;
      } else {
        throw Exception("Upload unsuccessful: ${snapshot.state}");
      }
    } catch (e) {
      print('StorageService: Error uploading file to storage: $e');
      rethrow;
    }
  }
}
