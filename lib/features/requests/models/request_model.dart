import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String? id;
  final String tenantId;
  final String tenantPhone;
  final String listingId;
  final String ownerId;
  final String area;
  final int rent;
  final String status; // pending, accepted, rejected
  final String senderType; // FIX: Ye database me jana zaroori tha
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
    this.senderType = 'tenant', // Default
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'tenantPhone': tenantPhone,
      'listingId': listingId,
      'ownerId': ownerId,
      'area': area,
      'rent': rent,
      'status': status,
      'senderType': senderType, // FIX: Ab database me save hoga
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map, String id) {
    return RequestModel(
      id: id,
      tenantId: map['tenantId'] ?? '',
      tenantPhone: map['tenantPhone'] ?? '',
      listingId: map['listingId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      area: map['area'] ?? '',
      rent: map['rent'] ?? 0,
      status: map['status'] ?? 'pending',
      senderType: map['senderType'] ?? 'tenant', // FIX: Read from DB
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
