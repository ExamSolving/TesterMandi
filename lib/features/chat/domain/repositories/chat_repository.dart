import '../entities/chat_message.dart';
import '../entities/chat_room.dart';

abstract class ChatRepository {
  Stream<List<ChatRoom>> watchChatRooms(String userId);
  Stream<List<ChatMessage>> watchMessages(String chatRoomId);
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String text,
    required List<String> participantIds,
  });
  Future<void> markAllRead(String chatRoomId, String userId);
}
