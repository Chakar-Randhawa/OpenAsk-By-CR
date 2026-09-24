/// Audit log model for tracking moderation and administrative actions.
class AuditLogModel {
  final String id;
  final String actorUid;
  final String action; // 'remove_question', 'remove_answer', 'ban_user', 'suspend_user', 'dismiss_report'
  final String targetType; // 'question', 'answer', 'user', 'report'
  final String targetId;
  final String reason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actorUid': actorUid,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String docId) {
    return AuditLogModel(
      id: docId,
      actorUid: map['actorUid'] ?? '',
      action: map['action'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      reason: map['reason'] ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
