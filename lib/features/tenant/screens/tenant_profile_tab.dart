import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TenantProfileTab extends StatelessWidget {
  const TenantProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC62828),
        elevation: 0,
        title: const Text('My Info',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<String?>(
        future: SharedPreferences.getInstance()
            .then((prefs) => prefs.getString('userId')),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFC62828)));
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('tenant_profiles')
                .stream(primaryKey: ['user_id'])
                .eq('user_id', snapshot.data!),
            builder: (context, docSnap) {
              if (!docSnap.hasData)
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC62828)));
              final data = docSnap.data!.isNotEmpty ? docSnap.data!.first : <String, dynamic>{};

              int filled = 0;
              if (data['name'] != null &&
                  data['name'].toString().trim().isNotEmpty) filled += 20;
              if (data['age'] != null &&
                  data['age'].toString().trim().isNotEmpty) filled += 20;
              if (data['occupation'] != null &&
                  data['occupation'].toString().trim().isNotEmpty) filled += 20;
              if (data['propertyRequirements'] != null &&
                  (data['propertyRequirements'] as List).isNotEmpty)
                filled += 20;
              if (data['budgetRange'] != null &&
                  data['budgetRange'].toString().trim().isNotEmpty)
                filled += 20;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Profile Completion',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87)),
                              Text('$filled%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC62828),
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                              value: filled / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: const Color(0xFFC62828),
                              minHeight: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Personal Details',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        TextButton.icon(
                          onPressed: () =>
                              context.push('/edit-profile', extra: 'tenant'),
                          icon: const Icon(Icons.edit,
                              size: 16, color: Color(0xFFC62828)),
                          label: const Text('Edit',
                              style: TextStyle(
                                  color: Color(0xFFC62828),
                                  fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          _buildDetailRow(
                              'Name', data['name']?.toString() ?? 'N/A'),
                          _buildDetailRow('Age & Gender',
                              '${data['age']?.toString() ?? 'N/A'} - ${data['gender']?.toString() ?? 'N/A'}'),
                          _buildDetailRow(
                              'City', data['city']?.toString() ?? 'N/A'),
                          _buildDetailRow(
                              'Area', data['area']?.toString() ?? 'N/A'),
                          _buildDetailRow(
                              'Sub-Area', data['subArea']?.toString() ?? 'N/A'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Requirements',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        TextButton.icon(
                          onPressed: () => context.push('/tenant-requirements'),
                          icon: const Icon(Icons.edit,
                              size: 16, color: Color(0xFFC62828)),
                          label: const Text('Edit',
                              style: TextStyle(
                                  color: Color(0xFFC62828),
                                  fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          if ((data['propertyKind']?.toString() ??
                                  'residential') ==
                              'residential')
                            _buildDetailRow('Occupation',
                                data['occupation']?.toString() ?? 'N/A'),
                          _buildDetailRow('Tenant Type',
                              data['tenantType']?.toString() ?? 'N/A'),
                          _buildDetailRow('Move-In Date',
                              data['moveInDate']?.toString() ?? 'N/A'),
                          _buildDetailRow('Budget',
                              data['budgetRange']?.toString() ?? 'N/A'),
                          _buildDetailRow(
                              'Looking For',
                              (data['propertyRequirements'] as List<dynamic>? ??
                                      [])
                                  .join(', ')),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500))),
          Expanded(
              child: Text(val.isEmpty ? 'N/A' : val,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87))),
        ],
      ),
    );
  }
}
