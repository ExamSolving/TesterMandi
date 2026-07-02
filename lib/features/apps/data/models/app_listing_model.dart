import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_listing.dart';

class AppListingModel extends AppListing {
  const AppListingModel({
    required super.id,
    required super.ownerId,
    required super.ownerName,
    required super.appName,
    required super.description,
    required super.packageName,
    required super.optInUrl,
    required super.category,
    required super.testersNeeded,
    required super.testerIds,
    required super.createdAt,
    super.iconUrl,
    super.targetCountries,
    super.appLanguages,
    super.latestVersion,
    super.minAndroidLevel,
    super.testingInstructions,
    super.paused,
  });

  factory AppListingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppListingModel(
      id: doc.id,
      ownerId: d['ownerId'] as String? ?? '',
      ownerName: d['ownerName'] as String? ?? '',
      appName: d['appName'] as String? ?? '',
      description: d['description'] as String? ?? '',
      packageName: d['packageName'] as String? ?? '',
      optInUrl: d['optInUrl'] as String? ?? '',
      category: _parseCategory(d['category'] as String?),
      testersNeeded: (d['testersNeeded'] as num?)?.toInt() ?? 12,
      testerIds: List<String>.from(d['testerIds'] as List? ?? []),
      createdAt: d['createdAt'] as Timestamp? ?? Timestamp.now(),
      iconUrl: d['iconUrl'] as String?,
      targetCountries: List<String>.from(d['targetCountries'] as List? ?? ['All']),
      appLanguages: List<String>.from(d['appLanguages'] as List? ?? ['English']),
      latestVersion: d['latestVersion'] as String?,
      minAndroidLevel: d['minAndroidLevel'] as String?,
      testingInstructions: d['testingInstructions'] as String?,
      paused: d['paused'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'appName': appName,
        'description': description,
        'packageName': packageName,
        'optInUrl': optInUrl,
        'category': category.name,
        'testersNeeded': testersNeeded,
        'testerIds': testerIds,
        'createdAt': createdAt,
        'iconUrl': iconUrl,
        'targetCountries': targetCountries,
        'appLanguages': appLanguages,
        if (latestVersion != null) 'latestVersion': latestVersion,
        if (minAndroidLevel != null) 'minAndroidLevel': minAndroidLevel,
        if (testingInstructions != null) 'testingInstructions': testingInstructions,
        'paused': paused,
      };

  static AppCategory _parseCategory(String? v) => AppCategory.values
      .firstWhere((e) => e.name == v, orElse: () => AppCategory.other);
}
