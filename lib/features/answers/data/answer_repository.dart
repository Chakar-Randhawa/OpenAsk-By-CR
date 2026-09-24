import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/answer_model.dart';

abstract class AnswerRepository {
  Future<List<AnswerModel>> fetchAnswersForQuestion(String questionId);
  Stream<List<AnswerModel>> streamAnswers(String questionId);
  Future<String> createAnswer({
    required String questionId,
    required String authorUid,
    required String authorDisplayName,
    String? authorPhotoUrl,
    required bool isAnonymous,
    required String body,
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
  Future<List<AnswerModel>> fetchAnswersForQuestion(String questionId) async {
    final snap = await _firestore
        .collection('answers')
        .where('questionId', isEqualTo: questionId)
        .orderBy('createdAt', descending: false)
        .limit(100)
        .get();

    return snap.docs.map((d) => AnswerModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Stream<List<AnswerModel>> streamAnswers(String questionId) {
    return _firestore
        .collection('answers')
        .where('questionId', isEqualTo: questionId)
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AnswerModel.fromMap(d.data(), d.id)).toList());
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
    final docRef = _firestore.collection('answers').doc();
    final now = DateTime.now();

    final answer = AnswerModel(
      id: docRef.id,
      questionId: questionId,
      authorUid: authorUid,
      isAnonymous: isAnonymous,
      authorDisplayName: isAnonymous ? 'Anonymous' : authorDisplayName,
      authorPhotoUrl: isAnonymous ? null : authorPhotoUrl,
      body: body.trim(),
      voteCount: 0,
      helpfulCount: 0,
      isHelpful: false,
      status: 'active',
      createdAt: now,
    );

    await docRef.set(answer.toMap());

    // Spark Architecture: Dispatch secure in-app notification directly to question author
    try {
      final questionSnap = await _firestore.collection('questions').doc(questionId).get();
      if (questionSnap.exists) {
        final qData = questionSnap.data()!;
        final qAuthorUid = qData['authorUid'] as String?;
        final qTitle = qData['title'] as String? ?? 'your question';

        // Notify question author if not answering own question
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
    } catch (_) {
      // In-app notification creation is non-blocking for answer submission
    }

    return docRef.id;
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
        // New vote
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
          // Remove vote
          transaction.delete(voteRef);
          return 0;
        } else {
          // Switch vote
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

    // Spark Architecture: Dispatch secure in-app notification to answer author
    if (newHelpful) {
      final answerAuthorUid = answerSnap.data()?['authorUid'] as String?;
      if (answerAuthorUid != null && answerAuthorUid != questionAuthorUid) {
        try {
          final notifRef = _firestore.collection('notifications').doc();
          await notifRef.set({
            'id': notifRef.id,
            'recipientUid': answerAuthorUid,
            'senderUid': questionAuthorUid,
            'type': 'helpful',
            'title': 'Solution Marked Helpful!',
            'body': 'Your answer was selected as the helpful solution.',
            'targetType': 'question',
            'targetId': questionId,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    }

    return newHelpful;
  }
}
