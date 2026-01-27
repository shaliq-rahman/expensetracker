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
    print("DEBUG: Starting upload for user: $userId, File: ${file.path}");
    try {
      Reference ref = _storage.ref().child('user_profile_images').child('$userId.jpg');
      print("DEBUG: Storage Reference: ${ref.fullPath}");
      
      UploadTask uploadTask = ref.putFile(file);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('DEBUG: Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
      }, onError: (e) {
        print('DEBUG: Upload stream error: $e');
      });

      TaskSnapshot snapshot = await uploadTask;
      print("DEBUG: Upload Task Finished. State: ${snapshot.state}");

      if (snapshot.state == TaskState.success) {
        String downloadUrl = await ref.getDownloadURL();
        print("DEBUG: Download URL retrieved: $downloadUrl");
        return downloadUrl;
      } else {
        throw 'Upload failed. Task State: ${snapshot.state}';
      }
    } catch (e) {
      print("DEBUG: Error in uploadProfilePicture: $e");
      rethrow;
    }
  }
}
