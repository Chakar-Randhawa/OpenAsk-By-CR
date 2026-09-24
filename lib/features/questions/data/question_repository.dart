import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/question_model.dart';

abstract class QuestionRepository {
  Future<List<QuestionModel>> fetchQuestions({
    required String feedType,
    String? categoryId,
    String? authorUid,
    List<String>? followedCategoryIds,
    int limit = 30,
  });
  Future<QuestionModel?> getQuestionById(String id);
  Future<String> createQuestion({
    required String authorUid,
    required String authorDisplayName,
    String? authorPhotoUrl,
    required bool isAnonymous,
    required String title,
    required String body,
    required String categoryId,
    required String categoryName,
    required List<String> tags,
    String? imageUrl,
  });
  Future<void> deleteQuestion(String questionId, String authorUid);
  Future<bool> toggleSaveQuestion(String questionId, String uid);
  Future<List<QuestionModel>> fetchSavedQuestions(String uid);
  Future<List<QuestionModel>> searchQuestions(String query);
  Future<void> recordView(String questionId, String? viewerUid);
}

class FirestoreQuestionRepository implements QuestionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> recordView(String questionId, String? viewerUid) async {
    if (viewerUid == null || viewerUid.isEmpty) return;
    try {
      await _firestore
          .collection('questions')
          .doc(questionId)
          .collection('views')
          .doc(viewerUid)
          .set({
        'viewedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-fatal view logging
    }
  }

  @override
  Future<List<QuestionModel>> fetchQuestions({
    required String feedType,
    String? categoryId,
    String? authorUid,
    List<String>? followedCategoryIds,
    int limit = 30,
  }) async {
    Query<Map<String, dynamic>> q = _firestore.collection('questions');

    if (authorUid != null && authorUid.isNotEmpty) {
      q = q.where('authorUid', isEqualTo: authorUid).orderBy('createdAt', descending: true);
    } else if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId).orderBy('createdAt', descending: true);
    } else if (feedType == 'trending') {
      q = q.orderBy('viewCount', descending: true).orderBy('createdAt', descending: true);
    } else if (feedType == 'following' && followedCategoryIds != null && followedCategoryIds.isNotEmpty) {
      final safeIds = followedCategoryIds.take(10).toList();
      q = q.where('categoryId', whereIn: safeIds).orderBy('createdAt', descending: true);
    } else {
      // 'new' and 'forYou' default
      q = q.orderBy('createdAt', descending: true);
    }

    final snapshot = await q.limit(limit).get();
    return snapshot.docs.map((d) => QuestionModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<QuestionModel?> getQuestionById(String id) async {
    final doc = await _firestore.collection('questions').doc(id).get();
    if (!doc.exists) return null;
    return QuestionModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<String> createQuestion({
    required String authorUid,
    required String authorDisplayName,
    String? authorPhotoUrl,
    required bool isAnonymous,
    required String title,
    required String body,
    required String categoryId,
    required String categoryName,
    required List<String> tags,
    String? imageUrl,
  }) async {
    final docRef = _firestore.collection('questions').doc();
    final now = DateTime.now();

    final newQuestion = QuestionModel(
      id: docRef.id,
      authorUid: authorUid,
      isAnonymous: isAnonymous,
      authorDisplayName: isAnonymous ? 'Anonymous' : authorDisplayName,
      authorPhotoUrl: isAnonymous ? null : authorPhotoUrl,
      title: title.trim(),
      body: body.trim(),
      categoryId: categoryId,
      categoryName: categoryName,
      tags: tags,
      imageUrl: imageUrl,
      voteCount: 0,
      answerCount: 0,
      viewCount: 0,
      status: 'active',
      createdAt: now,
    );

    await docRef.set(newQuestion.toMap());
    return docRef.id;
  }

  @override
  Future<void> deleteQuestion(String questionId, String authorUid) async {
    final docRef = _firestore.collection('questions').doc(questionId);
    final snap = await docRef.get();
    if (snap.exists && snap.data()?['authorUid'] == authorUid) {
      await docRef.delete();
    }
  }

  @override
  Future<bool> toggleSaveQuestion(String questionId, String uid) async {
    final saveId = '${questionId}_$uid';
    final saveRef = _firestore.collection('savedQuestions').doc(saveId);
    final snap = await saveRef.get();

    if (snap.exists) {
      await saveRef.delete();
      return false;
    } else {
      await saveRef.set({
        'id': saveId,
        'questionId': questionId,
        'uid': uid,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    }
  }

  @override
  Future<List<QuestionModel>> fetchSavedQuestions(String uid) async {
    final snap = await _firestore
        .collection('savedQuestions')
        .where('uid', isEqualTo: uid)
        .limit(50)
        .get();

    final questionIds = snap.docs.map((d) => d.data()['questionId'] as String).toList();
    if (questionIds.isEmpty) return [];

    final List<QuestionModel> results = [];
    for (final id in questionIds) {
      final qDoc = await _firestore.collection('questions').doc(id).get();
      if (qDoc.exists) {
        results.add(QuestionModel.fromMap(qDoc.data()!, qDoc.id));
      }
    }
    return results;
  }

  @override
  Future<List<QuestionModel>> searchQuestions(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    // Query active questions ordered by recency and filter matches accurately
    final snap = await _firestore
        .collection('questions')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(60)
        .get();

    final all = snap.docs.map((d) => QuestionModel.fromMap(d.data(), d.id)).toList();
    return all.where((q) {
      final inTitle = q.title.toLowerCase().contains(clean);
      final inBody = q.body.toLowerCase().contains(clean);
      final inCategory = q.categoryName.toLowerCase().contains(clean);
      final inTags = q.tags.any((t) => t.toLowerCase().contains(clean));
      return inTitle || inBody || inCategory || inTags;
    }).toList();
  }
}
