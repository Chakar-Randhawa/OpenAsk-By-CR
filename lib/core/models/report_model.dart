class ReportModel {
  final String id;
  final String reporterUid;
  final String targetType;
  final String targetId;
  final String reason;
  final String details;
  final String status;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reporterUid,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.details = '',
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterUid': reporterUid,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'details': details,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReportModel(
      id: docId,
      reporterUid: map['reporterUid'] ?? '',
      targetType: map['targetType'] ?? 'question',
      targetId: map['targetId'] ?? '',
      reason: map['reason'] ?? 'Other',
      details: map['details'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
