import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../../../core/utils/app_logger.dart';

class RequestRepository {
  final FirebaseFirestore _db;
  RequestRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // Request bheje (Tenant ya Owner)
  // FIX: TOCTOU race — pehle check + add alag calls the, rapid double-tap se
  // duplicate ban sakti thi. Ab deterministic doc ID + transaction se atomic
  // hai — dusri baar wahi ID pe write hi nahi hoga.
  Future<void> sendRequest(RequestModel request) async {
    final docId =
        '${request.tenantId}_${request.listingId}_${request.senderType}';
    final docRef = _db.collection('requests').doc(docId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        throw Exception('Aapne pehle se request bheji hai');
      }
      transaction.set(docRef, request.toMap());
    });
  }

  // Owner ki saari incoming requests (Jo sirf TENANT ne bheji hain)
  Stream<List<RequestModel>> getOwnerRequests(String ownerId) {
    return _db
        .collection('requests')
        .where('ownerId', isEqualTo: ownerId)
        .where('senderType', isEqualTo: 'tenant')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Owner ki Sent requests (Jo sirf OWNER ne khud bheji hain)
  Stream<List<RequestModel>> getOwnerSentRequests(String ownerId) {
    return _db
        .collection('requests')
        .where('ownerId', isEqualTo: ownerId)
        .where('senderType', isEqualTo: 'owner')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Tenant ki INCOMING requests (Jo OWNER ne bheji hain)
  Stream<List<RequestModel>> getTenantIncomingRequests(String tenantId) {
    return _db
        .collection('requests')
        .where('tenantId', isEqualTo: tenantId)
        .where('senderType', isEqualTo: 'owner')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((error) {
      AppLogger.error(
          'RequestRepository.getOwnerIncomingRequests', error, null);
      return <RequestModel>[];
    });
  }

  // Tenant ki SENT requests (Jo TENANT ne khud bheji hain)
  Stream<List<RequestModel>> getTenantSentRequests(String tenantId) {
    return _db
        .collection('requests')
        .where('tenantId', isEqualTo: tenantId)
        .where('senderType', isEqualTo: 'tenant')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((error) {
      AppLogger.error('RequestRepository.getTenantSentRequests', error, null);
      return <RequestModel>[];
    });
  }

  // Owner accept/reject kare — SECURITY FIX (IDOR): sirf ownerId ya tenantId
  // wala hi apni request update kar sakta hai
  Future<void> updateRequestStatus(
      String requestId, String status, String requesterId,
      {String? tenantPhone}) async {
    final doc = await _db.collection('requests').doc(requestId).get();
    if (!doc.exists) {
      throw Exception('Request nahi mili');
    }
    final data = doc.data()!;
    if (data['ownerId'] != requesterId && data['tenantId'] != requesterId) {
      throw Exception(
          'Aapko is request ko update karne ki permission nahi hai');
    }
    final updateData = <String, dynamic>{
      'status': status,
      'respondedBy': requesterId,
      'respondedAt': FieldValue.serverTimestamp(),
    };
    // FIX: Owner ne invite bheja tha to tenantPhone 'Hidden' save hua tha
    // (owner ko tenant ka number pata nahi hota). Ab tenant khud accept
    // kar raha hai, to apna asli number yahin fill kar do taaki owner
    // baad me call kar sake.
    if (tenantPhone != null && tenantPhone.isNotEmpty) {
      updateData['tenantPhone'] = tenantPhone;
    }
    await doc.reference.update(updateData);
  }

  // NAYA: Request Delete karo (Dono side se permanently gayab ho jayegi)
  // SECURITY FIX (IDOR): sirf ownerId ya tenantId wala hi delete kar sakta hai
  Future<void> deleteRequest(String requestId, String requesterId) async {
    try {
      final doc = await _db.collection('requests').doc(requestId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      if (data['ownerId'] != requesterId && data['tenantId'] != requesterId) {
        throw Exception(
            'Aapko is request ko delete karne ki permission nahi hai');
      }
      await doc.reference.delete();
    } catch (e) {
      throw Exception('Request delete karne me error aayi: $e');
    }
  }
}
