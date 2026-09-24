import 'package:flutter_test/flutter_test.dart';
import 'package:openask/core/models/user_profile_model.dart';
import 'package:openask/core/models/question_model.dart';
import 'package:openask/core/models/answer_model.dart';
import 'package:openask/core/models/category_model.dart';
import 'package:openask/core/models/comment_model.dart';
import 'package:openask/core/models/vote_model.dart';
import 'package:openask/core/models/bookmark_model.dart';
import 'package:openask/core/models/report_model.dart';
import 'package:openask/core/models/audit_log_model.dart';

void main() {
  group('Data Models Serialization Test Suite', () {
    test('UserProfileModel round-trip serialization', () {
      final now = DateTime.now();
      final profile = UserProfileModel(
        id: 'u_100',
        displayName: 'Alice Engineer',
        username: 'alice_eng',
        email: 'alice@example.com',
        bio: 'Mobile systems architect.',
        photoUrl: 'https://example.com/alice.png',
        country: 'Canada',
        language: 'en',
        timezone: 'America/Toronto',
        website: 'https://alice.dev',
        interests: ['flutter', 'security'],
        reputation: 250,
        questionCount: 5,
        answerCount: 12,
        followersCount: 30,
        followingCount: 15,
        role: 'member',
        status: 'active',
        createdAt: now,
      );

      final map = profile.toMap();
      final restored = UserProfileModel.fromMap(map, 'u_100');

      expect(restored.id, equals('u_100'));
      expect(restored.displayName, equals('Alice Engineer'));
      expect(restored.username, equals('alice_eng'));
      expect(restored.reputation, equals(250));
      expect(restored.interests, contains('flutter'));
    });

    test('CommentModel round-trip serialization', () {
      final now = DateTime.now();
      final comment = CommentModel(
        id: 'c_01',
        targetType: 'question',
        targetId: 'q_500',
        authorUid: 'u_200',
        authorDisplayName: 'Bob Reviewer',
        text: 'Could you clarify the exact error message received?',
        likesCount: 3,
        status: 'active',
        createdAt: now,
      );

      final map = comment.toMap();
      final restored = CommentModel.fromMap(map, 'c_01');

      expect(restored.id, equals('c_01'));
      expect(restored.targetId, equals('q_500'));
      expect(restored.text, equals('Could you clarify the exact error message received?'));
      expect(restored.likesCount, equals(3));
    });

    test('VoteModel round-trip serialization', () {
      final now = DateTime.now();
      final vote = VoteModel(
        id: 'ans_123_u_456',
        targetId: 'ans_123',
        targetType: 'answer',
        uid: 'u_456',
        value: 1,
        createdAt: now,
      );

      final map = vote.toMap();
      final restored = VoteModel.fromMap(map, 'ans_123_u_456');

      expect(restored.id, equals('ans_123_u_456'));
      expect(restored.value, equals(1));
      expect(restored.targetId, equals('ans_123'));
    });

    test('BookmarkCollectionModel round-trip serialization', () {
      final now = DateTime.now();
      final col = BookmarkCollectionModel(
        id: 'col_01',
        uid: 'u_777',
        title: 'Security Patterns',
        description: 'Selected questions on security',
        itemCount: 4,
        createdAt: now,
      );

      final map = col.toMap();
      final restored = BookmarkCollectionModel.fromMap(map, 'col_01');

      expect(restored.id, equals('col_01'));
      expect(restored.title, equals('Security Patterns'));
      expect(restored.itemCount, equals(4));
    });

    test('ReportModel round-trip serialization', () {
      final now = DateTime.now();
      final report = ReportModel(
        id: 'rep_01',
        reporterUid: 'u_888',
        targetType: 'question',
        targetId: 'q_999',
        reason: 'spam',
        details: 'Promotional link spam',
        status: 'pending',
        createdAt: now,
      );

      final map = report.toMap();
      final restored = ReportModel.fromMap(map, 'rep_01');

      expect(restored.id, equals('rep_01'));
      expect(restored.reason, equals('spam'));
      expect(restored.status, equals('pending'));
    });

    test('AuditLogModel round-trip serialization', () {
      final now = DateTime.now();
      final log = AuditLogModel(
        id: 'log_01',
        actorUid: 'mod_1',
        action: 'remove_content',
        targetType: 'question',
        targetId: 'q_bad',
        reason: 'NSFW violation',
        createdAt: now,
      );

      final map = log.toMap();
      final restored = AuditLogModel.fromMap(map, 'log_01');

      expect(restored.id, equals('log_01'));
      expect(restored.action, equals('remove_content'));
      expect(restored.actorUid, equals('mod_1'));
    });
  });
}
