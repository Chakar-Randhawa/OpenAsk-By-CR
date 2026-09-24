import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/comment_model.dart';

abstract class CommentRepository {
  Future<List<CommentModel>> getComments(String targetId, {String targetType = 'question'});
  Stream<List<CommentModel>> streamComments(String targetId);
  Future<String> addComment({
    required String targetType,
    required String targetId,
    String? parentCommentId,
    required String authorUid,
    required String authorDisplayName,
    String? authorPhotoUrl,
    required String text,
  });
  Future<void> updateComment({
    required String commentId,
    required String authorUid,
    required String text,
  });
  Future<void> deleteComment({
    required String commentId,
    required String authorUid,
  });
  Future<bool> toggleLikeComment(String commentId, String uid);
}

class FirestoreCommentRepository implements CommentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<CommentModel>> getComments(String targetId, {String targetType = 'question'}) async {
    final snap = await _firestore
        .collection('comments')
        .where('targetId', isEqualTo: targetId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .get();

    return snap.docs.map((d) => CommentModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Stream<List<CommentModel>> streamComments(String targetId) {
    return _firestore
        .collection('comments')
        .where('targetId', isEqualTo: targetId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommentModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Future<String> addComment({
    required String targetType,
    required String targetId,
    String? parentCommentId,
    required String authorUid,
    required String authorDisplayName,
    String? authorPhotoUrl,
    required String text,
  }) async {
    final docRef = _firestore.collection('comments').doc();
    final now = DateTime.now();

    final comment = CommentModel(
      id: docRef.id,
      targetType: targetType,
      targetId: targetId,
      parentCommentId: parentCommentId,
      authorUid: authorUid,
      authorDisplayName: authorDisplayName,
      authorPhotoUrl: authorPhotoUrl,
      text: text.trim(),
      likesCount: 0,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(comment.toMap());
    return docRef.id;
  }

  @override
  Future<void> updateComment({
    required String commentId,
    required String authorUid,
    required String text,
  }) async {
    final doc = await _firestore.collection('comments').doc(commentId).get();
    if (!doc.exists || doc.data()?['authorUid'] != authorUid) {
      throw Exception('Unauthorized: You cannot edit this comment.');
    }

    await doc.reference.update({
      'text': text.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteComment({
    required String commentId,
    required String authorUid,
  }) async {
    final doc = await _firestore.collection('comments').doc(commentId).get();
    if (!doc.exists || doc.data()?['authorUid'] != authorUid) {
      throw Exception('Unauthorized: You cannot delete this comment.');
    }

    await doc.reference.update({
      'status': 'deleted',
      'text': '[deleted]',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<bool> toggleLikeComment(String commentId, String uid) async {
    final likeId = '${commentId}_$uid';
    final likeRef = _firestore.collection('commentLikes').doc(likeId);
    final snap = await likeRef.get();

    if (snap.exists) {
      await likeRef.delete();
      return false;
    } else {
      await likeRef.set({
        'id': likeId,
        'commentId': commentId,
        'uid': uid,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    }
  }
}
