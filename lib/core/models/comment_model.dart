/// Comment and reply model for questions and answers.
class CommentModel {
  final String id;
  final String targetType; // 'question' or 'answer'
  final String targetId;
  final String? parentCommentId; // null for top-level comments, string for replies
  final String authorUid;
  final String authorDisplayName;
  final String? authorPhotoUrl;
  final String text;
  final int likesCount;
  final String status; // 'active', 'deleted'
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommentModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.parentCommentId,
    required this.authorUid,
    required this.authorDisplayName,
    this.authorPhotoUrl,
    required this.text,
    this.likesCount = 0,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetType': targetType,
      'targetId': targetId,
      'parentCommentId': parentCommentId,
      'authorUid': authorUid,
      'authorDisplayName': authorDisplayName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'likesCount': likesCount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String docId) {
    return CommentModel(
      id: docId,
      targetType: map['targetType'] ?? 'question',
      targetId: map['targetId'] ?? '',
      parentCommentId: map['parentCommentId'],
      authorUid: map['authorUid'] ?? '',
      authorDisplayName: map['authorDisplayName'] ?? 'Member',
      authorPhotoUrl: map['authorPhotoUrl'],
      text: map['text'] ?? '',
      likesCount: (map['likesCount'] ?? 0) as int,
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }
}
