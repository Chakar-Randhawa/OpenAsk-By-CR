import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/report_model.dart';
import '../../../core/models/audit_log_model.dart';
import '../../../core/models/user_profile_model.dart';

abstract class AdminRepository {
  Future<List<ReportModel>> getReportQueue({String status = 'pending'});
  Future<void> resolveReport({
    required String reportId,
    required String actionTaken,
    required String moderatorUid,
  });
  Future<void> removeContent({
    required String targetType,
    required String targetId,
    required String reason,
    required String moderatorUid,
  });
  Future<void> setAccountStatus({
    required String targetUid,
    required String newStatus, // 'active', 'suspended', 'banned'
    required String reason,
    required String moderatorUid,
  });
  Future<List<AuditLogModel>> getAuditLogs({int limit = 50});
  Future<bool> isModeratorOrAdmin(String uid);
}

class FirestoreAdminRepository implements AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<bool> isModeratorOrAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final role = doc.data()?['role'] as String?;
      return role == 'admin' || role == 'moderator';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ReportModel>> getReportQueue({String status = 'pending'}) async {
    final snap = await _firestore
        .collection('reports')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snap.docs.map((d) => ReportModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<void> resolveReport({
    required String reportId,
    required String actionTaken,
    required String moderatorUid,
  }) async {
    final hasPerm = await isModeratorOrAdmin(moderatorUid);
    if (!hasPerm) throw Exception('Unauthorized: Moderator role required.');

    final batch = _firestore.batch();
    final reportRef = _firestore.collection('reports').doc(reportId);
    batch.update(reportRef, {
      'status': 'resolved',
      'resolution': actionTaken,
      'resolvedBy': moderatorUid,
      'resolvedAt': DateTime.now().toIso8601String(),
    });

    final logRef = _firestore.collection('auditLogs').doc();
    batch.set(logRef, {
      'id': logRef.id,
      'actorUid': moderatorUid,
      'action': 'resolve_report',
      'targetType': 'report',
      'targetId': reportId,
      'reason': actionTaken,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  @override
  Future<void> removeContent({
    required String targetType,
    required String targetId,
    required String reason,
    required String moderatorUid,
  }) async {
    final hasPerm = await isModeratorOrAdmin(moderatorUid);
    if (!hasPerm) throw Exception('Unauthorized: Moderator role required.');

    final batch = _firestore.batch();
    if (targetType == 'question') {
      batch.update(_firestore.collection('questions').doc(targetId), {
        'status': 'deleted',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else if (targetType == 'answer') {
      batch.update(_firestore.collection('answers').doc(targetId), {
        'status': 'deleted',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    final logRef = _firestore.collection('auditLogs').doc();
    batch.set(logRef, {
      'id': logRef.id,
      'actorUid': moderatorUid,
      'action': 'remove_content',
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  @override
  Future<void> setAccountStatus({
    required String targetUid,
    required String newStatus,
    required String reason,
    required String moderatorUid,
  }) async {
    final hasPerm = await isModeratorOrAdmin(moderatorUid);
    if (!hasPerm) throw Exception('Unauthorized: Admin role required.');

    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(targetUid), {
      'status': newStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final logRef = _firestore.collection('auditLogs').doc();
    batch.set(logRef, {
      'id': logRef.id,
      'actorUid': moderatorUid,
      'action': 'set_status_$newStatus',
      'targetType': 'user',
      'targetId': targetUid,
      'reason': reason,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs({int limit = 50}) async {
    final snap = await _firestore
        .collection('auditLogs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => AuditLogModel.fromMap(d.data(), d.id)).toList();
  }
}
