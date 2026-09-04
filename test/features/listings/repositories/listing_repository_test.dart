import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chhat/features/listings/repositories/listing_repository.dart';
import 'package:chhat/core/utils/app_exceptions.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chhat/core/config/supabase_config.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late ListingRepository repo;

  setUpAll(() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  });

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    repo = ListingRepository(firestore: fakeDb);
  });

  group('deactivateListing (IDOR fix)', () {
    test('sahi owner deactivate kare toh allow ho', () async {
      final docRef = await fakeDb.collection('listings').add({
        'ownerId': 'owner1',
        'active': true,
      });

      await repo.deactivateListing(docRef.id, 'owner1');

      final updated = await docRef.get();
      expect(updated.data()!['active'], false);
    });

    test('unrelated user deactivate kare toh AppException aaye (IDOR block)',
        () async {
      final docRef = await fakeDb.collection('listings').add({
        'ownerId': 'owner1',
        'active': true,
      });

      expect(
        () => repo.deactivateListing(docRef.id, 'attacker99'),
        throwsA(isA<AppException>()),
      );

      final stillActive = await docRef.get();
      expect(stillActive.data()!['active'], true); // change nahi hui
    });

    test('nonexistent listingId ke liye AppException aaye', () {
      expect(
        () => repo.deactivateListing('does-not-exist', 'owner1'),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('reportListing (duplicate-report dedupe fix)', () {
    test('ek user same listing dobara report kare toh AppException aaye',
        () async {
      final docRef = await fakeDb.collection('listings').add({
        'ownerId': 'owner1',
        'active': true,
        'reportCount': 0,
      });

      await repo.reportListing(docRef.id, 'reporter1');

      expect(
        () => repo.reportListing(docRef.id, 'reporter1'),
        throwsA(isA<AppException>()),
      );

      final updated = await docRef.get();
      expect(updated.data()!['reportCount'], 1); // dobara count nahi hua
    });

    test('5 alag reporters report karein toh listing auto-deactivate ho',
        () async {
      final docRef = await fakeDb.collection('listings').add({
        'ownerId': 'owner1',
        'active': true,
        'reportCount': 0,
      });

      for (var i = 1; i <= 5; i++) {
        await repo.reportListing(docRef.id, 'reporter$i');
      }

      final updated = await docRef.get();
      expect(updated.data()!['reportCount'], 5);
      expect(updated.data()!['active'], false);
    });

    test('nonexistent listingId ke liye AppException aaye', () {
      expect(
        () => repo.reportListing('does-not-exist', 'reporter1'),
        throwsA(isA<AppException>()),
      );
    });
  });
}
