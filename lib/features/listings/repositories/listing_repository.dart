import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // NAYA: Storage se images delete karne ke liye
import '../models/listing_model.dart';
import '../../../core/utils/app_exceptions.dart';
import '../../../core/utils/app_logger.dart';

const int kListingsPageSize = 20;

class ListingRepository {
  final FirebaseFirestore _db;
  ListingRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // Listing create karo
  Future<String> createListing(ListingModel listing) async {
    try {
      // Anti-dalal check — ek number se max 3 listings
      final existing = await _db
          .collection('listings')
          .where('phone', isEqualTo: listing.phone)
          .where('active', isEqualTo: true)
          .limit(3)
          .get();

      if (existing.docs.length >= 3) {
        throw AppException('Aap already 3 rooms list kar chuke ho');
      }

      final doc = await _db.collection('listings').add(listing.toMap());
      return doc.id;
    } catch (e, st) {
      AppLogger.error('ListingRepository.createListing', e, st);
      throw mapToAppException(e);
    }
  }

  // Owner ki listings. [limit] pagination ke liye — puri collection kabhi mat khincho.
  Stream<List<ListingModel>> getOwnerListings(
    String ownerId, {
    int limit = kListingsPageSize,
  }) {
    return _db
        .collection('listings')
        .where('ownerId', isEqualTo: ownerId)
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((e, st) {
      AppLogger.error('ListingRepository.getOwnerListings', e, st);
    }).map((snap) => snap.docs
            .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// FIX: pehle [area] param liya jaata tha par IGNORE hota tha — hardcoded
  /// 200 docs khinch ke Dart side filter hota tha (4x zyada Firestore reads
  /// jitni zarurat thi, aur area-wise filtering hi missing thi).
  /// Ab jab [area] khali nahi hai, server-side where-clause se filter hota
  /// hai — sirf utne hi docs charge hote hain jitni zarurat hai.
  Stream<List<ListingModel>> getNearbyListings(
    String area, {
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query =
        _db.collection('listings').where('active', isEqualTo: true);

    if (area.trim().isNotEmpty) {
      query = query.where('area', isEqualTo: area.toLowerCase().trim());
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((e, st) {
      AppLogger.error('ListingRepository.getNearbyListings', e, st);
    }).map((snap) => snap.docs
            .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// NAYA: Proper search — [searchKeywords] field (Cloud Function se
  /// auto-generate hoti hai) ke against server-side query karta hai, poore
  /// dataset pe, sirf latest N docs tak limited nahi. propertyKind
  /// (residential/commercial) dono ke liye same tareeke se kaam karta hai.
  Stream<List<ListingModel>> searchListings({
    required String propertyKind,
    String search = '',
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('listings')
        .where('active', isEqualTo: true)
        .where('propertyKind', isEqualTo: propertyKind);

    final trimmed = search.toLowerCase().trim();
    if (trimmed.isNotEmpty) {
      final words = trimmed.split(RegExp(r'\s+')).take(10).toList();
      query = query.where('searchKeywords', arrayContainsAny: words);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((e, st) {
      AppLogger.error('ListingRepository.searchListings', e, st);
    }).map((snap) => snap.docs
            .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// SECURITY FIX (IDOR): pehle koi bhi apna listingId aur kisi aur ka
  /// document ID pass karke uski listing deactivate kara sakta tha, kyunki
  /// ownership check hi nahi tha. [requesterId] = current logged-in user's uid.
  /// NOTE: yeh client-side check hai (defense-in-depth) — asli enforcement
  /// Firestore Rules mein honi chahiye:
  ///   allow update: if request.auth.uid == resource.data.ownerId;
  Future<void> deactivateListing(String listingId, String requesterId) async {
    try {
      final ref = _db.collection('listings').doc(listingId);
      final snap = await ref.get();

      if (!snap.exists) {
        throw AppException('Yeh listing ab maujood nahi hai.');
      }
      if (snap.data()?['ownerId'] != requesterId) {
        throw AppException('Aap sirf apni listings deactivate kar sakte hain.');
      }

      await ref.update({'active': false});
    } catch (e, st) {
      AppLogger.error('ListingRepository.deactivateListing', e, st);
      throw mapToAppException(e);
    }
  }

  // NAYA: Permanent Delete (Database + Storage dono se kachra saaf karne ke liye)
  // SECURITY FIX: same ownership check yahan bhi zaroori hai.
  Future<void> deleteListingPermanently(
    String listingId,
    List<String> photoUrls,
    String requesterId,
  ) async {
    try {
      final ref = _db.collection('listings').doc(listingId);
      final snap = await ref.get();
      if (!snap.exists) {
        throw AppException('Yeh listing ab maujood nahi hai.');
      }
      if (snap.data()?['ownerId'] != requesterId) {
        throw AppException('Aap sirf apni listings delete kar sakte hain.');
      }

      // 1. Pehle Firebase Storage se saari photos udao
      for (String url in photoUrls) {
        try {
          if (url.isNotEmpty && url.contains('firebasestorage')) {
            final storageRef = FirebaseStorage.instance.refFromURL(url);
            await storageRef.delete();
          }
        } catch (e, st) {
          // ek photo delete fail hone se poora operation rukna nahi chahiye —
          // isliye yahan sirf log karte hain, rethrow nahi.
          AppLogger.error(
              'ListingRepository.deleteListingPermanently.photo', e, st);
        }
      }

      // 2. Uske baad Firestore se main room ka document udao
      await ref.delete();
    } catch (e, st) {
      AppLogger.error('ListingRepository.deleteListingPermanently', e, st);
      throw mapToAppException(e);
    }
  }

  /// SECURITY FIX: pehle koi bhi ek listing ko baar-baar report karke
  /// usko fraudulently 5-report threshold pe deactivate kara sakta tha
  /// (spam/abuse). Ab per-reporter dedupe hai — ek user ek listing
  /// sirf ek baar report kar sakta hai.
  Future<void> reportListing(String listingId, String reporterId) async {
    try {
      final ref = _db.collection('listings').doc(listingId);
      final reportDocRef = ref.collection('reports').doc(reporterId);

      await _db.runTransaction((txn) async {
        final reportSnap = await txn.get(reportDocRef);
        if (reportSnap.exists) {
          throw AppException('Aap yeh listing already report kar chuke hain.');
        }

        final snap = await txn.get(ref);
        if (!snap.exists) {
          throw AppException('Yeh listing ab maujood nahi hai.');
        }

        final newCount = ((snap.data()?['reportCount'] ?? 0) as int) + 1;
        txn.set(reportDocRef, {'reportedAt': FieldValue.serverTimestamp()});

        if (newCount >= 5) {
          txn.update(ref, {'reportCount': newCount, 'active': false});
        } else {
          txn.update(ref, {'reportCount': newCount});
        }
      });
    } catch (e, st) {
      AppLogger.error('ListingRepository.reportListing', e, st);
      throw mapToAppException(e);
    }
  }
}
