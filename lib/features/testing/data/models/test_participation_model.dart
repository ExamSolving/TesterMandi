import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/test_participation.dart';

class TestParticipationModel extends TestParticipation {
  const TestParticipationModel({
    required super.id,
    required super.appId,
    required super.appName,
    required super.appOwnerName,
    required super.appOwnerId,
    required super.testerId,
    required super.testerName,
    required super.joinedAt,
    required super.optInUrl,
    super.iconUrl,
    super.participationStatus = 'active',
    super.proofsSubmitted = 0,
    super.completionTier,
    super.lastProofAt,
    super.deactivatedAt,
    super.reactivationCount = 0,
  });

  factory TestParticipationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TestParticipationModel(
      id: doc.id,
      appId: d['appId'] as String? ?? '',
      appName: d['appName'] as String? ?? '',
      appOwnerName: d['appOwnerName'] as String? ?? '',
      appOwnerId: d['appOwnerId'] as String? ?? '',
      testerId: d['testerId'] as String? ?? '',
      testerName: d['testerName'] as String? ?? '',
      joinedAt: d['joinedAt'] as Timestamp? ?? Timestamp.now(),
      optInUrl: d['optInUrl'] as String? ?? '',
      iconUrl: d['iconUrl'] as String?,
      participationStatus: d['status'] as String? ?? 'active',
      proofsSubmitted: (d['proofsSubmitted'] as num?)?.toInt() ?? 0,
      completionTier: completionTierFromString(d['completionTier'] as String?),
      lastProofAt: d['lastProofAt'] as Timestamp?,
      deactivatedAt: d['deactivatedAt'] as Timestamp?,
      reactivationCount: (d['reactivationCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'appId': appId,
        'appName': appName,
        'appOwnerName': appOwnerName,
        'appOwnerId': appOwnerId,
        'testerId': testerId,
        'testerName': testerName,
        'joinedAt': joinedAt,
        'optInUrl': optInUrl,
        'iconUrl': iconUrl,
        'status': participationStatus,
        'proofsSubmitted': proofsSubmitted,
        'reactivationCount': reactivationCount,
      };
}
