import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../../../core/utils/app_exceptions.dart';
import '../../../core/utils/app_logger.dart';

class NotificationRepository {
  final SupabaseClient _client;
  NotificationRepository({SupabaseClient? client, dynamic firestore})
      : _client = client ?? Supabase.instance.client;

  /// User ki saari notifications (Realtime Stream)
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .map((item) => NotificationModel.fromMap(item, item['id'].toString()))
            .toList())
        .handleError((error) {
      AppLogger.error('NotificationRepository.watchNotifications', error, null);
      return <NotificationModel>[];
    });
  }

  /// Unread count — bell badge ke liye
  Stream<int> watchUnreadCount(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .limit(100)
        .map((data) => data.where((item) => item['read'] == false).length)
        .handleError((error) {
      AppLogger.error('NotificationRepository.watchUnreadCount', error, null);
      return 0;
    });
  }

  /// Server-side aggregation count query
  Future<int> getUnreadCount(String userId) async {
    try {
      final res = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('read', false)
          .count(CountOption.exact);
      return res.count;
    } catch (e, st) {
      AppLogger.error('NotificationRepository.getUnreadCount', e, st);
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId, String requesterId) async {
    try {
      final doc = await _client
          .from('notifications')
          .select('user_id')
          .eq('id', notificationId)
          .maybeSingle();

      if (doc == null) return;
      if (doc['user_id'] != requesterId) {
        throw AppException('Aap ye notification update nahi kar sakte.');
      }

      await _client
          .from('notifications')
          .update({'read': true}).eq('id', notificationId);
    } catch (e, st) {
      AppLogger.error('NotificationRepository.markAsRead', e, st);
      throw mapToAppException(e);
    }
  }

  Future<void> deleteNotification(String notificationId, String requesterId) async {
    try {
      final doc = await _client
          .from('notifications')
          .select('user_id')
          .eq('id', notificationId)
          .maybeSingle();

      if (doc == null) return;
      if (doc['user_id'] != requesterId) {
        throw AppException('Aap ye notification delete nahi kar sakte.');
      }

      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e, st) {
      AppLogger.error('NotificationRepository.deleteNotification', e, st);
      throw mapToAppException(e);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);
    } catch (e, st) {
      AppLogger.error('NotificationRepository.markAllAsRead', e, st);
      throw mapToAppException(e);
    }
  }
}
