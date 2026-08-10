import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/push_notification_service.dart';
import 'find_room_screen.dart';
import 'tenant_profile_tab.dart';
import 'tenant_requests_screen.dart';
import '../../profile/screens/profile_screen.dart';

const Color _bgColor = Color(0xFFF5F7F2);
const Color _cherryRed = Color(0xFFC62828);
const Color _cherryLight = Color(0xFFEF5350);

class TenantHomeScreen extends StatefulWidget {
  final int initialTab;
  const TenantHomeScreen({super.key, this.initialTab = 0});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  late int _currentIndex = widget.initialTab;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    // FIX: Ye function pehle kahin call hi nahi ho raha tha, isliye app
    // kabhi notification permission maangti hi nahi thi aur FCM token bhi
    // save nahi hota tha.
    SharedPreferences.getInstance().then((prefs) {
      final userId = prefs.getString('userId');
      if (userId != null && userId.isNotEmpty) {
        PushNotificationService.init(userId);
      }
    });
  }

  late final List<Widget> _pages = [
    const FindRoomScreen(),
    const TenantProfileTab(),
    const TenantRequestsScreen(),
    ProfileScreen(
      onBack: () {
        setState(() {
          _currentIndex = 0;
        });
      },
    ),
  ];

  // FIX: Hardware/gesture back button pehle screen ke andar navigate karta
  // hai (tab -> pehla tab), aur root pe "phir se dabao" confirmation ke
  // baad hi app close hoti hai — pehle seedha background me chali jaati thi.
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
        backgroundColor: _bgColor,
        body: _pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_cherryRed, _cherryLight]),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
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
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Find Room',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_ind_outlined),
                activeIcon: Icon(Icons.assignment_ind),
                label: 'My Info',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: 'Requests',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
