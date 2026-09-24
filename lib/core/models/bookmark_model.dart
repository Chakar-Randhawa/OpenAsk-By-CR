/// Bookmark and collection domain models for OpenAsk.
class BookmarkModel {
  final String id;
  final String questionId;
  final String uid;
  final String? collectionId;
  final DateTime createdAt;

  BookmarkModel({
    required this.id,
    required this.questionId,
    required this.uid,
    this.collectionId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionId': questionId,
      'uid': uid,
      'collectionId': collectionId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookmarkModel(
      id: docId,
      questionId: map['questionId'] ?? '',
      uid: map['uid'] ?? '',
      collectionId: map['collectionId'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class BookmarkCollectionModel {
  final String id;
  final String uid;
  final String title;
  final String? description;
  final int itemCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BookmarkCollectionModel({
    required this.id,
    required this.uid,
    required this.title,
    this.description,
    this.itemCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'title': title,
      'description': description,
      'itemCount': itemCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
    };
  }

  factory BookmarkCollectionModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookmarkCollectionModel(
      id: docId,
      uid: map['uid'] ?? '',
      title: map['title'] ?? 'Collection',
      description: map['description'],
      itemCount: (map['itemCount'] ?? 0) as int,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }
}
