import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// Throw this from repositories; catch it in UI to show a clean SnackBar.
class AppException implements Exception {
  final String message; // user-facing, Hinglish
  final Object? cause;
  AppException(this.message, {this.cause});
  @override
  String toString() => message;
}

/// Converts any caught error into an AppException with a safe, user-friendly
/// message. Call this inside every repository catch block:
///   } catch (e, st) {
///     AppLogger.error('ListingRepo.createListing', e, st);
///     throw mapToAppException(e);
///   }
AppException mapToAppException(Object error) {
  if (error is AppException) return error;

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-phone-number':
        return AppException('Phone number sahi format mein daalein.');
      case 'too-many-requests':
        return AppException('Bahut zyada attempts ho gaye. Thodi der baad try karein.');
      case 'invalid-verification-code':
        return AppException('OTP galat hai. Dobara check karein.');
      case 'session-expired':
        return AppException('OTP session expire ho gaya. Naya OTP mangwayein.');
      case 'network-request-failed':
        return AppException('Internet connection check karein.');
      default:
        return AppException('Authentication mein dikkat aayi. Dobara try karein.');
    }
  }

  if (error is FirebaseException) {
    // covers Firestore + Storage exceptions (both use FirebaseException)
    switch (error.code) {
      case 'permission-denied':
        return AppException('Aapko yeh action karne ki permission nahi hai.');
      case 'unavailable':
        return AppException('Server abhi available nahi hai. Thodi der baad try karein.');
      case 'not-found':
        return AppException('Yeh data ab maujood nahi hai.');
      case 'deadline-exceeded':
        return AppException('Request timeout ho gayi. Dobara try karein.');
      case 'cancelled':
        return AppException('Request cancel ho gayi.');
      case 'resource-exhausted':
        return AppException('Storage/quota limit khatam ho gayi hai.');
      default:
        return AppException('Server error aaya. Dobara try karein.');
    }
  }

  if (error is TimeoutException) {
    return AppException('Request bahut time le rahi hai. Internet check karke dobara try karein.');
  }

  if (error is SocketException) {
    return AppException('Internet connection nahi hai. Check karke dobara try karein.');
  }

  if (error is PlatformException) {
    switch (error.code) {
      case 'camera_access_denied':
      case 'photo_access_denied':
        return AppException('Camera/Gallery permission chahiye. Settings mein enable karein.');
      default:
        return AppException('Kuch galat ho gaya. Dobara try karein.');
    }
  }

  return AppException('Kuch anjaan error aaya. Dobara try karein.');
}
