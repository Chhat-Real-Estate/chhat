import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String phone;
  final String name;
  final String role; // 'owner' ya 'tenant'
  final String tenantType; // single, family, group, worker, student
  final String area;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.tenantType = '',
    this.area = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'role': role,
      'tenantType': tenantType,
      'area': area,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      tenantType: map['tenantType'] ?? '',
      area: map['area'] ?? '',
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
