import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/utils/app_logger.dart';

class PushNotificationService {
  static Future<void> init(String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Android 13+ / iOS ke liye permission zaroori hai
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) {
        await _saveToken(userId, token);
      }

      // Token kabhi refresh ho (app reinstall/clear data) toh update karo
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _saveToken(userId, newToken);
      });
    } catch (e, st) {
      AppLogger.error('PushNotificationService.init', e, st);
    }
  }

  static Future<void> _saveToken(String userId, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }
}
