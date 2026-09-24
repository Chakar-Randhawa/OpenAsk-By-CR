import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/category_model.dart';
import '../../../core/constants/categories_data.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
  Future<bool> followCategory(String categoryId, String uid);
  Future<Set<String>> getFollowedCategoryIds(String uid);
  Future<void> seedCategoriesIfEmpty();
}

class FirestoreCategoryRepository implements CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> seedCategoriesIfEmpty() async {
    try {
      final snap = await _firestore.collection('categories').limit(1).get();
      if (snap.docs.isEmpty) {
        final batch = _firestore.batch();
        for (final cat in kInitialCategories) {
          final docRef = _firestore.collection('categories').doc(cat.id);
          batch.set(docRef, cat.toMap());
        }
        await batch.commit();
      }
    } catch (_) {
      // Ignored if permissions restrict non-admin
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final snap = await _firestore.collection('categories').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => CategoryModel.fromMap(d.data(), d.id)).toList();
      }
      // If Firestore collection has not yet been populated via server-side deployment,
      // return canonical application configuration constants (read-only)
      return kInitialCategories;
    } catch (e) {
      // Offline fallback strictly for static application configuration
      return kInitialCategories;
    }
  }

  @override
  Future<bool> followCategory(String categoryId, String uid) async {
    final followId = '${categoryId}_$uid';
    final docRef = _firestore.collection('categoryFollows').doc(followId);
    final snap = await docRef.get();

    if (snap.exists) {
      await docRef.delete();
      return false;
    } else {
      await docRef.set({
        'id': followId,
        'categoryId': categoryId,
        'uid': uid,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    }
  }

  @override
  Future<Set<String>> getFollowedCategoryIds(String uid) async {
    final snap = await _firestore
        .collection('categoryFollows')
        .where('uid', isEqualTo: uid)
        .get();

    return snap.docs.map((d) => d.data()['categoryId'] as String).toSet();
  }
}
