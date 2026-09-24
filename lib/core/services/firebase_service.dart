import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling FCM background message: ${message.messageId}');
}

class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      // Initialize App Check (Development vs Production)
      if (!kIsWeb) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
          appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
        );
      }

      // Configure background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('FirebaseService init note: $e');
    }
  }

  static Future<void> setupFCM(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 2. Register current device FCM token securely under private subcollection
        final token = await messaging.getToken();
        if (token != null) {
          await _saveDeviceToken(uid, token);
        }

        // 3. Listen to token refresh
        messaging.onTokenRefresh.listen((newToken) async {
          await _saveDeviceToken(uid, newToken);
        });

        // 4. Foreground message listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('FCM Foreground message received: ${message.notification?.title}');
        });
      }
    } catch (e) {
      debugPrint('FCM setup note: $e');
    }
  }

  static Future<void> _saveDeviceToken(String uid, String token) async {
    final cleanToken = token.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('deviceTokens')
        .doc(cleanToken);

    await docRef.set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}

