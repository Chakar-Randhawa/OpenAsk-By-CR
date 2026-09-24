class NotificationModel {
  final String id;
  final String recipientUid;
  final String senderUid;
  final String type;
  final String title;
  final String body;
  final String targetType;
  final String targetId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientUid,
    this.senderUid = '',
    required this.type,
    required this.title,
    required this.body,
    required this.targetType,
    required this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'recipientUid': recipientUid,
      'type': type,
      'title': title,
      'body': body,
      'targetType': targetType,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };

    if (senderUid.isNotEmpty) {
      map['senderUid'] = senderUid;
    }

    return map;
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      recipientUid: map['recipientUid'] ?? '',
      senderUid: map['senderUid'] ?? '',
      type: map['type'] ?? 'system',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      targetType: map['targetType'] ?? 'question',
      targetId: map['targetId'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? recipientUid,
    String? senderUid,
    String? type,
    String? title,
    String? body,
    String? targetType,
    String? targetId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientUid: recipientUid ?? this.recipientUid,
      senderUid: senderUid ?? this.senderUid,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.recipientUid == recipientUid &&
        other.senderUid == senderUid &&
        other.type == type &&
        other.title == title &&
        other.body == body &&
        other.targetType == targetType &&
        other.targetId == targetId &&
        other.isRead == isRead &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    recipientUid,
    senderUid,
    type,
    title,
    body,
    targetType,
    targetId,
    isRead,
    createdAt,
  );
}
