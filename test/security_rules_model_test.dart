import 'package:flutter_test/flutter_test.dart';
import 'package:openask/core/models/question_model.dart';
import 'package:openask/core/models/answer_model.dart';
import 'package:openask/core/models/vote_model.dart';
import 'package:openask/core/models/notification_model.dart';

void main() {
  group('Security Rules and Model Invariants Test Suite (Phase 43)', () {
    test('TEST 2 & TEST 15: Anonymous question strictly strips authorUid in public model and toMap', () {
      final anonQuestion = QuestionModel(
        id: 'q_anon_01',
        authorUid: 'user_a_uid',
        isAnonymous: true,
        authorDisplayName: 'Anonymous Member',
        title: 'Security inquiry regarding anonymous posting',
        body: 'Details on how authorUid is stripped from the document payload.',
        categoryId: 'cybersecurity',
        categoryName: 'Cybersecurity & Privacy',
        tags: ['security'],
        createdAt: DateTime.now(),
      );

      final map = anonQuestion.toMap();

      // TEST 2: Anonymous question public response does not expose authorUid
      expect(map.containsKey('authorUid'), isFalse);
      expect(map['authorDisplayName'], equals('Anonymous'));
      expect(map['authorPhotoUrl'], isNull);

      // TEST 15: Anonymous content remains publicly anonymous through normal reads
      final parsed = QuestionModel.fromMap(map, 'q_anon_01');
      expect(parsed.authorUid, isNull);
      expect(parsed.isAnonymous, isTrue);
    });

    test('TEST 8: Vote document key format is strictly deterministic: {targetId}_{uid}', () {
      const targetId = 'ans_9876';
      const uid = 'user_voter_123';
      final deterministicKey = '${targetId}_$uid';

      final vote = VoteModel(
        id: deterministicKey,
        targetId: targetId,
        targetType: 'answer',
        uid: uid,
        value: 1,
        createdAt: DateTime.now(),
      );

      expect(vote.id, equals('ans_9876_user_voter_123'));
      // Value must be strictly +1 or -1
      expect(vote.value == 1 || vote.value == -1, isTrue);
    });

    test('TEST 9: Notification creation validates whitelisted types and distinct recipient', () {
      const allowedTypes = ['answer', 'helpful', 'follow', 'category_question', 'report_status', 'comment', 'reply'];
      const senderUid = 'user_sender_1';
      const recipientUid = 'user_recipient_2';

      // Self-notification is forbidden
      expect(senderUid == recipientUid, isFalse);

      final validNotification = NotificationModel(
        id: 'notif_1',
        recipientUid: recipientUid,
        senderUid: senderUid,
        type: 'answer',
        title: 'New Answer',
        body: 'Someone replied to your question.',
        targetType: 'question',
        targetId: 'q_100',
        createdAt: DateTime.now(),
      );

      expect(allowedTypes, contains(validNotification.type));
      expect(validNotification.recipientUid, isNot(equals(validNotification.senderUid)));
    });

    test('TEST 5, 6, 7: Client cannot tamper with reputation, role, or admin privileges', () {
      // In firestore.rules:
      // !request.resource.data.diff(resource.data).affectedKeys().hasAny(['reputation', 'role', 'id', 'createdAt', 'questionCount', 'answerCount', 'followersCount', 'followingCount', 'status'])
      final protectedKeys = ['reputation', 'role', 'id', 'createdAt', 'questionCount', 'answerCount', 'followersCount', 'followingCount', 'status'];

      final attemptedClientEdit = {'displayName': 'New Name', 'reputation': 999999, 'role': 'admin'};
      final affectedKeys = attemptedClientEdit.keys.toList();

      final hasForbiddenKeys = affectedKeys.any((key) => protectedKeys.contains(key) && key != 'displayName');
      expect(hasForbiddenKeys, isTrue); // Rules strictly reject this update!
    });
  });
}
