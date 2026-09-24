/// Deterministic vote document model. Keyed as {targetId}_{uid}.
class VoteModel {
  final String id;
  final String targetId;
  final String targetType; // 'question' or 'answer'
  final String uid;
  final int value; // +1 or -1
  final DateTime createdAt;
  final DateTime? updatedAt;

  VoteModel({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.uid,
    required this.value,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetId': targetId,
      'targetType': targetType,
      'uid': uid,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
    };
  }

  factory VoteModel.fromMap(Map<String, dynamic> map, String docId) {
    return VoteModel(
      id: docId,
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? 'question',
      uid: map['uid'] ?? '',
      value: (map['value'] ?? 0) as int,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }
}
