import 'package:cloud_firestore/cloud_firestore.dart';

enum SwapStatus { pending, accepted, denied }

class SwapRequest {
  const SwapRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromAppId,
    required this.fromAppName,
    required this.toUserId,
    required this.toAppId,
    required this.toAppName,
    required this.status,
    required this.createdAt,
    this.fromAppIconUrl,
    this.toAppIconUrl,
  });

  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromAppId;
  final String fromAppName;
  final String? fromAppIconUrl;
  final String toUserId;
  final String toAppId;
  final String toAppName;
  final String? toAppIconUrl;
  final SwapStatus status;
  final Timestamp createdAt;
}
