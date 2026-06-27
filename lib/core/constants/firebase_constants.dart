class FirebaseConstants {
  FirebaseConstants._();

  // Collections
  static const String usersCollection = 'users';
  static const String appsCollection = 'apps';
  static const String testingProgressCollection = 'testingProgress';
  static const String conversationsCollection = 'conversations';
  static const String messagesSubCollection = 'messages';
  static const String ratingsCollection = 'ratings';
  static const String notificationsCollection = 'notifications';

  // User document fields
  static const String fieldUid = 'uid';
  static const String fieldName = 'name';
  static const String fieldEmail = 'email';
  static const String fieldRole = 'role';
  static const String fieldRating = 'rating';
  static const String fieldFcmToken = 'fcmToken';
  static const String fieldCompletedTests = 'completedTests';
  static const String fieldIsVerified = 'isVerified';
  static const String fieldIsBanned = 'isBanned';
  static const String fieldJoinedAt = 'joinedAt';
  static const String fieldLastSeen = 'lastSeen';

  // App document fields
  static const String fieldDeveloperId = 'developerId';
  static const String fieldStatus = 'status';
  static const String fieldCurrentTesterCount = 'currentTesterCount';
  static const String fieldStartedAt = 'startedAt';
  static const String fieldDeadline = 'deadline';
  static const String fieldCreatedAt = 'createdAt';
}
