class NotificationModel {
  final String? id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'request_accepted', 'request_rejected', 'new_request', 'broadcast'
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
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return NotificationModel(
      id: id,
      userId: (map['user_id'] ?? map['userId'])?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'broadcast',
      read: map['read'] == true,
      createdAt: parseDateTime(map['created_at'] ?? map['createdAt']),
    );
  }
}
