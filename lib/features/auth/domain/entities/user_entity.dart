enum UserStatus { active, suspended, banned }

class UserEntity {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.photoUrl,
    this.fcmToken,
    this.status = UserStatus.active,
    this.isBanned = false,
    this.publishedAppIds = const [],
    this.activeTestingIds = const [],
    this.reputationScore = 0.0,
    this.totalTestsCompleted = 0,
    this.publishedAppCount = 0,
  });

  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final String? photoUrl;
  final String? fcmToken;
  final UserStatus status;
  final bool isBanned;
  final List<String> publishedAppIds;
  final List<String> activeTestingIds;
  final double reputationScore;
  final int totalTestsCompleted;
  final int publishedAppCount;

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    String? photoUrl,
    String? fcmToken,
    UserStatus? status,
    bool? isBanned,
    List<String>? publishedAppIds,
    List<String>? activeTestingIds,
    double? reputationScore,
    int? totalTestsCompleted,
    int? publishedAppCount,
  }) =>
      UserEntity(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        createdAt: createdAt ?? this.createdAt,
        photoUrl: photoUrl ?? this.photoUrl,
        fcmToken: fcmToken ?? this.fcmToken,
        status: status ?? this.status,
        isBanned: isBanned ?? this.isBanned,
        publishedAppIds: publishedAppIds ?? this.publishedAppIds,
        activeTestingIds: activeTestingIds ?? this.activeTestingIds,
        reputationScore: reputationScore ?? this.reputationScore,
        totalTestsCompleted: totalTestsCompleted ?? this.totalTestsCompleted,
        publishedAppCount: publishedAppCount ?? this.publishedAppCount,
      );
}
