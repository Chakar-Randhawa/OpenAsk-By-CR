import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Deep Link routing service for OpenAsk.
/// Supports openask:// and standard HTTPS app links.
class DeepLinkService {
  DeepLinkService._();

  static const String scheme = 'openask';
  static const String host = 'openask.app';

  static String? parseUriToRoute(Uri uri) {
    final normalizedScheme = uri.scheme.toLowerCase();
    final normalizedHost = uri.host.toLowerCase();
    final pathSegments = uri.pathSegments
        .map((segment) => Uri.decodeComponent(segment.trim()))
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (normalizedScheme == scheme && _isRoute(normalizedHost)) {
      if (pathSegments.isEmpty) return '/';
      return _buildRoute([normalizedHost, ...pathSegments]);
    }

    if (normalizedScheme == 'https' && (normalizedHost == host || normalizedHost.endsWith('.openask.app'))) {
      return _buildRoute(pathSegments);
    }

    return _buildRoute(pathSegments);
  }

  static String? _buildRoute(List<String> segments) {
    if (segments.isEmpty) return '/';
    final route = segments.first.toLowerCase();
    if (route == 'question' && segments.length > 1) {
      return '/question/${segments[1]}';
    }
    if (route == 'category' && segments.length > 1) {
      return '/category/${segments[1]}';
    }
    if (route == 'user' && segments.length > 1) {
      return '/user/${segments[1]}';
    }
    return null;
  }

  static void handleIncomingUri(Uri uri, GoRouter router) {
    final target = parseUriToRoute(uri);
    if (target == null || target == router.routeInformationProvider.value.uri.toString()) {
      return;
    }
    router.go(target);
  }

  static Uri _normalizeUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    if (scheme == 'openask' && uri.pathSegments.isNotEmpty && _isRoute(uri.pathSegments.first)) {
      return uri;
    }

    final candidatePath = uri.path.isEmpty ? uri.host : uri.path;
    if (scheme == 'https' && (host == DeepLinkService.host || host.endsWith('.openask.app'))) {
      return uri;
    }

    final routeMatch = RegExp(r'/(question|category|user)/[^/?#]+').firstMatch(uri.path);
    if (routeMatch != null) {
      return uri.replace(path: routeMatch.group(0)!);
    }

    final normalizedPath = candidatePath.startsWith('/') ? candidatePath : '/$candidatePath';
    return uri.replace(path: normalizedPath);
  }

  static bool _isRoute(String value) {
    final route = value.toLowerCase();
    return route == 'question' || route == 'category' || route == 'user';
  }

  static String buildQuestionUrl(String questionId) {
    return 'https://$host/question/$questionId';
  }

  static String buildCategoryUrl(String categoryId) {
    return 'https://$host/category/$categoryId';
  }

  static String buildUserUrl(String uid) {
    return 'https://$host/user/$uid';
  }
}
