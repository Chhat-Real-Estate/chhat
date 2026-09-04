import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

      final supabase = Supabase.instance.client;
      StringBuffer report = StringBuffer();

      report.writeln('====================================');
      report.writeln('       CHHAT APP - MY DATA          ');
      report.writeln('====================================');
      report.writeln(
          'Generated on: ${DateTime.now().toString().substring(0, 16)}');
      report.writeln('User ID: $userId\n');

      // 1. Fetch User Data
      final uData = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      String activeRole = 'tenant';
      if (uData != null) {
        activeRole = uData['active_role'] ?? 'tenant';
        report.writeln('--- ACCOUNT DETAILS ---');
        report.writeln('Phone Number: ${uData['phone'] ?? 'N/A'}');
        report.writeln('Active Role: ${activeRole.toUpperCase()}');

        final consentDate = uData['consent_given_at'];
        if (consentDate != null) {
          report.writeln('DPDP Consent Given: $consentDate');
        }
        report.writeln('Consent Version: ${uData['consent_version'] ?? '1.0'}\n');
      }

      // 2. Fetch Profile Data
      final profileTable =
          activeRole == 'owner' ? 'owner_profiles' : 'tenant_profiles';
      final pData = await supabase
          .from(profileTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      report.writeln('--- PERSONAL PROFILE ($activeRole) ---');
      if (pData != null) {
        pData.forEach((key, value) {
          if (key != 'created_at' && key != 'updated_at') {
            report.writeln('$key: $value');
          }
        });
      } else {
        report.writeln('Profile incomplete or not found.');
      }
      report.writeln('');

      // 3. Fetch Requests
      final requestKey = activeRole == 'tenant' ? 'tenant_id' : 'owner_id';
      final requests = await supabase
          .from('requests')
          .select()
          .eq(requestKey, userId);

      report.writeln('--- MY REQUESTS ---');
      if ((requests as List).isEmpty) {
        report.writeln('No requests found.');
      } else {
        report.writeln('Total Requests: ${requests.length}');
        for (var rData in requests) {
          report.writeln(
              '- Room: ${rData['area'] ?? 'Unknown'}, Rent: ₹${rData['rent']}, Status: ${rData['status']}, Sent by: ${rData['sender_type']}');
        }
      }
      report.writeln('');

      // 4. Fetch Listings (If Owner)
      if (activeRole == 'owner') {
        final listings = await supabase
            .from('listings')
            .select()
            .eq('owner_id', userId);

        report.writeln('--- MY LISTINGS ---');
        if ((listings as List).isEmpty) {
          report.writeln('No listings found.');
        } else {
          report.writeln('Total Listings: ${listings.length}');
          for (var rData in listings) {
            report.writeln(
                '- Room: ${rData['area'] ?? 'Unknown'}, Rent: ₹${rData['rent']}, Active: ${rData['active']}');
          }
        }
        report.writeln('');
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
