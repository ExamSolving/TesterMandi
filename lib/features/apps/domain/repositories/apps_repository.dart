import '../entities/app_listing.dart';

abstract class AppsRepository {
  Future<void> postApp(AppListing app);
  Future<List<AppListing>> fetchAllApps();
  Future<List<AppListing>> fetchUserApps(String userId);
  Future<AppListing?> fetchAppById(String appId);
  Future<bool> packageExists(String packageName);

  Stream<List<AppListing>> watchAllApps();
  Stream<List<AppListing>> watchUserApps(String userId);

  Future<void> togglePauseListing(String appId, {required bool paused});
  Future<void> updateApp(String appId, Map<String, dynamic> fields);

  Future<void> notifyNewAppListed({
    required String appId,
    required String appName,
    required String ownerName,
    required String ownerId,
  });

  Future<void> deleteApp({
    required String appId,
    required String ownerId,
    required String packageName,
  });
}
