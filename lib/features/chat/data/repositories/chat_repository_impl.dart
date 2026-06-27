import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  @override
  Stream<List<ChatRoom>> watchChatRooms(String userId) {
    return _chats
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final rooms = snap.docs.map(ChatRoomModel.fromFirestore).toList();
      rooms.sort((a, b) {
        if (a.lastMessageAt == null && b.lastMessageAt == null) {
          return b.createdAt.compareTo(a.createdAt);
        }
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });
      return rooms;
    });
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatRoomId) {
    return _chats
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessageModel.fromFirestore).toList());
  }

  @override
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String text,
    required List<String> participantIds,
  }) async {
    final msgRef = _chats.doc(chatRoomId).collection('messages').doc();
    final now = Timestamp.now();
    final batch = _db.batch();

    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'sentAt': now,
    });

    final unreadUpdate = <String, dynamic>{
      'lastMessage': text,
      'lastMessageAt': now,
      'lastMessageSenderId': senderId,
    };
    for (final uid in participantIds) {
      if (uid != senderId) {
        unreadUpdate['unreadCount.$uid'] = FieldValue.increment(1);
      }
    }
    batch.update(_chats.doc(chatRoomId), unreadUpdate);

    await batch.commit();

    // Fire-and-forget push notifications to all recipients
    _notifyRecipients(
      participantIds: participantIds,
      senderId: senderId,
      senderName: senderName,
      text: text,
    );
  }

  void _notifyRecipients({
    required List<String> participantIds,
    required String senderId,
    required String senderName,
    required String text,
  }) {
    final recipients = participantIds.where((id) => id != senderId).toList();
    if (recipients.isEmpty) return;

    Future(() async {
      final now = Timestamp.now();
      final preview = text.length > 60 ? '${text.substring(0, 60)}…' : text;

      for (final recipientId in recipients) {
        try {
          final userDoc = await _db.collection('users').doc(recipientId).get();
          final fcmToken = userDoc.data()?['fcmToken'] as String?;
          if (fcmToken == null || fcmToken.isEmpty) continue;

          await _db.collection('notification_requests').add({
            'targetToken': fcmToken,
            'recipientId': recipientId,
            'title': senderName,
            'body': preview,
            'type': 'new_message',
            'data': {'type': 'new_message', 'recipientId': recipientId},
            'createdAt': now,
          });
        } catch (_) {}
      }
    });
  }

  @override
  Future<void> markAllRead(String chatRoomId, String userId) async {
    try {
      await _chats.doc(chatRoomId).update({'unreadCount.$userId': 0});
    } catch (_) {}
  }
}
