import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/swap_request.dart';

class SwapRequestModel extends SwapRequest {
  const SwapRequestModel({
    required super.id,
    required super.fromUserId,
    required super.fromUserName,
    required super.fromAppId,
    required super.fromAppName,
    required super.toUserId,
    required super.toAppId,
    required super.toAppName,
    required super.status,
    required super.createdAt,
    super.fromAppIconUrl,
    super.toAppIconUrl,
  });

  factory SwapRequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SwapRequestModel(
      id: doc.id,
      fromUserId: d['fromUserId'] as String? ?? '',
      fromUserName: d['fromUserName'] as String? ?? '',
      fromAppId: d['fromAppId'] as String? ?? '',
      fromAppName: d['fromAppName'] as String? ?? '',
      fromAppIconUrl: d['fromAppIconUrl'] as String?,
      toUserId: d['toUserId'] as String? ?? '',
      toAppId: d['toAppId'] as String? ?? '',
      toAppName: d['toAppName'] as String? ?? '',
      toAppIconUrl: d['toAppIconUrl'] as String?,
      status: _parseStatus(d['status'] as String?),
      createdAt: d['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromAppId': fromAppId,
        'fromAppName': fromAppName,
        'fromAppIconUrl': fromAppIconUrl,
        'toUserId': toUserId,
        'toAppId': toAppId,
        'toAppName': toAppName,
        'toAppIconUrl': toAppIconUrl,
        'status': status.name,
        'createdAt': createdAt,
      };

  static SwapStatus _parseStatus(String? s) {
    switch (s) {
      case 'accepted': return SwapStatus.accepted;
      case 'denied':   return SwapStatus.denied;
      default:         return SwapStatus.pending;
    }
  }
}
