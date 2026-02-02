import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:expense_tracker/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return UserModel.fromMap(data);
    }
    return null;
  }

  Future<String> uploadProfilePicture(File file, String userId) async {
    print("DEBUG: STEP 1 - Check File");
    if (!file.existsSync()) throw Exception("Local file missing");

    try {
      print("DEBUG: STEP 2 - Check Bucket Access");
      // Try to verify bucket connection
      try {
        await _storage.ref().child('test_connection').getDownloadURL().catchError((_) => "");
        print("DEBUG: Connection seems alive (or at least reachable)");
      } catch (e) {
        print("DEBUG: Connection check note: $e");
      }

      print("DEBUG: STEP 3 - Prepare Ref");
      // Simplify path to root to rule out folder issues
      Reference ref = _storage.ref().child('profile_$userId.jpg'); 
      print("DEBUG: Uploading to ${ref.fullPath} in bucket ${_storage.bucket}");

      print("DEBUG: STEP 4 - Read Bytes");
      final bytes = await file.readAsBytes();
      print("DEBUG: Bytes read: ${bytes.length}");

      if (bytes.isEmpty) throw Exception("Empty file bytes");

      print("DEBUG: STEP 5 - Put Data");
      UploadTask task = ref.putData(bytes);
      
      task.snapshotEvents.listen((s) {
         print('DEBUG: Progress ${s.bytesTransferred} / ${s.totalBytes} (State: ${s.state})');
      }, onError: (e) {
         print("DEBUG: Stream Error: $e");
      });

      print("DEBUG: STEP 6 - Await Task");
      await task;
      print("DEBUG: Task Complete. Final State: ${task.snapshot.state}");

      if (task.snapshot.state == TaskState.success) {
         print("DEBUG: STEP 7 - Get URL");
         String url = await ref.getDownloadURL();
         print("DEBUG: URL: $url");
         return url;
      } else {
         throw Exception("Upload failed with state: ${task.snapshot.state}");
      }
    } catch (e, stack) {
       print("DEBUG: EXCEPTION CAUGHT: $e");
       print("DEBUG: Stack: $stack");
       rethrow;
    }
  }
}
