import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatController extends GetxController {
  ChatController(this._repo);
  final ChatRepository _repo;

  StreamSubscription<List<ChatRoom>>? _roomsSub;
  StreamSubscription<List<ChatMessage>>? _messagesSub;

  final rooms = <ChatRoom>[].obs;
  final roomsLoaded = false.obs;
  final messages = <ChatMessage>[].obs;
  final messagesLoaded = false.obs;
  final isSending = false.obs;
  final messageCtrl = TextEditingController();
  final scrollCtrl = ScrollController();

  String get _uid => Get.find<AuthController>().currentUser.value?.uid ?? '';
  String get _myName =>
      Get.find<AuthController>().currentUser.value?.displayName ?? '';

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    ever(auth.currentUser, (_) => _resubscribeRooms());
    if (auth.currentUser.value != null) _resubscribeRooms();
  }

  void _resubscribeRooms() {
    if (_uid.isEmpty) {
      _roomsSub?.cancel();
      return;
    }
    roomsLoaded.value = false;
    _roomsSub?.cancel();
    _roomsSub = _repo.watchChatRooms(_uid).listen(
      (list) {
        rooms.value = list;
        roomsLoaded.value = true;
      },
      onError: (e) => debugPrint('[ChatController] watchRooms error: $e'),
    );
  }

  void openChat(ChatRoom room) {
    messagesLoaded.value = false;
    messages.value = [];
    _messagesSub?.cancel();
    _messagesSub = _repo.watchMessages(room.id).listen(
      (list) {
        messages.value = list;
        messagesLoaded.value = true;
        _scrollToBottom();
      },
      onError: (e) => debugPrint('[ChatController] watchMessages error: $e'),
    );
    _repo.markAllRead(room.id, _uid);
    Get.toNamed(AppRoutes.chatDetail, arguments: room);
  }

  void closeChat() {
    _messagesSub?.cancel();
    messages.value = [];
    messagesLoaded.value = false;
  }

  Future<void> sendMessage(ChatRoom room) async {
    final text = messageCtrl.text.trim();
    if (text.isEmpty || _uid.isEmpty || isSending.value) return;
    isSending.value = true;
    messageCtrl.clear();
    try {
      await _repo.sendMessage(
        chatRoomId: room.id,
        senderId: _uid,
        senderName: _myName,
        text: text,
        participantIds: room.participantIds,
      );
      _scrollToBottom();
    } catch (e) {
      debugPrint('[ChatController] sendMessage error: $e');
    } finally {
      isSending.value = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int get totalUnread {
    if (_uid.isEmpty) return 0;
    return rooms.fold(0, (sum, r) => sum + r.myUnread(_uid));
  }

  @override
  void onClose() {
    _roomsSub?.cancel();
    _messagesSub?.cancel();
    messageCtrl.dispose();
    scrollCtrl.dispose();
    super.onClose();
  }
}
