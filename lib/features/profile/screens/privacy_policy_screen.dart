import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A), // Neutral Dark
        elevation: 0,
        title: const Text('Privacy Policy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Privacy Policy & DPDP Act Compliance',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              Text(
                  'Last updated: ${DateTime.now().toString().substring(0, 10)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(height: 32),
              _buildSection(
                '1. Data We Collect & Its Purpose',
                'To provide you with the best experience, we collect specific information:\n\n'
                    '• Phone Number: For OTP verification and secure communication between owners and tenants.\n'
                    '• Name, Age, Gender, Occupation: To build authentic tenant/owner profiles for safe matching.\n'
                    '• Location & Budget: To show you the most relevant room listings.\n'
                    '• Photos: Uploaded by owners strictly to showcase their properties.',
              ),
              _buildSection(
                '2. Data Retention Policy',
                'We only keep your data as long as necessary:\n\n'
                    '• Room Listings: Automatically expire and are hidden after 30 days.\n'
                    '• Inactive Profiles: If you do not use the app for 180 days, your profile will be soft-deleted to protect your privacy.',
              ),
              _buildSection(
                '3. Your Rights (DPDP Act 2023)',
                'Under India\'s Digital Personal Data Protection Act, you have the right to:\n'
                    '• Access a summary of the personal data we hold about you.\n'
                    '• Request corrections to your data.\n'
                    '• Request the erasure of your data.',
              ),
              _buildSection(
                '4. Consent Withdrawal & Deletion',
                'You have full control over your data. You can withdraw your consent at any time via the "Privacy Settings" (coming soon) which will hide your profile from new matches. Alternatively, you can permanently erase all your data, listings, and requests instantly using the "Delete Account" button in your profile.',
              ),
              _buildSection(
                '5. Grievance Redressal',
                'If you have any complaints regarding your personal data processing, please contact our Grievance Officer:\n\n'
                    'Email: grievance@chhat.in\n'
                    'Response Time: We are committed to resolving your complaints within 90 days as mandated by law.',
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('By using Chhat, you agree to these terms.',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      Color(0xFFC62828))), // Cherry Red highlight for headers
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87, height: 1.5)),
        ],
      ),
    );
  }
}
