import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_exception.dart';

/// Translates raw exceptions into friendly, actionable messages.
class ErrorMapper {
  static String map(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please verify and try again.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been suspended or disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again after a few moments.';
        case 'requires-recent-login':
          return 'For your security, please sign in again to continue this action.';
        default:
          return error.message ?? 'Authentication error occurred.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'unavailable':
          return 'Network service is currently unavailable. Using cached data.';
        case 'deadline-exceeded':
          return 'Request timed out. Please check your internet connection.';
        case 'not-found':
          return 'The requested resource was not found.';
        default:
          return 'A database error occurred. Please try again.';
      }
    }

    if (error is String) {
      return error;
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
