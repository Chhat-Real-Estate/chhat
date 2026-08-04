import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chhat/features/requests/repositories/request_repository.dart';
import 'package:chhat/features/requests/models/request_model.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late RequestRepository repo;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    repo = RequestRepository(firestore: fakeDb);
  });

  group('updateRequestStatus (IDOR fix)', () {
    test('sahi owner update kare toh allow ho', () async {
      final docRef = await fakeDb.collection('requests').add({
        'ownerId': 'owner1',
        'tenantId': 'tenant1',
        'status': 'pending',
      });

      await repo.updateRequestStatus(docRef.id, 'accepted', 'owner1');

      final updated = await docRef.get();
      expect(updated.data()!['status'], 'accepted');
    });

    test('sahi tenant update kare toh allow ho', () async {
      final docRef = await fakeDb.collection('requests').add({
        'ownerId': 'owner1',
        'tenantId': 'tenant1',
        'status': 'pending',
      });

      await repo.updateRequestStatus(docRef.id, 'rejected', 'tenant1');

      final updated = await docRef.get();
      expect(updated.data()!['status'], 'rejected');
    });

    test('unrelated user update kare toh Exception aaye (IDOR block)',
        () async {
      final docRef = await fakeDb.collection('requests').add({
        'ownerId': 'owner1',
        'tenantId': 'tenant1',
        'status': 'pending',
      });

      expect(
        () => repo.updateRequestStatus(docRef.id, 'accepted', 'attacker99'),
        throwsA(isA<Exception>()),
      );
    });

    test('nonexistent requestId ke liye Exception aaye', () {
      expect(
        () => repo.updateRequestStatus('does-not-exist', 'accepted', 'owner1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('deleteRequest (IDOR fix)', () {
    test('sahi owner delete kare toh allow ho', () async {
      final docRef = await fakeDb.collection('requests').add({
        'ownerId': 'owner1',
        'tenantId': 'tenant1',
      });

      await repo.deleteRequest(docRef.id, 'owner1');

      final deleted = await docRef.get();
      expect(deleted.exists, false);
    });

    test('unrelated user delete kare toh Exception aaye (IDOR block)',
        () async {
      final docRef = await fakeDb.collection('requests').add({
        'ownerId': 'owner1',
        'tenantId': 'tenant1',
      });

      expect(
        () => repo.deleteRequest(docRef.id, 'attacker99'),
        throwsA(isA<Exception>()),
      );

      final stillThere = await docRef.get();
      expect(stillThere.exists, true);
    });
  });

  group('sendRequest (TOCTOU fix)', () {
    test('naya request bheje toh save ho jaye', () async {
      final request = RequestModel(
        tenantId: 'tenant1',
        tenantPhone: '+919999999999',
        listingId: 'listing1',
        ownerId: 'owner1',
        area: 'Andheri',
        rent: 15000,
        senderType: 'tenant',
      );

      await repo.sendRequest(request);

      final snap = await fakeDb.collection('requests').get();
      expect(snap.docs.length, 1);
    });

    test(
        'duplicate request (same tenant+listing+type) dobara bheje toh Exception aaye',
        () async {
      final request = RequestModel(
        tenantId: 'tenant1',
        tenantPhone: '+919999999999',
        listingId: 'listing1',
        ownerId: 'owner1',
        area: 'Andheri',
        rent: 15000,
        senderType: 'tenant',
      );

      await repo.sendRequest(request);

      expect(
        () => repo.sendRequest(request),
        throwsA(isA<Exception>()),
      );

      final snap = await fakeDb.collection('requests').get();
      expect(snap.docs.length, 1); // dobara save nahi hua
    });
  });
}
