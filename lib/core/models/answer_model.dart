class AnswerModel {
  final String id;
  final String questionId;
  final String authorUid;
  final bool isAnonymous;
  final String authorDisplayName;
  final String? authorPhotoUrl;
  final String body;
  final int voteCount;
  final int helpfulCount;
  final bool isHelpful;
  final String status;
  final DateTime createdAt;

  AnswerModel({
    required this.id,
    required this.questionId,
    required this.authorUid,
    required this.isAnonymous,
    required this.authorDisplayName,
    this.authorPhotoUrl,
    required this.body,
    this.voteCount = 0,
    this.helpfulCount = 0,
    this.isHelpful = false,
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionId': questionId,
      'authorUid': authorUid,
      'isAnonymous': isAnonymous,
      'authorDisplayName': isAnonymous ? 'Anonymous' : authorDisplayName,
      'authorPhotoUrl': isAnonymous ? null : authorPhotoUrl,
      'body': body,
      'voteCount': voteCount,
      'helpfulCount': helpfulCount,
      'isHelpful': isHelpful,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AnswerModel.fromMap(Map<String, dynamic> map, String docId) {
    return AnswerModel(
      id: docId,
      questionId: map['questionId'] ?? '',
      authorUid: map['authorUid'] ?? '',
      isAnonymous: map['isAnonymous'] ?? false,
      authorDisplayName: map['authorDisplayName'] ?? 'Member',
      authorPhotoUrl: map['authorPhotoUrl'],
      body: map['body'] ?? '',
      voteCount: (map['voteCount'] ?? 0) as int,
      helpfulCount: (map['helpfulCount'] ?? 0) as int,
      isHelpful: map['isHelpful'] ?? false,
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
