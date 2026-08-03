import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    // 2-3 second ka splash delay
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // FIX: Firebase ka apna session state authoritative source hai —
    // sirf SharedPreferences pe depend karne se stale/mismatched state ka
    // risk tha. Agar Firebase session hi nahi hai to userId cache pe
    // bharosa mat karo.
    final currentUser = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final userId = currentUser?.uid ?? prefs.getString('userId');
    if (!mounted) return;

    if (currentUser != null && (userId?.isNotEmpty ?? false)) {
      // Firestore se role fetch karo, phir seedha home pe bhejo
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (!mounted) return;
        final data = doc.data();
        if (data != null && data['profileComplete'] == true) {
          final role = data['activeRole'] ?? data['role'];
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
          ],
        ),
      ),
    );
  }
}
