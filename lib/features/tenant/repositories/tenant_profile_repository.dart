import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/app_exceptions.dart';
import '../../../core/utils/app_logger.dart';

class TenantProfileRepository {
  final SupabaseClient _client;
  TenantProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>?> getTenantProfile(String userId) async {
    try {
      final res = await _client
          .from('tenant_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return res;
    } catch (e, st) {
      AppLogger.error('TenantProfileRepository.getTenantProfile', e, st);
      throw mapToAppException(e);
    }
  }

  Future<void> saveTenantProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      payload['user_id'] = userId;
      await _client.from('tenant_profiles').upsert(payload);
    } catch (e, st) {
      AppLogger.error('TenantProfileRepository.saveTenantProfile', e, st);
      throw mapToAppException(e);
    }
  }

  Future<void> updateTenantProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _client
          .from('tenant_profiles')
          .update(data)
          .eq('user_id', userId);
    } catch (e, st) {
      AppLogger.error('TenantProfileRepository.updateTenantProfile', e, st);
      throw mapToAppException(e);
    }
  }

  Stream<Map<String, dynamic>?> watchTenantProfile(String userId) {
    return _client
        .from('tenant_profiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) => data.isNotEmpty ? data.first : null)
        .handleError((e, st) {
      AppLogger.error('TenantProfileRepository.watchTenantProfile', e, st);
    });
  }
}
