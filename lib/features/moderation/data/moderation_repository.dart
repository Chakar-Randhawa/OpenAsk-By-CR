import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/report_model.dart';

abstract class ModerationRepository {
  Future<void> submitReport({
    required String reporterUid,
    required String targetType,
    required String targetId,
    required String reason,
    String details = '',
  });
  Future<void> blockUser(String blockerUid, String blockedUid);
  Future<void> unblockUser(String blockerUid, String blockedUid);
  Future<void> muteUser(String muterUid, String mutedUid);
  Future<void> unmuteUser(String muterUid, String mutedUid);
}

class FirestoreModerationRepository implements ModerationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> submitReport({
    required String reporterUid,
    required String targetType,
    required String targetId,
    required String reason,
    String details = '',
  }) async {
    final docRef = _firestore.collection('reports').doc();
    final report = ReportModel(
      id: docRef.id,
      reporterUid: reporterUid,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      details: details.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await docRef.set(report.toMap());
  }

  @override
  Future<void> blockUser(String blockerUid, String blockedUid) async {
    final blockId = '${blockerUid}_$blockedUid';
    await _firestore.collection('blocks').doc(blockId).set({
      'id': blockId,
      'blockerUid': blockerUid,
      'blockedUid': blockedUid,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> unblockUser(String blockerUid, String blockedUid) async {
    final blockId = '${blockerUid}_$blockedUid';
    await _firestore.collection('blocks').doc(blockId).delete();
  }

  @override
  Future<void> muteUser(String muterUid, String mutedUid) async {
    final muteId = '${muterUid}_$mutedUid';
    await _firestore.collection('mutes').doc(muteId).set({
      'id': muteId,
      'muterUid': muterUid,
      'mutedUid': mutedUid,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> unmuteUser(String muterUid, String mutedUid) async {
    final muteId = '${muterUid}_$mutedUid';
    await _firestore.collection('mutes').doc(muteId).delete();
  }
}
