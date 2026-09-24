import 'package:flutter_test/flutter_test.dart';
import 'package:openask/core/services/deep_link_service.dart';

void main() {
  group('DeepLinkService Test Suite (Phase 25)', () {
    test('parses openask://question/:id correctly', () {
      final uri = Uri.parse('openask://question/q_abc_123');
      final route = DeepLinkService.parseUriToRoute(uri);
      expect(route, equals('/question/q_abc_123'));
    });

    test('parses https://openask.app/question/:id correctly', () {
      final uri = Uri.parse('https://openask.app/question/q_xyz_789');
      final route = DeepLinkService.parseUriToRoute(uri);
      expect(route, equals('/question/q_xyz_789'));
    });

    test('parses category deep link correctly', () {
      final uri = Uri.parse('openask://category/tech_programming');
      final route = DeepLinkService.parseUriToRoute(uri);
      expect(route, equals('/category/tech_programming'));
    });

    test('parses user deep link correctly', () {
      final uri = Uri.parse('openask://user/uid_555');
      final route = DeepLinkService.parseUriToRoute(uri);
      expect(route, equals('/user/uid_555'));
    });

    test('returns null for unrelated schemes', () {
      final uri = Uri.parse('https://external-website.com/something');
      final route = DeepLinkService.parseUriToRoute(uri);
      expect(route, isNull);
    });

    test('builds canonical share URLs', () {
      expect(
        DeepLinkService.buildQuestionUrl('q_123'),
        equals('https://openask.app/question/q_123'),
      );
      expect(
        DeepLinkService.buildCategoryUrl('ai_ml'),
        equals('https://openask.app/category/ai_ml'),
      );
      expect(
        DeepLinkService.buildUserUrl('u_999'),
        equals('https://openask.app/user/u_999'),
      );
    });
  });
}
