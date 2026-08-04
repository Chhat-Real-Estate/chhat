import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chhat/core/utils/app_exceptions.dart';

void main() {
  group('mapToAppException', () {
    test('AppException ko waisa hi return karta hai (double-wrap nahi karta)',
        () {
      final original = AppException('Original message');
      final result = mapToAppException(original);
      expect(result, same(original));
    });

    test('FirebaseAuthException: invalid-verification-code', () {
      final error = FirebaseAuthException(code: 'invalid-verification-code');
      final result = mapToAppException(error);
      expect(result.message, 'OTP galat hai. Dobara check karein.');
    });

    test('FirebaseAuthException: too-many-requests', () {
      final error = FirebaseAuthException(code: 'too-many-requests');
      final result = mapToAppException(error);
      expect(result.message,
          'Bahut zyada attempts ho gaye. Thodi der baad try karein.');
    });

    test('FirebaseAuthException: unknown code ke liye default message', () {
      final error = FirebaseAuthException(code: 'some-random-code');
      final result = mapToAppException(error);
      expect(result.message,
          'Authentication mein dikkat aayi. Dobara try karein.');
    });

    test('FirebaseException: permission-denied', () {
      final error =
          FirebaseException(plugin: 'firestore', code: 'permission-denied');
      final result = mapToAppException(error);
      expect(result.message, 'Aapko yeh action karne ki permission nahi hai.');
    });

    test('FirebaseException: not-found', () {
      final error = FirebaseException(plugin: 'firestore', code: 'not-found');
      final result = mapToAppException(error);
      expect(result.message, 'Yeh data ab maujood nahi hai.');
    });

    test('FirebaseException: unknown code ke liye default message', () {
      final error =
          FirebaseException(plugin: 'firestore', code: 'something-else');
      final result = mapToAppException(error);
      expect(result.message, 'Server error aaya. Dobara try karein.');
    });

    test('TimeoutException', () {
      final error = TimeoutException('timed out');
      final result = mapToAppException(error);
      expect(result.message,
          'Request bahut time le rahi hai. Internet check karke dobara try karein.');
    });

    test('SocketException', () {
      final error = const SocketException('no internet');
      final result = mapToAppException(error);
      expect(result.message,
          'Internet connection nahi hai. Check karke dobara try karein.');
    });

    test('PlatformException: camera_access_denied', () {
      final error = PlatformException(code: 'camera_access_denied');
      final result = mapToAppException(error);
      expect(result.message,
          'Camera/Gallery permission chahiye. Settings mein enable karein.');
    });

    test('Anjaan error type ke liye generic fallback', () {
      final result = mapToAppException(Exception('kuch bhi'));
      expect(result.message, 'Kuch anjaan error aaya. Dobara try karein.');
    });
  });
}
