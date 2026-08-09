import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'find_tenants_screen.dart';
import 'owner_listings_screen.dart';
import 'owner_requests_screen.dart';
import '../../profile/screens/profile_screen.dart';

const Color _blueDark = Color(0xFF1A237E);
const Color _blueLight = Color(0xFF3949AB);

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  List<Widget> get _pages => [
        const FindTenantsScreen(),
        const OwnerListingsScreen(),
        const OwnerRequestsScreen(),
        ProfileScreen(
          onBack: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        ),
      ];

  // FIX: Hardware/gesture back button pehle screen ke andar navigate karta
  // hai (tab -> pehla tab), root pe "phir se dabao" confirmation ke baad hi
  // app close hoti hai — pehle seedha background me chali jaati thi.
  Future<bool> _handleBack() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Wapas dabao app band karne ke liye'),
          duration: Duration(seconds: 2)));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _handleBack()) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F2),
        body: _pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_blueDark, _blueLight]),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_search_outlined),
                  activeIcon: Icon(Icons.person_search),
                  label: 'Find Tenants'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Meri Listings'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_outlined),
                  activeIcon: Icon(Icons.notifications),
                  label: 'Requests'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
