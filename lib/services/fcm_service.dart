import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
       if (kDebugMode) {
        print("FCM Token Refreshed: $newToken");
      }
      
      // Update in DB if user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await saveTokenToDatabase(currentUser.uid);
      }
    });

    // Check if user is already logged in and update token
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await saveTokenToDatabase(currentUser.uid);
      await subscribeToTopic('xtrack-users');
    }
  }

  Future<String?> getToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Retry getting APNS token up to 3 times
      for (int i = 0; i < 3; i++) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          if (kDebugMode) {
             print('APNS Token retrieved: $apnsToken');
          }
          break; // Found it!
        }
        
        if (kDebugMode) {
           print('APNS Token not available yet. Retrying in 3 seconds... (Attempt ${i + 1}/3)');
        }
        await Future.delayed(const Duration(seconds: 3));
      }
      
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken == null) {
        if (kDebugMode) {
           print('APNS Token still null after retries. FCM token generation may fail on iOS.');
        }
        // We still try to get the FCM token, but it might fail or return null
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
