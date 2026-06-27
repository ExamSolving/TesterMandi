import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.recipientId,
    required super.title,
    required super.body,
    required super.type,
    required super.createdAt,
    super.data = const {},
    super.isRead = false,
  });

  factory AppNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawData = (d['data'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));
    return AppNotificationModel(
      id: doc.id,
      recipientId: d['recipientId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      type: _parseType(d['type'] as String? ?? ''),
      data: rawData,
      isRead: d['isRead'] as bool? ?? false,
      createdAt: d['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  factory AppNotificationModel.fromRemoteMessage(RemoteMessage message) {
    final rawData = message.data.map((k, v) => MapEntry(k, v.toString()));
    return AppNotificationModel(
      id: message.messageId ?? const Uuid().v4(),
      recipientId: rawData['recipientId'] ?? '',
      title: message.notification?.title ?? rawData['title'] ?? '',
      body: message.notification?.body ?? rawData['body'] ?? '',
      type: _parseType(rawData['type'] ?? ''),
      data: rawData,
      isRead: false,
      createdAt: Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'type': _typeToString(type),
        'data': data,
        'isRead': isRead,
        'createdAt': createdAt,
      };

  static NotificationType _parseType(String s) {
    switch (s) {
      case 'swap_request': return NotificationType.swapRequest;
      case 'swap_accepted': return NotificationType.swapAccepted;
      case 'swap_denied': return NotificationType.swapDenied;
      case 'proof_submitted': return NotificationType.proofSubmitted;
      case 'proof_approved': return NotificationType.proofApproved;
      case 'proof_rejected': return NotificationType.proofRejected;
      case 'new_message': return NotificationType.newMessage;
      case 'daily_reminder': return NotificationType.dailyReminder;
      case 'new_app': return NotificationType.newApp;
      default: return NotificationType.general;
    }
  }

  static String _typeToString(NotificationType t) {
    switch (t) {
      case NotificationType.swapRequest: return 'swap_request';
      case NotificationType.swapAccepted: return 'swap_accepted';
      case NotificationType.swapDenied: return 'swap_denied';
      case NotificationType.proofSubmitted: return 'proof_submitted';
      case NotificationType.proofApproved: return 'proof_approved';
      case NotificationType.proofRejected: return 'proof_rejected';
      case NotificationType.newMessage: return 'new_message';
      case NotificationType.dailyReminder: return 'daily_reminder';
      case NotificationType.newApp: return 'new_app';
      case NotificationType.general: return 'general';
    }
  }
}
