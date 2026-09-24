import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/answer_model.dart';

abstract class AnswerRepository {
  Future<List<AnswerModel>> fetchAnswersForQuestion(String questionId, {String sortBy = 'helpful'});
  Stream<List<AnswerModel>> streamAnswers(String questionId);
  Future<bool> isAnswerOwner(String answerId, String uid);
  Future<String> createAnswer({
    required String questionId,
    required String authorUid,
    required String authorDisplayName,
    String? authorPhotoUrl,
    required bool isAnonymous,
    required String body,
  });
  Future<void> updateAnswer({
    required String answerId,
    required String editorUid,
    required String body,
  });
  Future<void> deleteAnswer({
    required String answerId,
    required String authorUid,
  });
  Future<int> voteAnswer({
    required String answerId,
    required String uid,
    required int voteValue, // +1 or -1
  });
  Future<int> getUserVote(String answerId, String uid);
  Future<int> getAnswerVoteCount(String answerId);
  Future<bool> markAnswerHelpful({
    required String questionId,
    required String answerId,
    required String questionAuthorUid,
  });
}

class FirestoreAnswerRepository implements AnswerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<bool> isAnswerOwner(String answerId, String uid) async {
    try {
      final ownerDoc = await _firestore.collection('answerOwners').doc(answerId).get();
      if (ownerDoc.exists && ownerDoc.data()?['ownerUid'] == uid) {
        return true;
      }
      final ansDoc = await _firestore.collection('answers').doc(answerId).get();
      if (ansDoc.exists && ansDoc.data()?['authorUid'] == uid) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<List<AnswerModel>> fetchAnswersForQuestion(String questionId, {String sortBy = 'helpful'}) async {
    final snap = await _firestore
        .collection('answers')
        .where('questionId', isEqualTo: questionId)
        .where('status', isEqualTo: 'active')
        .limit(100)
        .get();

    final answers = snap.docs.map((d) => AnswerModel.fromMap(d.data(), d.id)).toList();

    // Client-side authoritative sorting
    if (sortBy == 'helpful') {
      answers.sort((a, b) {
        if (a.isHelpful && !b.isHelpful) return -1;
        if (!a.isHelpful && b.isHelpful) return 1;
        return b.voteCount.compareTo(a.voteCount);
      });
    } else if (sortBy == 'newest') {
      answers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (sortBy == 'oldest') {
      answers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return answers;
  }

  @override
  Stream<List<AnswerModel>> streamAnswers(String questionId) {
    return _firestore
        .collection('answers')
        .where('questionId', isEqualTo: questionId)
        .where('status', isEqualTo: 'active')
        .limit(100)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => AnswerModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) {
        if (a.isHelpful && !b.isHelpful) return -1;
        if (!a.isHelpful && b.isHelpful) return 1;
        return b.voteCount.compareTo(a.voteCount);
      });
      return list;
    });
  }

  @override
  Future<String> createAnswer({
    required String questionId,
    required String authorUid,
    required String authorDisplayName,
    String? authorPhotoUrl,
    required bool isAnonymous,
    required String body,
  }) async {
    final batch = _firestore.batch();
    final answerRef = _firestore.collection('answers').doc();
    final ownerRef = _firestore.collection('answerOwners').doc(answerRef.id);
    final now = DateTime.now();

    // 1. Private answer owner mapping
    batch.set(ownerRef, {
      'id': answerRef.id,
      'ownerUid': authorUid,
      'questionId': questionId,
      'isAnonymous': isAnonymous,
      'createdAt': now.toIso8601String(),
    });

    // 2. Public answer document
    final answer = AnswerModel(
      id: answerRef.id,
      questionId: questionId,
      authorUid: isAnonymous ? null : authorUid,
      isAnonymous: isAnonymous,
      authorDisplayName: isAnonymous ? 'Anonymous' : authorDisplayName,
      authorPhotoUrl: isAnonymous ? null : authorPhotoUrl,
      body: body.trim(),
      voteCount: 0,
      helpfulCount: 0,
      isHelpful: false,
      commentCount: 0,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );

    batch.set(answerRef, answer.toMap());
    await batch.commit();

    // 3. Dispatch secure in-app notification directly to question author
    try {
      final questionSnap = await _firestore.collection('questions').doc(questionId).get();
      if (questionSnap.exists) {
        final qData = questionSnap.data()!;
        final qAuthorUid = qData['authorUid'] as String?;
        final qTitle = qData['title'] as String? ?? 'your question';

        if (qAuthorUid != null && qAuthorUid != authorUid) {
          final notifRef = _firestore.collection('notifications').doc();
          await notifRef.set({
            'id': notifRef.id,
            'recipientUid': qAuthorUid,
            'senderUid': authorUid,
            'type': 'answer',
            'title': 'New Answer Received',
            'body': '${isAnonymous ? 'Someone' : authorDisplayName} answered: "$qTitle"',
            'targetType': 'question',
            'targetId': questionId,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (_) {}

    return answerRef.id;
  }

  @override
  Future<void> updateAnswer({
    required String answerId,
    required String editorUid,
    required String body,
  }) async {
    final isOwner = await isAnswerOwner(answerId, editorUid);
    if (!isOwner) {
      throw Exception('Unauthorized: You do not own this answer.');
    }

    await _firestore.collection('answers').doc(answerId).update({
      'body': body.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteAnswer({
    required String answerId,
    required String authorUid,
  }) async {
    final isOwner = await isAnswerOwner(answerId, authorUid);
    if (!isOwner) {
      throw Exception('Unauthorized: You do not own this answer.');
    }

    final batch = _firestore.batch();
    batch.delete(_firestore.collection('answers').doc(answerId));
    batch.delete(_firestore.collection('answerOwners').doc(answerId));
    await batch.commit();
  }

  @override
  Future<int> voteAnswer({
    required String answerId,
    required String uid,
    required int voteValue,
  }) async {
    final voteDocId = '${answerId}_$uid';
    final voteRef = _firestore.collection('votes').doc(voteDocId);

    return _firestore.runTransaction<int>((transaction) async {
      final voteSnap = await transaction.get(voteRef);

      if (!voteSnap.exists) {
        transaction.set(voteRef, {
          'id': voteDocId,
          'targetId': answerId,
          'targetType': 'answer',
          'uid': uid,
          'value': voteValue,
          'createdAt': DateTime.now().toIso8601String(),
        });
        return voteValue;
      } else {
        final currentValue = (voteSnap.data()?['value'] ?? 0) as int;
        if (currentValue == voteValue) {
          transaction.delete(voteRef);
          return 0;
        } else {
          transaction.update(voteRef, {
            'value': voteValue,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          return voteValue;
        }
      }
    });
  }

  @override
  Future<int> getUserVote(String answerId, String uid) async {
    final voteDocId = '${answerId}_$uid';
    final voteSnap = await _firestore.collection('votes').doc(voteDocId).get();
    if (!voteSnap.exists) return 0;
    return (voteSnap.data()?['value'] ?? 0) as int;
  }

  @override
  Future<int> getAnswerVoteCount(String answerId) async {
    try {
      final upSnap = await _firestore
          .collection('votes')
          .where('targetId', isEqualTo: answerId)
          .where('value', isEqualTo: 1)
          .count()
          .get();
      final downSnap = await _firestore
          .collection('votes')
          .where('targetId', isEqualTo: answerId)
          .where('value', isEqualTo: -1)
          .count()
          .get();

      return (upSnap.count ?? 0) - (downSnap.count ?? 0);
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<bool> markAnswerHelpful({
    required String questionId,
    required String answerId,
    required String questionAuthorUid,
  }) async {
    final answerRef = _firestore.collection('answers').doc(answerId);
    final questionRef = _firestore.collection('questions').doc(questionId);

    final answerSnap = await answerRef.get();
    if (!answerSnap.exists) return false;

    final currentHelpful = answerSnap.data()?['isHelpful'] ?? false;
    final newHelpful = !currentHelpful;

    await answerRef.update({
      'isHelpful': newHelpful,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await questionRef.update({
      'helpfulAnswerId': newHelpful ? answerId : FieldValue.delete(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Secure Spark-only architecture: helpful notifications are intentionally not
    // created from the client because they require server-side validation of the actual
    // answer relationship. The question/answer relationship is already persisted in the
    // answer record, but the notification payload cannot be tied to a concrete answerId
    // without server-side enforcement.
    return newHelpful;
  }
}
