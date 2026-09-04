import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/listing_model.dart';
import '../../../core/utils/app_exceptions.dart';
import '../../../core/utils/app_logger.dart';

const int kListingsPageSize = 20;

class ListingRepository {
  final SupabaseClient _client;
  ListingRepository({SupabaseClient? client, dynamic firestore})
      : _client = client ?? Supabase.instance.client;

  // Listing create karo
  Future<String> createListing(ListingModel listing) async {
    try {
      // Anti-dalal check — ek number se max 3 listings
      final existing = await _client
          .from('listings')
          .select('id')
          .eq('phone', listing.phone)
          .eq('active', true)
          .limit(3);

      if ((existing as List).length >= 3) {
        throw AppException('Aap already 3 rooms list kar chuke ho');
      }

      final res = await _client
          .from('listings')
          .insert(listing.toMap())
          .select('id')
          .single();

      return res['id'].toString();
    } catch (e, st) {
      AppLogger.error('ListingRepository.createListing', e, st);
      throw mapToAppException(e);
    }
  }

  // Owner ki listings stream (Realtime)
  Stream<List<ListingModel>> getOwnerListings(
    String ownerId, {
    int limit = kListingsPageSize,
  }) {
    return _client
        .from('listings')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) => data
            .where((item) => item['active'] == true)
            .map((item) => ListingModel.fromMap(item, item['id'].toString()))
            .toList())
        .handleError((e, st) {
      AppLogger.error('ListingRepository.getOwnerListings', e, st);
    });
  }

  // Nearby listings stream
  Stream<List<ListingModel>> getNearbyListings(
    String area, {
    int limit = 50,
  }) {
    final stream = _client
        .from('listings')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit);

    return stream.map((data) {
      final normalizedArea = area.toLowerCase().trim();
      return data
          .where((item) =>
              item['active'] == true &&
              (normalizedArea.isEmpty ||
                  (item['area'] ?? '').toString().toLowerCase().trim() ==
                      normalizedArea))
          .map((item) => ListingModel.fromMap(item, item['id'].toString()))
          .toList();
    }).handleError((e, st) {
      AppLogger.error('ListingRepository.getNearbyListings', e, st);
      throw e;
    });
  }

  // Search listings stream
  Stream<List<ListingModel>> searchListings({
    required String propertyKind,
    String search = '',
    int limit = 50,
  }) {
    final stream = _client
        .from('listings')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit);

    return stream.map((data) {
      final trimmed = search.toLowerCase().trim();
      return data
          .where((item) {
            final matchesActive = item['active'] == true;
            final matchesKind =
                (item['property_kind'] ?? 'residential') == propertyKind;
            if (!matchesActive || !matchesKind) return false;
            if (trimmed.isEmpty) return true;

            final keywords =
                List<String>.from(item['search_keywords'] ?? const []);
            final words = trimmed.split(RegExp(r'\s+'));
            return words.any((word) => keywords.contains(word));
          })
          .map((item) => ListingModel.fromMap(item, item['id'].toString()))
          .toList();
    }).handleError((e, st) {
      AppLogger.error('ListingRepository.searchListings', e, st);
      throw e;
    });
  }

  // Deactivate listing
  Future<void> deactivateListing(String listingId, String requesterId) async {
    try {
      final res = await _client
          .from('listings')
          .select('owner_id')
          .eq('id', listingId)
          .maybeSingle();

      if (res == null) {
        throw AppException('Yeh listing ab maujood nahi hai.');
      }
      if (res['owner_id'] != requesterId) {
        throw AppException('Aap sirf apni listings deactivate kar sakte hain.');
      }

      await _client
          .from('listings')
          .update({'active': false}).eq('id', listingId);
    } catch (e, st) {
      AppLogger.error('ListingRepository.deactivateListing', e, st);
      throw mapToAppException(e);
    }
  }

  // Permanent Delete (Database + Storage)
  Future<void> deleteListingPermanently(
    String listingId,
    List<String> photoUrls,
    String requesterId,
  ) async {
    try {
      final res = await _client
          .from('listings')
          .select('owner_id')
          .eq('id', listingId)
          .maybeSingle();

      if (res == null) {
        throw AppException('Yeh listing ab maujood nahi hai.');
      }
      if (res['owner_id'] != requesterId) {
        throw AppException('Aap sirf apni listings delete kar sakte hain.');
      }

      // 1. Storage se images delete karo
      for (final url in photoUrls) {
        try {
          final uri = Uri.parse(url);
          final segments = uri.pathSegments;
          final listingsIndex = segments.indexOf('listings');
          if (listingsIndex != -1 && listingsIndex + 1 < segments.length) {
            final path = segments.sublist(listingsIndex + 1).join('/');
            await _client.storage.from('listings').remove([path]);
          }
        } catch (e, st) {
          AppLogger.error('ListingRepository.deleteListingPermanently.photo', e, st);
        }
      }

      // 2. Database row delete karo
      await _client.from('listings').delete().eq('id', listingId);
    } catch (e, st) {
      AppLogger.error('ListingRepository.deleteListingPermanently', e, st);
      throw mapToAppException(e);
    }
  }

  // Report listing
  Future<void> reportListing(String listingId, String reporterId) async {
    try {
      // 1. Check if already reported
      final existing = await _client
          .from('listing_reports')
          .select('reported_at')
          .eq('listing_id', listingId)
          .eq('reporter_id', reporterId)
          .maybeSingle();

      if (existing != null) {
        throw AppException('Aap yeh listing already report kar chuke hain.');
      }

      // 2. Insert report dedupe record
      await _client.from('listing_reports').insert({
        'listing_id': listingId,
        'reporter_id': reporterId,
      });

      // 3. Increment report_count on listing
      final listing = await _client
          .from('listings')
          .select('report_count')
          .eq('id', listingId)
          .single();

      final currentCount = (listing['report_count'] as int? ?? 0) + 1;
      final updates = <String, dynamic>{'report_count': currentCount};
      if (currentCount >= 5) {
        updates['active'] = false;
      }

      await _client.from('listings').update(updates).eq('id', listingId);
    } catch (e, st) {
      AppLogger.error('ListingRepository.reportListing', e, st);
      throw mapToAppException(e);
    }
  }
}
