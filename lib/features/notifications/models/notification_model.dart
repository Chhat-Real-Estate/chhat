import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String userId;
  final String title;
  final String body;
  final String
      type; // 'request_accepted', 'request_rejected', 'new_request', 'broadcast'
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.read = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': read,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['createdAt'];
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'broadcast',
      read: map['read'] ?? false,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
