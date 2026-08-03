import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = true;
  bool _consentActive = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');

      if (_userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            // Agar pehle se flag nahi hai, to default true manenge
            _consentActive = doc.data()!.containsKey('consentActive')
                ? doc.data()!['consentActive']
                : true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleConsent(bool value) async {
    setState(() => _consentActive = value);
    if (_userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'consentActive': value,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value
              ? 'Profile visible to others.'
              : 'Profile hidden from others.'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ));
      }
    }
  }

  Future<void> _withdrawConsent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Withdraw Consent?',
            style:
                TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        content: const Text(
          'Agar aap consent withdraw karte hain, toh aapki profile search aur matching se hide ho jayegi, par aapka account aur current requests delete nahi honge. Kya aap sure hain?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Withdraw', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _toggleConsent(false);
    }
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete All My Data?',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'WARNING: Ye action wapas nahi liya jaa sakta. Aapka saara data (Profile, Rooms, Requests) hamesha ke liye delete ho jayega.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Data',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
                child: CircularProgressIndicator(color: Colors.red)));

        if (_userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .update({
            'active': false,
            'consentActive': false,
            'deletedAt': FieldValue.serverTimestamp()
          });
        }

        await AuthService().signOut();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (context.mounted) {
          Navigator.pop(context); // Remove Loader
          context.go('/phone'); // Redirect to Login
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to delete data. Check internet.'),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text('Privacy Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop()),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage Your Privacy (DPDP Act)',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text(
                      'Aapka data aapke control me hai. Yahan se aap apni profile visibility aur account data manage kar sakte hain.',
                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 24),

                  // Toggle Section
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF2D6A4F),
                      title: const Text('Profile Visibility',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: const Text(
                          'Allow profile to be visible to Owners/Tenants.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      value: _consentActive,
                      onChanged: _toggleConsent,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Withdraw Consent Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _consentActive ? _withdrawConsent : null,
                      icon: const Icon(Icons.security, color: Colors.orange),
                      label: const Text('Withdraw Consent',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Text(
                        'Withdrawing consent hides you from new matches, but does not affect requests already in progress.',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 32),

                  // Hard Delete Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _deleteAllData,
                      icon:
                          const Icon(Icons.delete_forever, color: Colors.white),
                      label: const Text('Delete All My Data',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
