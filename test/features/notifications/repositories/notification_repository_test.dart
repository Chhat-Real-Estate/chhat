import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chhat/features/notifications/repositories/notification_repository.dart';
import 'package:chhat/core/utils/app_exceptions.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late NotificationRepository repo;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    repo = NotificationRepository(firestore: fakeDb);
  });

  group('watchNotifications', () {
    test('sirf usi user ki notifications aayein, doosre ki nahi', () async {
      await fakeDb.collection('notifications').add({
        'userId': 'user1',
        'title': 'A',
        'body': 'body A',
        'type': 'new_request',
        'read': false,
        'createdAt': DateTime.now(),
      });
      await fakeDb.collection('notifications').add({
        'userId': 'user2',
        'title': 'B',
        'body': 'body B',
        'type': 'new_request',
        'read': false,
        'createdAt': DateTime.now(),
      });

      final result = await repo.watchNotifications('user1').first;
      expect(result.length, 1);
      expect(result.first.title, 'A');
    });
  });

  group('watchUnreadCount', () {
    test('sirf unread wali count ho, read wali nahi', () async {
      await fakeDb.collection('notifications').add({
        'userId': 'user1',
        'title': 'A',
        'body': 'body A',
        'type': 'new_request',
        'read': false,
        'createdAt': DateTime.now(),
      });
      await fakeDb.collection('notifications').add({
        'userId': 'user1',
        'title': 'B',
        'body': 'body B',
        'type': 'new_request',
        'read': true,
        'createdAt': DateTime.now(),
      });

      final count = await repo.watchUnreadCount('user1').first;
      expect(count, 1);
    });
  });

  group('markAsRead (ownership check)', () {
    test('sahi owner mark-as-read kare toh allow ho', () async {
      final docRef = await fakeDb.collection('notifications').add({
        'userId': 'user1',
        'title': 'A',
        'body': 'body A',
        'type': 'new_request',
        'read': false,
        'createdAt': DateTime.now(),
      });

      await repo.markAsRead(docRef.id, 'user1');

      final updated = await docRef.get();
      expect(updated.data()!['read'], true);
    });

    test('unrelated user mark-as-read kare toh AppException aaye (IDOR block)',
        () async {
      final docRef = await fakeDb.collection('notifications').add({
        'userId': 'user1',
        'title': 'A',
        'body': 'body A',
        'type': 'new_request',
        'read': false,
        'createdAt': DateTime.now(),
      });

      expect(
        () => repo.markAsRead(docRef.id, 'attacker99'),
        throwsA(isA<AppException>()),
      );

      final stillUnread = await docRef.get();
      expect(stillUnread.data()!['read'], false);
    });
  });

  group('markAllAsRead', () {
    test('user ki saari unread notifications read ho jayein', () async {
      await fakeDb.collection('notifications').add({
        'userId': 'user1',
        'title': 'A',
        'body': 'b',
        'type': 'x',
        'read': false,
        'createdAt': DateTime.now(),
      });
      await fakeDb.collection('notifications').add({
        'userId': 'user1',
        'title': 'B',
        'body': 'b',
        'type': 'x',
        'read': false,
        'createdAt': DateTime.now(),
      });
      await fakeDb.collection('notifications').add({
        'userId': 'user2',
        'title': 'C',
        'body': 'b',
        'type': 'x',
        'read': false,
        'createdAt': DateTime.now(),
      }); // doosre user ki — touch nahi honi chahiye

      await repo.markAllAsRead('user1');

      final user1Count = await repo.watchUnreadCount('user1').first;
      final user2Count = await repo.watchUnreadCount('user2').first;
      expect(user1Count, 0);
      expect(user2Count, 1); // untouched
    });
  });
}
