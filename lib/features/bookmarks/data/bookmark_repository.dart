import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/bookmark_model.dart';
import '../../../core/models/question_model.dart';

abstract class BookmarkRepository {
  Future<bool> toggleBookmark(String questionId, String uid, {String? collectionId});
  Future<List<QuestionModel>> getSavedQuestions(String uid, {String? collectionId});
  Future<List<BookmarkCollectionModel>> getCollections(String uid);
  Future<String> createCollection(String uid, String title, {String? description});
  Future<void> deleteCollection(String collectionId, String uid);
  Future<void> renameCollection(String collectionId, String uid, String newTitle);
}

class FirestoreBookmarkRepository implements BookmarkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<bool> toggleBookmark(String questionId, String uid, {String? collectionId}) async {
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
        'collectionId': collectionId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    }
  }

  @override
  Future<List<QuestionModel>> getSavedQuestions(String uid, {String? collectionId}) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection('savedQuestions')
        .where('uid', isEqualTo: uid);

    if (collectionId != null && collectionId.isNotEmpty) {
      q = q.where('collectionId', isEqualTo: collectionId);
    }

    final snap = await q.limit(50).get();
    final questionIds = snap.docs.map((d) => d.data()['questionId'] as String).toList();
    if (questionIds.isEmpty) return [];

    final List<QuestionModel> results = [];
    for (final id in questionIds) {
      final doc = await _firestore.collection('questions').doc(id).get();
      if (doc.exists && doc.data()?['status'] != 'deleted') {
        results.add(QuestionModel.fromMap(doc.data()!, doc.id, isSaved: true));
      }
    }
    return results;
  }

  @override
  Future<List<BookmarkCollectionModel>> getCollections(String uid) async {
    final snap = await _firestore
        .collection('collections')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => BookmarkCollectionModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<String> createCollection(String uid, String title, {String? description}) async {
    final docRef = _firestore.collection('collections').doc();
    final now = DateTime.now();

    final col = BookmarkCollectionModel(
      id: docRef.id,
      uid: uid,
      title: title.trim(),
      description: description?.trim(),
      itemCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(col.toMap());
    return docRef.id;
  }

  @override
  Future<void> deleteCollection(String collectionId, String uid) async {
    final doc = await _firestore.collection('collections').doc(collectionId).get();
    if (!doc.exists || doc.data()?['uid'] != uid) {
      throw Exception('Unauthorized: You cannot delete this collection.');
    }
    await doc.reference.delete();
  }

  @override
  Future<void> renameCollection(String collectionId, String uid, String newTitle) async {
    final doc = await _firestore.collection('collections').doc(collectionId).get();
    if (!doc.exists || doc.data()?['uid'] != uid) {
      throw Exception('Unauthorized: You cannot modify this collection.');
    }
    await doc.reference.update({
      'title': newTitle.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
