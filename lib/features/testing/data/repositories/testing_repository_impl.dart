import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/test_participation.dart';
import '../../domain/repositories/testing_repository.dart';
import '../models/test_participation_model.dart';

class TestingRepositoryImpl implements TestingRepository {
  TestingRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _participations =>
      _db.collection('participations');

  CollectionReference<Map<String, dynamic>> get _apps =>
      _db.collection('apps');

  @override
  Future<void> joinApp({
    required String appId,
    required String appName,
    required String appOwnerName,
    required String appOwnerId,
    required String testerId,
    required String testerName,
    required String optInUrl,
    String? iconUrl,
  }) async {
    final batch = _db.batch();

    final pRef = _participations.doc();
    batch.set(
      pRef,
      TestParticipationModel(
        id: pRef.id,
        appId: appId,
        appName: appName,
        appOwnerName: appOwnerName,
        appOwnerId: appOwnerId,
        testerId: testerId,
        testerName: testerName,
        joinedAt: Timestamp.now(),
        optInUrl: optInUrl,
        iconUrl: iconUrl,
        participationStatus: 'active',
        proofsSubmitted: 0,
      ).toFirestore(),
    );

    batch.update(_apps.doc(appId), {
      'testerIds': FieldValue.arrayUnion([testerId]),
    });

    await batch.commit();
  }

  @override
  Future<List<TestParticipation>> fetchUserParticipations(
      String userId) async {
    final snap = await _participations
        .where('testerId', isEqualTo: userId)
        .orderBy('joinedAt', descending: true)
        .get();
    return snap.docs.map(TestParticipationModel.fromFirestore).toList();
  }

  @override
  Future<List<TestParticipation>> fetchTestersForMyApps(String ownerId) async {
    final snap = await _participations
        .where('appOwnerId', isEqualTo: ownerId)
        .orderBy('joinedAt', descending: true)
        .get();
    return snap.docs.map(TestParticipationModel.fromFirestore).toList();
  }

  @override
  Future<bool> isAlreadyTesting({
    required String userId,
    required String appId,
  }) async {
    final snap = await _participations
        .where('testerId', isEqualTo: userId)
        .where('appId', isEqualTo: appId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Stream<List<TestParticipation>> watchUserParticipations(String userId) {
    return _participations.where('testerId', isEqualTo: userId).snapshots().map(
      (snap) {
        final list = snap.docs.map(TestParticipationModel.fromFirestore).toList()
          ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
        return list;
      },
    );
  }

  @override
  Stream<List<TestParticipation>> watchTestersForMyApps(String ownerId) {
    return _participations.where('appOwnerId', isEqualTo: ownerId).snapshots().map(
      (snap) {
        final list = snap.docs.map(TestParticipationModel.fromFirestore).toList()
          ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
        return list;
      },
    );
  }

  @override
  Future<void> reactivateParticipation(String participationId) async {
    final doc = await _participations.doc(participationId).get();
    final data = doc.data();
    if (data == null) return;

    final appId = data['appId'] as String? ?? '';
    final testerId = data['testerId'] as String? ?? '';

    final batch = _db.batch();

    batch.update(_participations.doc(participationId), {
      'status': 'active',
      'joinedAt': Timestamp.now(),
      'proofsSubmitted': 0,
      'deactivatedAt': FieldValue.delete(),
      'reactivationCount': FieldValue.increment(1),
    });

    if (appId.isNotEmpty && testerId.isNotEmpty) {
      batch.update(_apps.doc(appId), {
        'testerIds': FieldValue.arrayUnion([testerId]),
      });
    }

    await batch.commit();
  }

}
