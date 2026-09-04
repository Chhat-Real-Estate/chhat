import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request_model.dart';
import '../../../core/utils/app_logger.dart';

class RequestRepository {
  final SupabaseClient _client;
  RequestRepository({SupabaseClient? client, dynamic firestore})
      : _client = client ?? Supabase.instance.client;

  // Send request
  Future<void> sendRequest(RequestModel request) async {
    try {
      // Check duplicate
      final existing = await _client
          .from('requests')
          .select('id')
          .eq('tenant_id', request.tenantId)
          .eq('listing_id', request.listingId)
          .eq('sender_type', request.senderType)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Aapne pehle se request bheji hai');
      }

      await _client.from('requests').insert(request.toMap());
    } catch (e, st) {
      AppLogger.error('RequestRepository.sendRequest', e, st);
      rethrow;
    }
  }

  // Owner incoming requests (sent by tenant)
  Stream<List<RequestModel>> getOwnerRequests(String ownerId) {
    return _client
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .where((item) => item['sender_type'] == 'tenant')
            .map((item) => RequestModel.fromMap(item, item['id'].toString()))
            .toList())
        .handleError((error) {
      AppLogger.error('RequestRepository.getOwnerRequests', error, null);
      return <RequestModel>[];
    });
  }

  // Owner sent requests (sent by owner)
  Stream<List<RequestModel>> getOwnerSentRequests(String ownerId) {
    return _client
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .where((item) => item['sender_type'] == 'owner')
            .map((item) => RequestModel.fromMap(item, item['id'].toString()))
            .toList())
        .handleError((error) {
      AppLogger.error('RequestRepository.getOwnerSentRequests', error, null);
      return <RequestModel>[];
    });
  }

  // Tenant incoming requests (sent by owner)
  Stream<List<RequestModel>> getTenantIncomingRequests(String tenantId) {
    return _client
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .where((item) => item['sender_type'] == 'owner')
            .map((item) => RequestModel.fromMap(item, item['id'].toString()))
            .toList())
        .handleError((error) {
      AppLogger.error('RequestRepository.getTenantIncomingRequests', error, null);
      return <RequestModel>[];
    });
  }

  // Tenant sent requests (sent by tenant)
  Stream<List<RequestModel>> getTenantSentRequests(String tenantId) {
    return _client
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .where((item) => item['sender_type'] == 'tenant')
            .map((item) => RequestModel.fromMap(item, item['id'].toString()))
            .toList())
        .handleError((error) {
      AppLogger.error('RequestRepository.getTenantSentRequests', error, null);
      return <RequestModel>[];
    });
  }

  // Update request status (accept / reject)
  Future<void> updateRequestStatus(
    String requestId,
    String status,
    String requesterId, {
    String? tenantPhone,
  }) async {
    try {
      final doc = await _client
          .from('requests')
          .select('owner_id, tenant_id')
          .eq('id', requestId)
          .maybeSingle();

      if (doc == null) {
        throw Exception('Request nahi mili');
      }

      if (doc['owner_id'] != requesterId && doc['tenant_id'] != requesterId) {
        throw Exception('Aapko is request ko update karne ki permission nahi hai');
      }

      final updateData = <String, dynamic>{
        'status': status,
        'responded_by': requesterId,
        'responded_at': DateTime.now().toIso8601String(),
      };

      if (tenantPhone != null && tenantPhone.isNotEmpty) {
        updateData['tenant_phone'] = tenantPhone;
      }

      await _client.from('requests').update(updateData).eq('id', requestId);
    } catch (e, st) {
      AppLogger.error('RequestRepository.updateRequestStatus', e, st);
      rethrow;
    }
  }

  // Delete request
  Future<void> deleteRequest(String requestId, String requesterId) async {
    try {
      final doc = await _client
          .from('requests')
          .select('owner_id, tenant_id')
          .eq('id', requestId)
          .maybeSingle();

      if (doc == null) return;

      if (doc['owner_id'] != requesterId && doc['tenant_id'] != requesterId) {
        throw Exception('Aapko is request ko delete karne ki permission nahi hai');
      }

      await _client.from('requests').delete().eq('id', requestId);
    } catch (e, st) {
      AppLogger.error('RequestRepository.deleteRequest', e, st);
      throw Exception('Request delete karne me error aayi: $e');
    }
  }
}
