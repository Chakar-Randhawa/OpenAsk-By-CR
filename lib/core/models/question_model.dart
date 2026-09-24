/// Question domain model for OpenAsk.
/// Public question documents NEVER expose authorUid when isAnonymous is true.
/// Private ownership is securely maintained in /questionOwners/{questionId}.
class QuestionModel {
  final String id;
  final String? authorUid; // Null/omitted when isAnonymous is true
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
  final String status; // 'active', 'resolved', 'closed', 'deleted'
  final String language;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSaved;

  QuestionModel({
    required this.id,
    this.authorUid,
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
    this.language = 'en',
    required this.createdAt,
    this.updatedAt,
    this.isSaved = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
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
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
    };

    // SECURE ANONYMITY: Only include authorUid if explicitly NOT anonymous
    if (!isAnonymous && authorUid != null && authorUid!.isNotEmpty) {
      map['authorUid'] = authorUid;
    }

    return map;
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map, String docId, {bool isSaved = false}) {
    final isAnon = map['isAnonymous'] ?? false;
    return QuestionModel(
      id: docId,
      // If document was marked anonymous, authorUid must be null for privacy
      authorUid: isAnon ? null : map['authorUid'],
      isAnonymous: isAnon,
      authorDisplayName: isAnon ? 'Anonymous' : (map['authorDisplayName'] ?? 'Member'),
      authorPhotoUrl: isAnon ? null : map['authorPhotoUrl'],
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
      language: map['language'] ?? 'en',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      isSaved: isSaved,
    );
  }

  QuestionModel copyWith({
    String? id,
    String? authorUid,
    bool? isAnonymous,
    String? authorDisplayName,
    String? authorPhotoUrl,
    String? title,
    String? body,
    String? categoryId,
    String? categoryName,
    List<String>? tags,
    String? imageUrl,
    int? answerCount,
    int? viewCount,
    int? voteCount,
    String? helpfulAnswerId,
    String? status,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSaved,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      authorUid: authorUid ?? this.authorUid,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      title: title ?? this.title,
      body: body ?? this.body,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      answerCount: answerCount ?? this.answerCount,
      viewCount: viewCount ?? this.viewCount,
      voteCount: voteCount ?? this.voteCount,
      helpfulAnswerId: helpfulAnswerId ?? this.helpfulAnswerId,
      status: status ?? this.status,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
