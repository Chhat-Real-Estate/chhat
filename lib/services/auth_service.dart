import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? get currentUserId => _prefs?.getString('userId');
  static String? get currentUserPhone => _prefs?.getString('userPhone');
  static String? get userRole => _prefs?.getString('userRole');
  static bool get isProfileComplete => _prefs?.getBool('profileComplete') ?? false;
  static bool get isLoggedIn => (_prefs?.getString('userId')?.isNotEmpty ?? false);

  fb.User? get currentUser => fb.FirebaseAuth.instance.currentUser;
  Stream<fb.User?> get authStateChanges => fb.FirebaseAuth.instance.authStateChanges();

  static Future<void> setSession({
    required String userId,
    required String phone,
    String? name,
    String? role,
    bool? profileComplete,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('userId', userId);
    await _prefs!.setString('savedUserId', userId);
    await _prefs!.setString('userPhone', phone);
    if (name != null) await _prefs!.setString('userName', name);
    if (role != null) await _prefs!.setString('userRole', role);
    if (profileComplete != null) await _prefs!.setBool('profileComplete', profileComplete);
  }

  static Future<void> setProfileComplete(bool complete, {String? role}) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool('profileComplete', complete);
    if (role != null) await _prefs!.setString('userRole', role);
  }

  Future<void> signOut() => staticSignOut();

  static Future<void> staticSignOut() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove('userId');
    await _prefs!.remove('savedUserId');
    await _prefs!.remove('userPhone');
    await _prefs!.remove('userRole');
    await _prefs!.remove('userName');
    await _prefs!.remove('profileComplete');
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }
}

