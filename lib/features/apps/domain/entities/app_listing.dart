import 'package:cloud_firestore/cloud_firestore.dart';

enum AppCategory {
  games, education, entertainment, business, productivity, finance,
  healthFitness, lifestyle, social, communication, travel, shopping,
  news, music, photography, sports, food, personalization, weather,
  tools, other,
}

enum AppStatus { active, full, expired }

extension AppCategoryLabel on AppCategory {
  String get categoryLabel {
    switch (this) {
      case AppCategory.games:           return 'Games';
      case AppCategory.education:       return 'Education';
      case AppCategory.entertainment:   return 'Entertainment';
      case AppCategory.business:        return 'Business';
      case AppCategory.productivity:    return 'Productivity';
      case AppCategory.finance:         return 'Finance';
      case AppCategory.healthFitness:   return 'Health & Fitness';
      case AppCategory.lifestyle:       return 'Lifestyle';
      case AppCategory.social:          return 'Social';
      case AppCategory.communication:   return 'Communication';
      case AppCategory.travel:          return 'Travel & Local';
      case AppCategory.shopping:        return 'Shopping';
      case AppCategory.news:            return 'News & Magazines';
      case AppCategory.music:           return 'Music & Audio';
      case AppCategory.photography:     return 'Photography';
      case AppCategory.sports:          return 'Sports';
      case AppCategory.food:            return 'Food & Drink';
      case AppCategory.personalization: return 'Personalization';
      case AppCategory.weather:         return 'Weather';
      case AppCategory.tools:           return 'Tools';
      case AppCategory.other:           return 'Other';
    }
  }
}

class AppListing {
  const AppListing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.appName,
    required this.description,
    required this.packageName,
    required this.optInUrl,
    required this.category,
    required this.testersNeeded,
    required this.testerIds,
    required this.createdAt,
    this.iconUrl,
    this.targetCountries = const ['All'],
    this.appLanguages = const ['English'],
    this.latestVersion,
    this.minAndroidLevel,
    this.testingInstructions,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String appName;
  final String description;
  final String packageName;
  final String optInUrl;
  final AppCategory category;
  final int testersNeeded;
  final List<String> testerIds;
  final Timestamp createdAt;
  final String? iconUrl;
  final List<String> targetCountries;
  final List<String> appLanguages;
  final String? latestVersion;
  final String? minAndroidLevel;
  final String? testingInstructions;

  int get testerCount => testerIds.length;
  bool get isFull => testerCount >= testersNeeded;

  int get daysLeft {
    final expiry = createdAt.toDate().add(const Duration(days: 14));
    return expiry.difference(DateTime.now()).inDays.clamp(0, 14);
  }

  AppStatus get status {
    if (daysLeft == 0) return AppStatus.expired;
    if (isFull) return AppStatus.full;
    return AppStatus.active;
  }

  String get categoryLabel => category.categoryLabel;
}
