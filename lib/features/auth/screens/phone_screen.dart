import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/msg91_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NAYA: Consent save karne ke liye
import 'package:flutter/gestures.dart'; // NAYA: Tappable text link ke liye

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  bool _consentChecked = false; // NAYA: Checkbox track karne ke liye

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2), // Light theme off-white
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Illustration Header
              Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.maps_home_work_outlined,
                        size: 80, color: Color(0xFF2D6A4F)),
                    Positioned(
                      top: 40,
                      right: 30,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.chat_bubble_outline,
                            size: 24, color: Color(0xFF2D6A4F)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome to Chhat',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Room khojo, Dalal nahi.\nApna mobile number daaliye login karne ke liye.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Color(0xFF666666), height: 1.4),
              ),
              const SizedBox(height: 40),

              // Input Field (Light Theme)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Mobile Number',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
              ),
              const SizedBox(height: 8),
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
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('+91',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A))),
                    ),
                    Container(
                        width: 1, height: 24, color: const Color(0xFFE0E0E0)),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 0, 0,
                                0), // NAYA: White text for dark background
                            fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          hintText: 'Enter your mobile',
                          hintStyle: TextStyle(
                              color:
                                  Colors.white54), // NAYA: Lighter white hint
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // NAYA: DPDP Consent Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _consentChecked,
                      onChanged: (val) =>
                          setState(() => _consentChecked = val ?? false),
                      activeColor: const Color(0xFF2D6A4F),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                            height: 1.4),
                        children: [
                          const TextSpan(
                              text:
                                  'I understand that my data will be processed as per the DPDP Act 2023. I have read the '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                                color: Color(0xFF2D6A4F),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.push(
                                  '/privacy-policy'), // NAYA: Link to policy
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // NAYA: Jab tak checkbox true nahi, button disable rahega
                  onPressed: (_loading || !_consentChecked) ? null : _sendOtp,
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
                      : const Text('OTP Bhejo',
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

  Future<void> _sendOtp() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('10 digit ka number daalo')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('consentVersion', '1.0');
      await prefs.setString('consentGivenAt', DateTime.now().toIso8601String());

      // Google Play review ke liye reserved test-account.
      // MSG91 ko bilkul call nahi karta — seedha OTP screen pe le jata hai,
      // jahan otp_screen.dart backend se test-credentials verify karega.
      const testPhone = '9999999999';
      if (_phoneController.text.trim() == testPhone) {
        if (mounted) {
          setState(() => _loading = false);
          context.go('/otp', extra: {
            'verificationId': 'test-review-bypass',
            'phoneNumber': _phoneController.text,
          });
        }
        return;
      }

      final reqId = await Msg91Service.sendOtp(_phoneController.text);

      if (mounted) {
        setState(() => _loading = false);
        context.go('/otp', extra: {
          'verificationId': reqId,
          'phoneNumber': _phoneController.text,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
}
