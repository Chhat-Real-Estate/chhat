class RequestModel {
  final String? id;
  final String tenantId;
  final String tenantPhone;
  final String listingId;
  final String ownerId;
  final String area;
  final int rent;
  final String status; // pending, accepted, rejected
  final String senderType;
  final DateTime createdAt;

  RequestModel({
    this.id,
    required this.tenantId,
    required this.tenantPhone,
    required this.listingId,
    required this.ownerId,
    required this.area,
    required this.rent,
    this.status = 'pending',
    this.senderType = 'tenant',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'tenant_phone': tenantPhone,
      'listing_id': listingId,
      'owner_id': ownerId,
      'area': area,
      'rent': rent,
      'status': status,
      'sender_type': senderType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return RequestModel(
      id: id,
      tenantId: (map['tenant_id'] ?? map['tenantId'])?.toString() ?? '',
      tenantPhone: (map['tenant_phone'] ?? map['tenantPhone'])?.toString() ?? '',
      listingId: (map['listing_id'] ?? map['listingId'])?.toString() ?? '',
      ownerId: (map['owner_id'] ?? map['ownerId'])?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      rent: (map['rent'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'pending',
      senderType: (map['sender_type'] ?? map['senderType'])?.toString() ?? 'tenant',
      createdAt: parseDateTime(map['created_at'] ?? map['createdAt']),
    );
  }
}
