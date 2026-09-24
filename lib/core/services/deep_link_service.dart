import 'package:flutter/foundation.dart';

/// Deep Link routing service for OpenAsk.
/// Supports openask:// and standard HTTPS app links.
class DeepLinkService {
  DeepLinkService._();

  static const String scheme = 'openask';
  static const String host = 'openask.app';

  /// Parse URI into application route.
  static String? parseUriToRoute(Uri uri) {
    if (uri.scheme == scheme || (uri.scheme == 'https' && uri.host == host)) {
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) return '/';

      final first = pathSegments[0];
      if (first == 'question' && pathSegments.length > 1) {
        return '/question/${pathSegments[1]}';
      } else if (first == 'category' && pathSegments.length > 1) {
        return '/category/${pathSegments[1]}';
      } else if (first == 'user' && pathSegments.length > 1) {
        return '/user/${pathSegments[1]}';
      }
    }
    return null;
  }

  /// Build canonical shareable question link.
  static String buildQuestionUrl(String questionId) {
    return 'https://$host/question/$questionId';
  }

  /// Build canonical shareable category link.
  static String buildCategoryUrl(String categoryId) {
    return 'https://$host/category/$categoryId';
  }

  /// Build canonical shareable user link.
  static String buildUserUrl(String uid) {
    return 'https://$host/user/$uid';
  }
}
