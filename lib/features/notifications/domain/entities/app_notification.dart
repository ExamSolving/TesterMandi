import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  swapRequest,
  swapAccepted,
  swapDenied,
  proofSubmitted,
  proofApproved,
  proofRejected,
  newMessage,
  dailyReminder,
  newApp,
  general,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.data = const {},
    this.isRead = false,
  });

  final String id;
  final String recipientId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, String> data;
  final bool isRead;
  final Timestamp createdAt;
}
