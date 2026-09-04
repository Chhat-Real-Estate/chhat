import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';

class ReportRepository {
  static Future<void> submitReport({
    required String reporterId,
    required String reportedUserId,
    required String reportType,
    String? listingId,
    String? additionalInfo,
  }) async {
    final currentUserId = AuthService.currentUserId ??
        FirebaseAuth.instance.currentUser?.uid ??
        Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == null || currentUserId != reporterId) {
      throw Exception('Unauthorized: You can only submit reports as yourself.');
    }

    try {
      await Supabase.instance.client.from('reports').insert({
        'reporter_id': reporterId,
        'reported_user_id': reportedUserId,
        'report_type': reportType,
        'listing_id': listingId,
        'status': 'pending',
        'additional_info': additionalInfo ?? '',
      });
    } catch (e) {
      throw Exception('Report submit karne me error aayi: $e');
    }
  }
}
