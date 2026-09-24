import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/question_model.dart';

abstract class QuestionRepository {
  Future<List<QuestionModel>> fetchQuestions({
    required String feedType,
    String? categoryId,
    String? authorUid,
    String? language,
    bool? unansweredOnly,
    List<String>? followedCategoryIds,
    DocumentSnapshot? startAfterDoc,
    int limit = 25,
  });

  Future<QuestionModel?> getQuestionById(String id, {String? viewerUid});

  Future<bool> isQuestionOwner(String questionId, String uid);

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
    String language = 'en',
    String? imageUrl,
  });

  Future<void> updateQuestion({
    required String questionId,
    required String editorUid,
    required String title,
    required String body,
    required List<String> tags,
  });

  Future<void> updateQuestionStatus({
    required String questionId,
    required String userUid,
    required String newStatus, // 'active', 'closed', 'resolved'
  });

  Future<void> deleteQuestion(String questionId, String authorUid);

  Future<bool> toggleSaveQuestion(String questionId, String uid);

  Future<List<QuestionModel>> fetchSavedQuestions(String uid);

  Future<List<QuestionModel>> searchQuestions({
    required String query,
    String? categoryId,
    String? language,
    bool? unansweredOnly,
  });

  Future<List<QuestionModel>> findSimilarQuestions({
    required String title,
    required String categoryId,
  });

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
  Future<bool> isQuestionOwner(String questionId, String uid) async {
    try {
      // 1. Check private ownership mapping (safe for anonymous & named posts)
      final ownerDoc = await _firestore.collection('questionOwners').doc(questionId).get();
      if (ownerDoc.exists && ownerDoc.data()?['ownerUid'] == uid) {
        return true;
      }
      // 2. Fallback check public question authorUid if named
      final qDoc = await _firestore.collection('questions').doc(questionId).get();
      if (qDoc.exists && qDoc.data()?['authorUid'] == uid) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<List<QuestionModel>> fetchQuestions({
    required String feedType,
    String? categoryId,
    String? authorUid,
    String? language,
    bool? unansweredOnly,
    List<String>? followedCategoryIds,
    DocumentSnapshot? startAfterDoc,
    int limit = 25,
  }) async {
    Query<Map<String, dynamic>> q = _firestore.collection('questions');

    // Only active or resolved questions in public feeds
    q = q.where('status', whereIn: ['active', 'resolved', 'closed']);

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

    if (startAfterDoc != null) {
      q = q.startAfterDocument(startAfterDoc);
    }

    final snapshot = await q.limit(limit).get();
    var results = snapshot.docs.map((d) => QuestionModel.fromMap(d.data(), d.id)).toList();

    // Client-side lightweight secondary filters if composite indexes aren't exhausted
    if (language != null && language.isNotEmpty) {
      results = results.where((item) => item.language == language).toList();
    }
    if (unansweredOnly == true) {
      results = results.where((item) => item.answerCount == 0).toList();
    }

    return results;
  }

  @override
  Future<QuestionModel?> getQuestionById(String id, {String? viewerUid}) async {
    final doc = await _firestore.collection('questions').doc(id).get();
    if (!doc.exists) return null;

    bool isSaved = false;
    if (viewerUid != null && viewerUid.isNotEmpty) {
      final saveSnap = await _firestore.collection('savedQuestions').doc('${id}_$viewerUid').get();
      isSaved = saveSnap.exists;
    }

    return QuestionModel.fromMap(doc.data()!, doc.id, isSaved: isSaved);
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
    String language = 'en',
    String? imageUrl,
  }) async {
    final batch = _firestore.batch();
    final questionRef = _firestore.collection('questions').doc();
    final ownerRef = _firestore.collection('questionOwners').doc(questionRef.id);
    final now = DateTime.now();

    // 1. Private ownership record: stores authenticated author UID privately
    batch.set(ownerRef, {
      'id': questionRef.id,
      'ownerUid': authorUid,
      'isAnonymous': isAnonymous,
      'createdAt': now.toIso8601String(),
    });

    // 2. Public question document: NEVER includes authorUid when anonymous
    final newQuestion = QuestionModel(
      id: questionRef.id,
      authorUid: isAnonymous ? null : authorUid,
      isAnonymous: isAnonymous,
      authorDisplayName: isAnonymous ? 'Anonymous' : authorDisplayName,
      authorPhotoUrl: isAnonymous ? null : authorPhotoUrl,
      title: title.trim(),
      body: body.trim(),
      categoryId: categoryId,
      categoryName: categoryName,
      tags: tags.map((t) => t.trim().toLowerCase()).toList(),
      imageUrl: imageUrl,
      answerCount: 0,
      viewCount: 0,
      voteCount: 0,
      status: 'active',
      language: language,
      createdAt: now,
      updatedAt: now,
    );

    batch.set(questionRef, newQuestion.toMap());
    await batch.commit();

    return questionRef.id;
  }

  @override
  Future<void> updateQuestion({
    required String questionId,
    required String editorUid,
    required String title,
    required String body,
    required List<String> tags,
  }) async {
    final hasOwnership = await isQuestionOwner(questionId, editorUid);
    if (!hasOwnership) {
      throw Exception('Unauthorized: You do not own this question.');
    }

    await _firestore.collection('questions').doc(questionId).update({
      'title': title.trim(),
      'body': body.trim(),
      'tags': tags.map((t) => t.trim().toLowerCase()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateQuestionStatus({
    required String questionId,
    required String userUid,
    required String newStatus,
  }) async {
    final hasOwnership = await isQuestionOwner(questionId, userUid);
    if (!hasOwnership) {
      throw Exception('Unauthorized: Only question owner can change question status.');
    }

    await _firestore.collection('questions').doc(questionId).update({
      'status': newStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteQuestion(String questionId, String authorUid) async {
    final hasOwnership = await isQuestionOwner(questionId, authorUid);
    if (!hasOwnership) {
      throw Exception('Unauthorized: You do not own this question.');
    }

    final batch = _firestore.batch();
    batch.delete(_firestore.collection('questions').doc(questionId));
    batch.delete(_firestore.collection('questionOwners').doc(questionId));
    await batch.commit();
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
      if (qDoc.exists && qDoc.data()?['status'] != 'deleted') {
        results.add(QuestionModel.fromMap(qDoc.data()!, qDoc.id, isSaved: true));
      }
    }
    return results;
  }

  @override
  Future<List<QuestionModel>> searchQuestions({
    required String query,
    String? categoryId,
    String? language,
    bool? unansweredOnly,
  }) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    Query<Map<String, dynamic>> q = _firestore
        .collection('questions')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }

    final snap = await q.limit(60).get();
    var all = snap.docs.map((d) => QuestionModel.fromMap(d.data(), d.id)).toList();

    return all.where((item) {
      final inTitle = item.title.toLowerCase().contains(clean);
      final inBody = item.body.toLowerCase().contains(clean);
      final inCategory = item.categoryName.toLowerCase().contains(clean);
      final inTags = item.tags.any((t) => t.toLowerCase().contains(clean));

      if (language != null && language.isNotEmpty && item.language != language) {
        return false;
      }
      if (unansweredOnly == true && item.answerCount > 0) {
        return false;
      }

      return inTitle || inBody || inCategory || inTags;
    }).toList();
  }

  @override
  Future<List<QuestionModel>> findSimilarQuestions({
    required String title,
    required String categoryId,
  }) async {
    final words = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toSet();

    if (words.isEmpty) return [];

    final snap = await _firestore
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'active')
        .limit(30)
        .get();

    final all = snap.docs.map((d) => QuestionModel.fromMap(d.data(), d.id)).toList();

    return all.where((q) {
      final qTitleWords = q.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
          .split(RegExp(r'\s+'))
          .toSet();
      final intersection = words.intersection(qTitleWords);
      return intersection.isNotEmpty;
    }).take(5).toList();
  }
}
