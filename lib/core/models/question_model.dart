class QuestionModel {
  final String id;
  final String authorUid;
  final bool isAnonymous;
  final String authorDisplayName;
  final String? authorPhotoUrl;
  final String title;
  final String body;
  final String categoryId;
  final String categoryName;
  final List<String> tags;
  final String? imageUrl;
  final int answerCount;
  final int viewCount;
  final int voteCount;
  final String? helpfulAnswerId;
  final String status;
  final DateTime createdAt;

  QuestionModel({
    required this.id,
    required this.authorUid,
    required this.isAnonymous,
    required this.authorDisplayName,
    this.authorPhotoUrl,
    required this.title,
    required this.body,
    required this.categoryId,
    required this.categoryName,
    required this.tags,
    this.imageUrl,
    this.answerCount = 0,
    this.viewCount = 0,
    this.voteCount = 0,
    this.helpfulAnswerId,
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorUid': authorUid,
      'isAnonymous': isAnonymous,
      'authorDisplayName': isAnonymous ? 'Anonymous' : authorDisplayName,
      'authorPhotoUrl': isAnonymous ? null : authorPhotoUrl,
      'title': title,
      'body': body,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'tags': tags,
      'imageUrl': imageUrl,
      'answerCount': answerCount,
      'viewCount': viewCount,
      'voteCount': voteCount,
      'helpfulAnswerId': helpfulAnswerId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map, String docId) {
    return QuestionModel(
      id: docId,
      authorUid: map['authorUid'] ?? '',
      isAnonymous: map['isAnonymous'] ?? false,
      authorDisplayName: map['authorDisplayName'] ?? 'Member',
      authorPhotoUrl: map['authorPhotoUrl'],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      imageUrl: map['imageUrl'],
      answerCount: (map['answerCount'] ?? 0) as int,
      viewCount: (map['viewCount'] ?? 0) as int,
      voteCount: (map['voteCount'] ?? 0) as int,
      helpfulAnswerId: map['helpfulAnswerId'],
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
