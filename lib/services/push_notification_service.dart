import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/app_logger.dart';

class PushNotificationService {
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String? _currentUserId;

  static Future<void> init(String userId) async {
    if (_currentUserId == userId && _tokenRefreshSubscription != null) {
      return;
    }

    try {
      await dispose();

      _currentUserId = userId;
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) {
        await _saveToken(userId, token);
      }

      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((newToken) {
        if (_currentUserId != null) {
          _saveToken(_currentUserId!, newToken);
        }
      });
    } catch (e, st) {
      AppLogger.error('PushNotificationService.init', e, st);
    }
  }

  static Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _currentUserId = null;
  }

  static Future<void> _saveToken(String userId, String token) async {
    try {
      await Supabase.instance.client.from('users').upsert({
        'id': userId,
        'fcm_token': token,
      });
    } catch (e, st) {
      AppLogger.error('PushNotificationService._saveToken', e, st);
    }
  }
}
