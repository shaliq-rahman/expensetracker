import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialise() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      // Note: We might want to update this in the DB if we have a current user
      // For now we will rely on the app logic to call saveTokenToDatabase
      if (kDebugMode) {
        print("FCM Token Refreshed: $newToken");
      }
    });
  }

  Future<String?> getToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken == null) {
        if (kDebugMode) {
          print('APNS Token not available yet');
        }
        return null;
      }
    }
    return await _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    if (kDebugMode) {
      print("Subscribed to topic: $topic");
    }
  }

  Future<void> saveTokenToDatabase(String userId) async {
    String? token = await getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      if (kDebugMode) {
        print("Token saved for user: $userId");
      }
    }
  }
}
