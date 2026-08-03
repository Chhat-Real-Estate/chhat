import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack; // NAYA: Parent tab change karne ke liye
  const ProfileScreen({super.key, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _name = '';
  String _phone = '';
  String _activeRole = 'tenant';
  List<dynamic> _roles = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      // Step 1: SharedPreferences se jo bhi hai turant dikhao (no "User" placeholder)
      final cachedName = prefs.getString('userName') ?? '';
      final cachedPhone = prefs.getString('userPhone') ?? '';
      final cachedRole = prefs.getString('userRole') ?? 'tenant';

      if (mounted) {
        setState(() {
          _name = cachedName;
          _phone = cachedPhone;
          _activeRole = cachedRole;
          _isLoading = false; // Spinner band — cached data se UI ready
        });
      }

      // Step 2: Firestore se fresh data background mein lao
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get()
            .timeout(const Duration(seconds: 5));

        if (doc.exists && mounted) {
          final data = doc.data()!;
          final freshName = data['name'] ?? cachedName;
          final freshPhone = data['phone'] ?? cachedPhone;
          final freshRole = data['activeRole'] ?? cachedRole;

          // Cache update karo for next time
          await prefs.setString('userName', freshName);
          await prefs.setString('userRole', freshRole);

          setState(() {
            _name = freshName;
            _phone = freshPhone;
            _activeRole = freshRole;
            _roles = data['roles'] ?? [];
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // YAHI HAI WOH MAIN LOGIC JO TENANT KO OWNER AUR OWNER KO TENANT BANAYEGA
  Future<void> _switchRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;
    if (!mounted) return;

    final targetRole = _activeRole == 'tenant' ? 'owner' : 'tenant';

    // FIX: Switch karne se pehle warning dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, // FIX: Pure white background
        surfaceTintColor: Colors.white, // FIX: Green tint hataya
        title: Text('Switch to ${targetRole.toUpperCase()}?',
            style: const TextStyle(color: Colors.black)),
        content: const Text(
            'Aap mode switch kar rahe hain. Naye mode me aapko alag dashboard aur features dikhenge. Kya aap sure hain?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Switch',
                style: TextStyle(
                    color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'activeRole': targetRole});
      if (mounted) {
        Navigator.pop(context);
        if (_roles.contains(targetRole)) {
          context.go('/$targetRole-home');
        } else {
          context.go('/$targetRole-onboarding');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to switch role')));
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) context.go('/phone');
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic color depending on active role
    final themeColor = _activeRole == 'tenant'
        ? const Color(0xFFC62828)
        : const Color(0xFF1A237E);

    if (_isLoading && _name.isEmpty && _phone.isEmpty) {
      return Scaffold(
          backgroundColor: const Color(0xFFF5F7F2),
          body: Center(
              child: CircularProgressIndicator(
                  color: Color(
                      0xFF1A237E))) // FIX: Loader hamesha Blueberry color me dikhega
          );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      body: Column(
        children: [
          // 1. Full-Bleed Top Header (Jaisa aap hamesha bolte ho)
          Container(
            padding:
                const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _activeRole == 'tenant'
                    ? [
                        const Color(0xFFC62828),
                        const Color(0xFFEF5350)
                      ] // Cherry Red
                    : [
                        const Color(0xFF1A237E),
                        const Color(0xFF3949AB)
                      ], // Blueberry
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                    color: themeColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Column(
              children: [
                // Custom AppBar inside Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        // FIX: Agar parent se onBack pass hua hai, toh direct Tab 0 par jao
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go('/$_activeRole-home');
                        }
                      },
                    ),
                    const Expanded(
                      child: Text('My Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
                const SizedBox(height: 20),
                // Profile Info
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: themeColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(_phone,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withOpacity(0.9))),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16)),
                            child: Text(
                              _activeRole.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rest of the body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // 2. Switch Role Button
                  GestureDetector(
                    onTap: _switchRole,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: themeColor.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.1),
                                shape: BoxShape.circle),
                            child: Icon(Icons.swap_horiz_rounded,
                                color: themeColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeRole == 'tenant'
                                      ? 'Switch to Owner'
                                      : 'Switch to Tenant',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A)),
                                ),
                                Text(
                                  _activeRole == 'tenant'
                                      ? 'Apna room kiraye pe dein'
                                      : 'Apne liye room khojein',
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF666666)),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.grey.shade400, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Action Tiles
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        _buildActionTile(Icons.person_outline, 'Basic Details',
                            () {
                          context.push('/edit-profile', extra: _activeRole);
                        }),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        // FIX: 'My Requirements' yahan se hata diya gaya hai
                        _buildActionTile(
                            Icons.help_outline, 'Grievance & Support', () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('Grievance & Support',
                                  style: TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.bold)),
                              content: const Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Grievance Officer: Pravin Kumar Jaiswal',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8),
                                  Text('Email: grievance@chhat.in',
                                      style: TextStyle(color: Colors.blue)),
                                  SizedBox(height: 16),
                                  Text(
                                      'DPDP Act 2023: Hum 90 dino ke andar aapki complaint resolve karenge.',
                                      style: TextStyle(
                                          color: Colors.black54,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 13)),
                                ],
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Close',
                                        style: TextStyle(color: Colors.grey))),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A1A1A)),
                                  onPressed: () {
                                    // Yahan url_launcher ka mailto: laga sakte ho
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Email Us',
                                      style: TextStyle(color: Colors.white)),
                                )
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        // NAYA: DPDP Data Export Button
                        _buildActionTile(
                            Icons.download_rounded, 'Download My Data', () {
                          context.push('/data-export');
                        }),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        // NAYA: Privacy Settings Button
                        _buildActionTile(Icons.security, 'Privacy Settings',
                            () {
                          context.push('/privacy-settings');
                        }),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        _buildActionTile(
                            Icons.description_outlined, 'Legal & Policies', () {
                          context.push('/privacy-policy'); // FIX: Added routing
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Danger Zone
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        _buildActionTile(Icons.logout, 'Logout', _logout,
                            isDestructive: true),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        _buildActionTile(Icons.delete_outline, 'Delete Account',
                            () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('Delete Account?',
                                  style: TextStyle(color: Colors.red)),
                              content: const Text(
                                  'Kya aap sachme apna account delete karna chahte hain? Aapka saara data hamesha ke liye delete ho jayega.',
                                  style: TextStyle(color: Colors.black87)),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel',
                                        style: TextStyle(color: Colors.grey))),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.white)),
                                )
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.red)));

                              final prefs =
                                  await SharedPreferences.getInstance();
                              final userId = prefs.getString('userId');

                              if (userId != null) {
                                // Mark user as deleted in Firestore (Hard delete can be done via Firebase Functions later)
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .update({
                                  'active': false,
                                  'deletedAt': FieldValue.serverTimestamp()
                                });
                              }

                              await AuthService().signOut();
                              await prefs.clear();

                              if (context.mounted) {
                                Navigator.pop(context); // Remove Loader
                                context.go('/phone'); // Redirect to Login
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Failed to delete account. Try again.'),
                                        backgroundColor: Colors.red));
                              }
                            }
                          }
                        }, isDestructive: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    final color =
        isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF1A1A1A);
    return ListTile(
      leading:
          Icon(icon, color: isDestructive ? color : const Color(0xFF666666)),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
