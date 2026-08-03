import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:go_router/go_router.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _loading = true;
  String _exportedData = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _generateDataReport();
  }

  Future<void> _generateDataReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('User ID nahi mila. Kripya dobara login karein.');
      }

      final db = FirebaseFirestore.instance;
      StringBuffer report = StringBuffer();

      report.writeln('====================================');
      report.writeln('       CHHAT APP - MY DATA          ');
      report.writeln('====================================');
      report.writeln(
          'Generated on: ${DateTime.now().toString().substring(0, 16)}');
      report.writeln('User ID: $userId\n');

      // 1. Fetch User Data (Phone, Consent)
      final userDoc = await db.collection('users').doc(userId).get();
      String activeRole = 'tenant';
      if (userDoc.exists) {
        final uData = userDoc.data()!;
        activeRole = uData['activeRole'] ?? uData['role'] ?? 'tenant';
        report.writeln('--- ACCOUNT DETAILS ---');
        report.writeln('Phone Number: ${uData['phone'] ?? 'N/A'}');
        report.writeln('Active Role: ${activeRole.toUpperCase()}');

        final consentDate = uData['consentGivenAt'];
        if (consentDate != null) {
          if (consentDate is Timestamp) {
            report.writeln(
                'DPDP Consent Given: ${consentDate.toDate().toString().substring(0, 16)}');
          } else if (consentDate is String) {
            report.writeln('DPDP Consent Given: $consentDate');
          }
        }
        report
            .writeln('Consent Version: ${uData['consentVersion'] ?? '1.0'}\n');
      }

      // 2. Fetch Profile Data (Tenant or Owner)
      final profileCollection =
          activeRole == 'owner' ? 'ownerProfiles' : 'tenantProfiles';
      final profileDoc =
          await db.collection(profileCollection).doc(userId).get();

      report.writeln('--- PERSONAL PROFILE ($activeRole) ---');
      if (profileDoc.exists) {
        final pData = profileDoc.data()!;
        pData.forEach((key, value) {
          if (key != 'createdAt' && key != 'updatedAt') {
            report.writeln('$key: $value');
          }
        });
      } else {
        report.writeln('Profile incomplete or not found.');
      }
      report.writeln('');

      // 3. Fetch Requests (Both Sent and Incoming)
      final requestsSnap = await db
          .collection('requests')
          .where(activeRole == 'tenant' ? 'tenantId' : 'ownerId',
              isEqualTo: userId)
          .get();

      report.writeln('--- MY REQUESTS ---');
      if (requestsSnap.docs.isEmpty) {
        report.writeln('No requests found.');
      } else {
        report.writeln('Total Requests: ${requestsSnap.docs.length}');
        for (var doc in requestsSnap.docs) {
          final rData = doc.data();
          report.writeln(
              '- Room: ${rData['area'] ?? 'Unknown'}, Rent: ₹${rData['rent']}, Status: ${rData['status']}, Sent by: ${rData['senderType']}');
        }
      }
      report.writeln('');

      // 4. Fetch Listings (If Owner)
      if (activeRole == 'owner') {
        final listingsSnap = await db
            .collection('listings')
            .where('ownerId', isEqualTo: userId)
            .get();

        report.writeln('--- MY LISTINGS ---');
        if (listingsSnap.docs.isEmpty) {
          report.writeln('No listings found.');
        } else {
          report.writeln('Total Listings: ${listingsSnap.docs.length}');
          for (var doc in listingsSnap.docs) {
            final lData = doc.data();
            report.writeln(
                '- ${lData['propertyCategory']} in ${lData['area']} (₹${lData['rent']}/month) - Status: ${lData['active'] == true ? 'Active' : 'Inactive'}');
          }
        }
      }

      report.writeln('\n====================================');
      report.writeln('End of Data Report');
      report.writeln('====================================');

      if (mounted) {
        setState(() {
          _exportedData = report.toString();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _exportedData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Data copied to clipboard!'),
          backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text('Download My Data',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text('Error: $_errorMessage',
                      style: const TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'DPDP Act 2023 ke tehat ye aapka poora personal data hai jo Chhat app par save hai.',
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _exportedData,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy, color: Colors.white),
                          label: const Text('Copy My Data',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
    );
  }
}
