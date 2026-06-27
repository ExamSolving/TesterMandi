class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.fromAppName,
    required this.toAppName,
    this.fromAppIconUrl,
    this.toAppIconUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    required this.createdAt,
    required this.unreadCount,
  });

  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String fromAppName;
  final String toAppName;
  final String? fromAppIconUrl;
  final String? toAppIconUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final DateTime createdAt;
  final Map<String, int> unreadCount;

  String otherUserId(String myUid) =>
      participantIds.firstWhere((id) => id != myUid, orElse: () => '');

  String otherUserName(String myUid) =>
      participantNames[otherUserId(myUid)] ?? 'Unknown';

  int myUnread(String myUid) => unreadCount[myUid] ?? 0;

  bool get hasMessages => lastMessage != null;
}
