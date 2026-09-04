import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // FIX #31: 3-second freeze hataya — quick 800ms branding animation
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = AuthService.currentUserId ?? prefs.getString('userId');
    if (!mounted) return;

    if (userId != null && userId.isNotEmpty) {
      // Supabase se role fetch karo, phir seedha home pe bhejo
      try {
        final data = await Supabase.instance.client
            .from('users')
            .select('profile_complete, active_role, roles')
            .eq('id', userId)
            .maybeSingle();

        if (!mounted) return;
        if (data != null && data['profile_complete'] == true) {
          final role = data['active_role'];
          if (role != null && role.toString().isNotEmpty) {
            context.go('/$role-home');
            return;
          }
        }
      } catch (_) {}
      if (!mounted) return;
      context.go('/role');
    } else {
      context.go('/phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2), // NAYA: Light Theme Background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Tera Naya Logo Asset
            Image.asset(
              'assets/images/chhat_logo.png',
              width: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.maps_home_work_rounded,
                size: 100,
                color: Color(0xFF2D6A4F),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Naya English Slogan
            const Text(
              'Find Rooms, Not Brokers.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A), // NAYA: Dark Text for Light Theme
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // 3. CHA🔑 - Room Rent Text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'CHHA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666), // NAYA: Grey Text for Light Theme
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Icon(
                    Icons.key,
                    color: Color(0xFF666666), // NAYA: Grey Icon for Light Theme
                    size: 20,
                  ),
                ),
                const Text(
                  '- Room Rent',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666), // NAYA: Grey Text for Light Theme
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D6A4F)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
