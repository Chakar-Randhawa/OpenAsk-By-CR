import 'package:flutter_test/flutter_test.dart';
import 'package:openask/core/models/question_model.dart';
import 'package:openask/core/models/answer_model.dart';

void main() {
  group('Anonymous Privacy Test Suite (Phase 6 & Phase 43)', () {
    test('Anonymous question toMap() strictly OMITS authorUid', () {
      final anonQuestion = QuestionModel(
        id: 'q_12345',
        authorUid: 'secret_user_uid_999',
        isAnonymous: true,
        authorDisplayName: 'Secret Identity',
        authorPhotoUrl: 'https://example.com/avatar.jpg',
        title: 'How does Firestore security work?',
        body: 'Detailed question body regarding rules and anonymity.',
        categoryId: 'tech_programming',
        categoryName: 'Technology & Software',
        tags: ['security', 'privacy'],
        createdAt: DateTime.now(),
      );

      final map = anonQuestion.toMap();

      // TEST 2: Anonymous question public response does not expose authorUid
      expect(map.containsKey('authorUid'), isFalse);
      expect(map['authorUid'], isNull);
      expect(map['authorDisplayName'], equals('Anonymous'));
      expect(map['authorPhotoUrl'], isNull);
      expect(map['isAnonymous'], isTrue);
    });

    test('Non-anonymous question toMap() preserves authorUid and display info', () {
      final publicQuestion = QuestionModel(
        id: 'q_67890',
        authorUid: 'public_user_uid_111',
        isAnonymous: false,
        authorDisplayName: 'Jane Doe',
        authorPhotoUrl: 'https://example.com/jane.jpg',
        title: 'Best practices for Flutter state management',
        body: 'Looking for maintainable architecture insights.',
        categoryId: 'mobile_dev',
        categoryName: 'Mobile Development',
        tags: ['flutter', 'dart'],
        createdAt: DateTime.now(),
      );

      final map = publicQuestion.toMap();

      expect(map.containsKey('authorUid'), isTrue);
      expect(map['authorUid'], equals('public_user_uid_111'));
      expect(map['authorDisplayName'], equals('Jane Doe'));
      expect(map['authorPhotoUrl'], equals('https://example.com/jane.jpg'));
      expect(map['isAnonymous'], isFalse);
    });

    test('Anonymous question fromMap() enforces null authorUid even if present in legacy doc', () {
      // Defensive parsing: even if a malicious client or legacy doc had authorUid,
      // fromMap guarantees authorUid is null when isAnonymous == true!
      final legacyMap = {
        'authorUid': 'leaked_uid_333',
        'isAnonymous': true,
        'authorDisplayName': 'Anonymous',
        'title': 'Legacy anonymous inquiry',
        'body': 'Inquiry context and details.',
        'categoryId': 'open_discussion',
        'categoryName': 'Open Community Inquiries',
        'tags': <String>[],
      };

      final parsed = QuestionModel.fromMap(legacyMap, 'q_legacy_001');

      // TEST 15: Anonymous content remains publicly anonymous through normal application reads
      expect(parsed.authorUid, isNull);
      expect(parsed.isAnonymous, isTrue);
      expect(parsed.authorDisplayName, equals('Anonymous'));
      expect(parsed.authorPhotoUrl, isNull);
    });

    test('Anonymous answer toMap() strictly OMITS authorUid', () {
      final anonAnswer = AnswerModel(
        id: 'ans_555',
        questionId: 'q_12345',
        authorUid: 'secret_answerer_uid',
        isAnonymous: true,
        authorDisplayName: 'Secret Doctor',
        body: 'Expert medical opinion shared anonymously for privacy.',
        createdAt: DateTime.now(),
      );

      final map = anonAnswer.toMap();

      expect(map.containsKey('authorUid'), isFalse);
      expect(map['authorUid'], isNull);
      expect(map['authorDisplayName'], equals('Anonymous'));
      expect(map['authorPhotoUrl'], isNull);
    });

    test('Anonymous answer fromMap() cleanses authorUid defensively', () {
      final rawMap = {
        'questionId': 'q_12345',
        'authorUid': 'should_not_leak',
        'isAnonymous': true,
        'authorDisplayName': 'Anonymous',
        'body': 'Anonymous response body',
      };

      final parsed = AnswerModel.fromMap(rawMap, 'ans_999');

      expect(parsed.authorUid, isNull);
      expect(parsed.isAnonymous, isTrue);
    });
  });
}
