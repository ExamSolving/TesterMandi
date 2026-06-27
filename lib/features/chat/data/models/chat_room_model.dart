import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_room.dart';

class ChatRoomModel {
  static ChatRoom fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final rawNames = d['participantNames'] as Map<String, dynamic>? ?? {};
    final rawUnread = d['unreadCount'] as Map<String, dynamic>? ?? {};
    return ChatRoom(
      id: doc.id,
      participantIds: List<String>.from(d['participantIds'] ?? []),
      participantNames: rawNames.map((k, v) => MapEntry(k, v.toString())),
      fromAppName: d['fromAppName'] as String? ?? '',
      toAppName: d['toAppName'] as String? ?? '',
      fromAppIconUrl: d['fromAppIconUrl'] as String?,
      toAppIconUrl: d['toAppIconUrl'] as String?,
      lastMessage: d['lastMessage'] as String?,
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: d['lastMessageSenderId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: rawUnread.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  static Map<String, dynamic> toFirestore({
    required String id,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required String fromAppName,
    required String toAppName,
    String? fromAppIconUrl,
    String? toAppIconUrl,
    required Timestamp createdAt,
  }) =>
      {
        'participantIds': participantIds,
        'participantNames': participantNames,
        'fromAppName': fromAppName,
        'toAppName': toAppName,
        'fromAppIconUrl': fromAppIconUrl,
        'toAppIconUrl': toAppIconUrl,
        'lastMessage': null,
        'lastMessageAt': null,
        'lastMessageSenderId': null,
        'createdAt': createdAt,
        'unreadCount': {for (final uid in participantIds) uid: 0},
      };
}
