import 'dart:convert';
import 'package:http/http.dart' as http;
import 'msg91_widget_bridge.dart';

class Msg91Service {
  static const String _verifyBackendUrl =
      'https://us-central1-chhat-app-7e66e.cloudfunctions.net/verifyMsg91Token';

  static Future<String> sendOtp(String phone10Digit) {
    return Msg91WidgetBridge.instance.sendOtp(phone10Digit);
  }

  static Future<String> verifyOtp(String reqId, String otp) {
    // Note: reqId yahan use nahi hota — widget apna session khud track
    // karta hai WebView ke andar, isliye ignore kiya hua hai.
    return Msg91WidgetBridge.instance.verifyOtp(otp);
  }

  static Future<Map<String, dynamic>> verifyWithBackend(
      String accessToken) async {
    final res = await http
        .post(
          Uri.parse(_verifyBackendUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'accessToken': accessToken}),
        )
        .timeout(const Duration(seconds: 15),
            onTimeout: () => throw Exception(
                'Server response nahi de raha, dobara try karo'));

    if (res.statusCode != 200) {
      throw Exception('Verification fail ho gayi (server error)');
    }

    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return data;
    }
    throw Exception(data['error']?.toString() ?? 'Verification fail ho gayi');
  }
}
