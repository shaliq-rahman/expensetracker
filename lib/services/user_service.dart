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
      
      // Simple upload without stream listener for reliability
      await ref.putFile(file);
      
      // Get URL after upload completes
      String downloadUrl = await ref.getDownloadURL();
      print("DEBUG: Download URL retrieved: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("DEBUG: Error in uploadProfilePicture: $e");
      rethrow;
    }
  }
}
