import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/daily_proof.dart';

class DailyProofModel extends DailyProof {
  const DailyProofModel({
    required super.id,
    required super.participationId,
    required super.appId,
    required super.appName,
    required super.testerId,
    required super.screenshotUrls,
    required super.feedback,
    required super.submittedAt,
    required super.dayNumber,
    super.status,
  });

  factory DailyProofModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyProofModel(
      id: doc.id,
      participationId: data['participationId'] as String? ?? '',
      appId: data['appId'] as String? ?? '',
      appName: data['appName'] as String? ?? '',
      testerId: data['testerId'] as String? ?? '',
      screenshotUrls: List<String>.from(data['screenshotUrls'] as List? ?? []),
      feedback: data['feedback'] as String? ?? '',
      submittedAt: data['submittedAt'] as Timestamp? ?? Timestamp.now(),
      dayNumber: data['dayNumber'] as int? ?? 1,
      status: data['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'participationId': participationId,
        'appId': appId,
        'appName': appName,
        'testerId': testerId,
        'screenshotUrls': screenshotUrls,
        'feedback': feedback,
        'submittedAt': submittedAt,
        'dayNumber': dayNumber,
        'status': status,
      };
}
