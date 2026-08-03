import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/utils/app_logger.dart';

/// MSG91 ka OTP widget ek WebView ke andar chalta hai (koi official Flutter
/// SDK nahi hai isliye). Yeh WebView poore app mein SIRF EK BAAR banta hai
/// aur zinda rehta hai (main.dart mein mount hai) — kyunki phone screen se
/// otp screen jaate waqt widget ka session (reqId) tootna nahi chahiye.
class Msg91WidgetBridge {
  Msg91WidgetBridge._();
  static final Msg91WidgetBridge instance = Msg91WidgetBridge._();

  late final WebViewController controller;
  bool _ready = false;
  Completer<bool>? _readyCompleter;
  Completer<Map<String, dynamic>>? _sendCompleter;
  Completer<Map<String, dynamic>>? _verifyCompleter;

  void init() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (message) {
          final data = jsonDecode(message.message) as Map<String, dynamic>;
          switch (data['event']) {
            case 'ready':
              _ready = true;
              _readyCompleter?.complete(true);
              break;
            case 'sendSuccess':
              _sendCompleter?.complete(data);
              break;
            case 'sendFailure':
              AppLogger.error('Msg91WidgetBridge.sendOtp', data['error'], null);
              _sendCompleter
                  ?.completeError(Exception('OTP bhejne mein dikkat aayi'));
              break;
            case 'verifySuccess':
              _verifyCompleter?.complete(data);
              break;
            case 'verifyFailure':
              AppLogger.error(
                  'Msg91WidgetBridge.verifyOtp', data['error'], null);
              _verifyCompleter
                  ?.completeError(Exception('Galat OTP hai ya expire ho gaya'));
              break;
          }
        },
      )
      ..loadFlutterAsset('assets/msg91_widget.html');
  }

  Future<void> _waitUntilReady() async {
    if (_ready) return;
    _readyCompleter = Completer<bool>();
    await _readyCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () =>
          throw Exception('OTP widget load nahi hua, internet check karo'),
    );
  }

  /// OTP bhejta hai, success par MSG91 ka reqId return karta hai.
  Future<String> sendOtp(String phone10Digit) async {
    // FIX: Race condition — pehle wali call abhi pending hai toh naya call reject karo
    if (_sendCompleter != null && !_sendCompleter!.isCompleted) {
      throw Exception('Pehli OTP request abhi process ho rahi hai, thoda ruko');
    }
    await _waitUntilReady();
    _sendCompleter = Completer<Map<String, dynamic>>();
    await controller.runJavaScript("callSendOtp('91$phone10Digit');");
    final result = await _sendCompleter!.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () =>
          throw Exception('OTP bhejne mein time zyada lag raha hai'),
    );
    return (result['data']?['message'] ?? '').toString();
  }

  /// OTP verify karta hai, success par access-token (JWT) return karta hai.
  Future<String> verifyOtp(String otp) async {
    // FIX: Race condition — pehle wali call abhi pending hai toh naya call reject karo
    if (_verifyCompleter != null && !_verifyCompleter!.isCompleted) {
      throw Exception(
          'Pehli verify request abhi process ho rahi hai, thoda ruko');
    }
    _verifyCompleter = Completer<Map<String, dynamic>>();
    await controller.runJavaScript("callVerifyOtp('$otp');");
    final result = await _verifyCompleter!.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () =>
          throw Exception('Verify hone mein time zyada lag raha hai'),
    );
    return (result['data']?['message'] ?? '').toString();
  }
}
