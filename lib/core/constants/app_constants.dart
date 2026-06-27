class AppConstants {
  AppConstants._();

  static const String appName = 'TesterMandi';
  static const String appTagline = 'Connect · Test · Grow';
  static const String appVersion = '1.0.0';

  // Platform Google Group — all testers must join this once
  static const String platformGroupEmail = 'appvora-tester@googlegroups.com';
  static const String platformGroupUrl = 'https://groups.google.com/g/appvora-tester';
  static const String platformGroupName = 'Appvora Tester Community';

  // Google Play Console Requirements
  static const int minimumTesters = 12;
  static const int testingDurationDays = 14;

  // Tester Limits
  static const int maxActiveTestsPerTester = 3;
  static const int checkinWindowHours = 20;
  static const int abandonCooldownHours = 24;
  static const int minRatingToJoin = 2; // out of 5

  // Pagination
  static const int appsPageSize = 15;
  static const int messagesPageSize = 30;

  // Storage
  static const String userAvatarFolder = 'avatars';
  static const String appIconFolder = 'app_icons';
  static const String appScreenshotFolder = 'screenshots';

  // Cache keys
  static const String cachedUserRole = 'cached_user_role';
  static const String cachedUserId = 'cached_user_id';
  static const String onboardingDone = 'onboarding_done';
}
