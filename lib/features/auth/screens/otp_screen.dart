import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_auth/smart_auth.dart';
import '../../../services/msg91_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_logger.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  late String _reqId;
  bool _loading = false;
  int _secondsLeft = 45;
  bool _canResend = false;
  Timer? _timer;
  // NAYA: SMS User Consent API — koi app hash / DLT template change nahi
  // chahiye. SMS aane par system consent dialog dikhta hai.
  final _smartAuth = SmartAuth.instance;

  @override
  void initState() {
    super.initState();
    _reqId = widget.verificationId;
    _startTimer();
    _listenForOtp();
  }

  Future<void> _listenForOtp() async {
    try {
      final res = await _smartAuth.getSmsWithUserConsentApi();
      if (!mounted) return;
      if (res.hasData) {
        final code = res.requireData.code;
        if (code != null && code.length == 6) {
          setState(() => _otpController.text = code);
        }
      }
      // res.isCanceled ya error case me kuch nahi karna — user manually
      // type kar sakta hai, jaisa pehle bhi option tha.
    } catch (e, st) {
      AppLogger.error('OtpScreen._listenForOtp', e, st);
    }
  }

  void _startTimer() {
    setState(() {
      _secondsLeft = 45;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    _smartAuth.removeUserConsentApiListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      // ✅ AppBar hataya — back button nahi chahiye OTP screen par
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Illustration Header
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    size: 64, color: Color(0xFF2D6A4F)),
              ),
              const SizedBox(height: 32),

              const Text(
                'Enter OTP',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 8),
              Text(
                'Don\'t worry! We have sent a 6-digit code to\n+91 ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF666666), height: 1.4),
              ),
              const SizedBox(height: 8),

              // ✅ Change Number button
              GestureDetector(
                onTap: () => context.go('/phone'),
                child: const Text(
                  'Change Number?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D6A4F),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF2D6A4F),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // OTP Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 16,
                      color: Color(0xFF1A1A1A)),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '------',
                    hintStyle:
                        TextStyle(color: Color(0xFFDDDDDD), letterSpacing: 16),
                    contentPadding: EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _canResend
                  ? TextButton(
                      onPressed: () async {
                        try {
                          _reqId =
                              await Msg91Service.sendOtp(widget.phoneNumber);
                          _startTimer();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('OTP resend failed. Try again.')),
                            );
                          }
                        }
                      },
                      child: const Text('Resend OTP',
                          style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2D6A4F),
                              fontWeight: FontWeight.bold)),
                    )
                  : Text('Resend Code in ${_secondsLeft}s',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF666666))),
              const SizedBox(height: 32),

              // Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Verify Karo',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();

    if (enteredOtp.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(enteredOtp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sahi 6 digit ka OTP daalo')),
      );
      return;
    }

    setState(() => _loading = true);

    // Google Play review ke liye reserved test-account — MSG91 poori tarah
    // skip karke seedha backend se verify karta hai.
    const testPhone = '9999999999';
    const testOtp = '123456';
    if (widget.phoneNumber.trim() == testPhone && enteredOtp == testOtp) {
      try {
        final result = await Msg91Service.verifyTestAccount(testPhone, testOtp);
        final customToken = result['customToken'].toString();
        final uid = result['uid'].toString();
        await FirebaseAuth.instance.signInWithCustomToken(customToken);
        await _handleLoginSuccess(widget.phoneNumber, uid);
      } catch (e, st) {
        AppLogger.error('OtpScreen.verifyTestAccount', e, st);
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification failed. Try again.')),
          );
        }
      }
      return;
    }

    try {
      final accessToken = await Msg91Service.verifyOtp(_reqId, enteredOtp);
      final result = await Msg91Service.verifyWithBackend(accessToken);

      final customToken = result['customToken'].toString();
      final uid = result['uid'].toString();

      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      await _handleLoginSuccess(widget.phoneNumber, uid);
    } catch (e, st) {
      AppLogger.error('OtpScreen.verifyOtp', e, st);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Galat OTP hai ya expire ho gaya. Wapas try karo.')),
        );
      }
    }
  }

  Future<void> _handleLoginSuccess(String phone, String uid) async {
    try {
      // NAYA: API Optimization & Caching (Save locally immediately)
      final prefs = await SharedPreferences.getInstance();
      String normalizedPhone = phone.trim();
      if (!normalizedPhone.startsWith('+91')) {
        normalizedPhone = '+91$normalizedPhone';
      }
      await prefs.setString('savedUserId', uid);
      await prefs.setString('userId', uid);
      await prefs.setString('userPhone', normalizedPhone);

      final db = FirebaseFirestore.instance;
      final docRef = db.collection('users').doc(uid);

      // FIX: Login jaisi critical check ke liye hamesha server se confirm
      // karo — 'serverAndCache' kabhi-kabhi device ke purane local cache se
      // stale data de deta tha (jaise Firestore console se data delete karne
      // ke baad bhi purana role/profile dikh jaata tha).
      final doc = await docRef.get(const GetOptions(source: Source.server));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // FIX: Sirf tabhi write karo jab consentVersion actually badla ho —
        // pehle har login pe unconditional write hota tha
        final consentVersion = prefs.getString('consentVersion') ?? '1.0';
        if (data['consentVersion'] != consentVersion) {
          final consentGivenAtStr = prefs.getString('consentGivenAt');
          final consentGivenAt = consentGivenAtStr != null
              ? DateTime.parse(consentGivenAtStr)
              : DateTime.now();

          await docRef.update({
            'consentVersion': consentVersion,
            'consentGivenAt': consentGivenAt,
          });
        }

        // Cache save karo — profile pe instant load ke liye
        await prefs.setString('userName', data['name'] ?? '');
        await prefs.setString(
            'userRole', data['activeRole'] ?? data['role'] ?? 'tenant');

        if (mounted) {
          setState(() => _loading = false);

          if (data['profileComplete'] == true) {
            final role = data['activeRole'] ?? data['role'];
            if (role != null && role.toString().isNotEmpty) {
              context.go('/$role-home');
            } else {
              context.go('/role');
            }
          } else {
            context.go('/role');
          }
        }
      } else {
        // NAYA: Naye user ke liye DPDP consent details Firestore me save karo
        final consentVersion = prefs.getString('consentVersion') ?? '1.0';
        final consentGivenAtStr = prefs.getString('consentGivenAt');
        final consentGivenAt = consentGivenAtStr != null
            ? DateTime.parse(consentGivenAtStr)
            : DateTime.now();

        // Naya User create karo
        // Normalize: '+91' sirf ek baar
        String normalizedPhone = phone.trim();
        if (!normalizedPhone.startsWith('+91')) {
          normalizedPhone = '+91$normalizedPhone';
        }

        await docRef.set({
          'phone': normalizedPhone,
          'profileComplete': false,
          'active': true,
          'consentVersion': consentVersion, // DPDP Compliance
          'consentGivenAt': consentGivenAt, // DPDP Compliance
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() => _loading = false);
          context.go('/role');
        }
      }
    } catch (e) {
      debugPrint("🔥 OTP Navigation Error: $e");
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Login failed due to network error.')), // NAYA: Error handling
        );
      }
    }
  }
}
