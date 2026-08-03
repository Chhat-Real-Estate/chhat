import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/app_exceptions.dart';
import '../../../core/utils/app_logger.dart';

class TenantProfileRepository {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getTenantProfile(String userId) async {
    try {
      final doc = await _db.collection('tenantProfiles').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e, st) {
      AppLogger.error('TenantProfileRepository.getTenantProfile', e, st);
      throw mapToAppException(e);
    }
  }

  Future<void> saveTenantProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _db
          .collection('tenantProfiles')
          .doc(userId)
          .set(data, SetOptions(merge: true));
    } catch (e, st) {
      AppLogger.error('TenantProfileRepository.saveTenantProfile', e, st);
      throw mapToAppException(e);
    }
  }

  Future<void> updateTenantProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _db.collection('tenantProfiles').doc(userId).update(data);
    } catch (e, st) {
      AppLogger.error('TenantProfileRepository.updateTenantProfile', e, st);
      throw mapToAppException(e);
    }
  }

  Stream<DocumentSnapshot> watchTenantProfile(String userId) {
    return _db.collection('tenantProfiles').doc(userId).snapshots().handleError(
        (e, st) {
      AppLogger.error('TenantProfileRepository.watchTenantProfile', e, st);
    });
  }
}
