import 'package:cloud_firestore/cloud_firestore.dart';

class DailyProof {
  const DailyProof({
    required this.id,
    required this.participationId,
    required this.appId,
    required this.appName,
    required this.testerId,
    required this.screenshotUrls,
    required this.feedback,
    required this.submittedAt,
    required this.dayNumber,
    this.status = 'pending',
  });

  final String id;
  final String participationId;
  final String appId;
  final String appName;
  final String testerId;
  final List<String> screenshotUrls;
  final String feedback;
  final Timestamp submittedAt;
  final int dayNumber;
  /// 'pending' | 'approved' | 'rejected'
  final String status;

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';

  String get dateLabel {
    final d = submittedAt.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }
}
