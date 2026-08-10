import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../../../core/utils/app_exceptions.dart';
import '../../../core/utils/app_logger.dart';

class NotificationRepository {
  final FirebaseFirestore _db;
  NotificationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// User ki saari notifications, naye se purane order mein
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((error) {
      // FIX: pehle return value discard ho jaata tha (handleError isse
      // stream me inject nahi karta) — StreamBuilder ko error kabhi pata
      // nahi chalta tha, list hamesha "loading" jaisi dikhti reh jaati thi.
      AppLogger.error('NotificationRepository.watchNotifications', error, null);
      throw error;
    });
  }

  /// Unread count — bell badge ke liye
  Stream<int> watchUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length)
        .handleError((error) {
      AppLogger.error('NotificationRepository.watchUnreadCount', error, null);
      return 0;
    });
  }

  Future<void> markAsRead(String notificationId, String requesterId) async {
    try {
      final doc =
          await _db.collection('notifications').doc(notificationId).get();
      if (!doc.exists) return;
      // SECURITY: sirf apni hi notification mark-as-read kar sakte ho
      if (doc.data()!['userId'] != requesterId) {
        throw AppException('Aap ye notification update nahi kar sakte.');
      }
      await doc.reference.update({'read': true});
    } catch (e, st) {
      AppLogger.error('NotificationRepository.markAsRead', e, st);
      throw mapToAppException(e);
    }
  }

  Future<void> deleteNotification(
      String notificationId, String requesterId) async {
    try {
      final doc =
          await _db.collection('notifications').doc(notificationId).get();
      if (!doc.exists) return;
      // SECURITY: sirf apni hi notification delete kar sakte ho
      if (doc.data()!['userId'] != requesterId) {
        throw AppException('Aap ye notification delete nahi kar sakte.');
      }
      await doc.reference.delete();
    } catch (e, st) {
      AppLogger.error('NotificationRepository.deleteNotification', e, st);
      throw mapToAppException(e);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e, st) {
      AppLogger.error('NotificationRepository.markAllAsRead', e, st);
      throw mapToAppException(e);
    }
  }
}
