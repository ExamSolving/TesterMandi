import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../domain/entities/daily_proof.dart';
import '../../domain/repositories/proofs_repository.dart';
import '../models/daily_proof_model.dart';

class ProofsRepositoryImpl implements ProofsRepository {
  ProofsRepositoryImpl(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('proofs');

  @override
  Future<Map<int, String>> fetchDayStatuses(String participationId) async {
    final snap = await _col
        .where('participationId', isEqualTo: participationId)
        .get();
    return {
      for (final d in snap.docs)
        (d.data()['dayNumber'] as int? ?? 1):
            (d.data()['status'] as String? ?? 'pending'),
    };
  }

  @override
  Future<String?> fetchTodayPendingProofId(String participationId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final snap = await _col
        .where('participationId', isEqualTo: participationId)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = data['submittedAt'] as Timestamp?;
      final status = data['status'] as String? ?? 'pending';
      if (status == 'pending' &&
          ts != null &&
          !ts.toDate().isBefore(startOfDay)) {
        return doc.id;
      }
    }
    return null;
  }

  @override
  Future<void> approveDayProof(String proofId) async {
    await _col.doc(proofId).update({'status': 'approved'});
  }

  @override
  Future<DailyProof?> fetchProofById(String proofId) async {
    final doc = await _col.doc(proofId).get();
    if (!doc.exists) return null;
    return DailyProofModel.fromFirestore(doc);
  }

  @override
  Future<void> rejectDayProof(String proofId) async {
    final doc = await _col.doc(proofId).get();
    final urls = (doc.data()?['screenshotUrls'] as List<dynamic>?)
            ?.cast<String>() ??
        [];

    // Delete Storage files in parallel, ignore individual errors
    await Future.wait(
      urls.map((url) async {
        try {
          await _storage.refFromURL(url).delete();
        } catch (e) {
          debugPrint('[Proofs] Storage delete failed for $url: $e');
        }
      }),
    );

    await _col.doc(proofId).update({'status': 'rejected'});
  }

  @override
  Future<void> submitProof({
    required String participationId,
    required String appId,
    required String appName,
    required String testerId,
    required List<File> screenshots,
    required String feedback,
    required int dayNumber,
  }) async {
    // Upload screenshots to Firebase Storage in parallel
    final now = DateTime.now();
    final datePath =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final uploadFutures = screenshots.asMap().entries.map((entry) async {
      final compressed =
          await ImageCompressor.compressProofFile(entry.value.absolute.path);
      final ref = _storage
          .ref('proofs/$appId/$testerId/$datePath/screenshot_${entry.key}.jpg');
      await ref.putData(compressed, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    });
    final urls = await Future.wait(uploadFutures);

    // Write proof document
    final id = const Uuid().v4();
    final model = DailyProofModel(
      id: id,
      participationId: participationId,
      appId: appId,
      appName: appName,
      testerId: testerId,
      screenshotUrls: urls,
      feedback: feedback,
      submittedAt: Timestamp.now(),
      dayNumber: dayNumber,
    );

    final batch = _db.batch();
    batch.set(_col.doc(id), model.toFirestore());
    // Update participation's last proof timestamp and count
    batch.update(
      _db.collection('participations').doc(participationId),
      {
        'lastProofAt': Timestamp.now(),
        'proofCount': FieldValue.increment(1),
      },
    );
    await batch.commit();
  }

  @override
  Future<List<DailyProof>> fetchProofsForParticipation(
      String participationId) async {
    final snap = await _col
        .where('participationId', isEqualTo: participationId)
        .get();
    final list = snap.docs.map(DailyProofModel.fromFirestore).toList();
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  @override
  Future<bool> hasSubmittedTodayFor(String participationId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    // Single-field query only — no composite index needed.
    // Filter by date client-side.
    final snap = await _col
        .where('participationId', isEqualTo: participationId)
        .get();
    return snap.docs.any((doc) {
      final ts = doc.data()['submittedAt'] as Timestamp?;
      if (ts == null) return false;
      return !ts.toDate().isBefore(startOfDay);
    });
  }

  @override
  Future<bool> sendReminderToTester({
    required String participationId,
    required String testerId,
    required String appName,
    required String senderName,
  }) async {
    final now = Timestamp.now();

    // Throttle: only 1 reminder per hour per tester per participation
    final partDoc = await _db.collection('participations').doc(participationId).get();
    final lastTs = partDoc.data()?['lastReminderToTesterAt'] as Timestamp?;
    if (lastTs != null &&
        now.toDate().difference(lastTs.toDate()).inMinutes < 60) {
      return false;
    }

    final userDoc = await _db.collection('users').doc(testerId).get();
    final fcmToken = userDoc.data()?['fcmToken'] as String?;

    final batch = _db.batch();
    batch.update(_db.collection('participations').doc(participationId), {
      'lastReminderToTesterAt': now,
    });
    if (fcmToken != null && fcmToken.isNotEmpty) {
      batch.set(_db.collection('reminder_requests').doc(), {
        'targetToken': fcmToken,
        'title': '⏰ Proof reminder',
        'body': '$senderName is waiting for your Day proof for "$appName"',
        'createdAt': now,
        'type': 'remind_tester',
      });
    }
    await batch.commit();
    return true;
  }

  @override
  Future<bool> sendReminderToOwner({
    required String participationId,
    required String ownerId,
    required String appName,
    required String senderName,
  }) async {
    final now = Timestamp.now();

    final partDoc = await _db.collection('participations').doc(participationId).get();
    final lastTs = partDoc.data()?['lastReminderToOwnerAt'] as Timestamp?;
    if (lastTs != null &&
        now.toDate().difference(lastTs.toDate()).inMinutes < 60) {
      return false;
    }

    final userDoc = await _db.collection('users').doc(ownerId).get();
    final fcmToken = userDoc.data()?['fcmToken'] as String?;

    final batch = _db.batch();
    batch.update(_db.collection('participations').doc(participationId), {
      'lastReminderToOwnerAt': now,
    });
    if (fcmToken != null && fcmToken.isNotEmpty) {
      batch.set(_db.collection('reminder_requests').doc(), {
        'targetToken': fcmToken,
        'title': '⏰ Review reminder',
        'body': '$senderName is waiting for you to review their proof for "$appName"',
        'createdAt': now,
        'type': 'remind_owner',
      });
    }
    await batch.commit();
    return true;
  }

}
