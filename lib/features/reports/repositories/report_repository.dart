import 'package:cloud_firestore/cloud_firestore.dart';

class ReportRepository {
  static Future<void> submitReport({
    required String reporterId,
    required String reportedUserId,
    required String reportType, // 'fake_listing', 'agent_spam', etc.
    String? listingId,
    String? additionalInfo,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reportType': reportType,
        'listingId': listingId,
        'status': 'pending', // pending, reviewed, banned
        'additionalInfo': additionalInfo ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Report submit karne me error aayi: $e');
    }
  }
}
