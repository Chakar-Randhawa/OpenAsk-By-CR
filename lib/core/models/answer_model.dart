/// Answer domain model for OpenAsk.
/// Public answer documents NEVER expose authorUid when isAnonymous is true.
/// Private ownership is securely maintained in /answerOwners/{answerId}.
class AnswerModel {
  final String id;
  final String questionId;
  final String? authorUid; // Null/omitted when isAnonymous is true
  final bool isAnonymous;
  final String authorDisplayName;
  final String? authorPhotoUrl;
  final String body;
  final int voteCount;
  final int helpfulCount;
  final bool isHelpful;
  final int commentCount;
  final String status; // 'active', 'deleted'
  final DateTime createdAt;
  final DateTime? updatedAt;

  AnswerModel({
    required this.id,
    required this.questionId,
    this.authorUid,
    required this.isAnonymous,
    required this.authorDisplayName,
    this.authorPhotoUrl,
    required this.body,
    this.voteCount = 0,
    this.helpfulCount = 0,
    this.isHelpful = false,
    this.commentCount = 0,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'questionId': questionId,
      'isAnonymous': isAnonymous,
      'authorDisplayName': isAnonymous ? 'Anonymous' : authorDisplayName,
      'authorPhotoUrl': isAnonymous ? null : authorPhotoUrl,
      'body': body,
      'voteCount': voteCount,
      'helpfulCount': helpfulCount,
      'isHelpful': isHelpful,
      'commentCount': commentCount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
    };

    // SECURE ANONYMITY: Only include authorUid if explicitly NOT anonymous
    if (!isAnonymous && authorUid != null && authorUid!.isNotEmpty) {
      map['authorUid'] = authorUid;
    }

    return map;
  }

  factory AnswerModel.fromMap(Map<String, dynamic> map, String docId) {
    final isAnon = map['isAnonymous'] ?? false;
    return AnswerModel(
      id: docId,
      questionId: map['questionId'] ?? '',
      authorUid: isAnon ? null : map['authorUid'],
      isAnonymous: isAnon,
      authorDisplayName: isAnon ? 'Anonymous' : (map['authorDisplayName'] ?? 'Member'),
      authorPhotoUrl: isAnon ? null : map['authorPhotoUrl'],
      body: map['body'] ?? '',
      voteCount: (map['voteCount'] ?? 0) as int,
      helpfulCount: (map['helpfulCount'] ?? 0) as int,
      isHelpful: map['isHelpful'] ?? false,
      commentCount: (map['commentCount'] ?? 0) as int,
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }

  AnswerModel copyWith({
    String? id,
    String? questionId,
    String? authorUid,
    bool? isAnonymous,
    String? authorDisplayName,
    String? authorPhotoUrl,
    String? body,
    int? voteCount,
    int? helpfulCount,
    bool? isHelpful,
    int? commentCount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnswerModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      authorUid: authorUid ?? this.authorUid,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      body: body ?? this.body,
      voteCount: voteCount ?? this.voteCount,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isHelpful: isHelpful ?? this.isHelpful,
      commentCount: commentCount ?? this.commentCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
