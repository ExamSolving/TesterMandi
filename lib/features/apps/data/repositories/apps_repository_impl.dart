import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_listing.dart';
import '../../domain/repositories/apps_repository.dart';
import '../models/app_listing_model.dart';


class AppsRepositoryImpl implements AppsRepository {
  AppsRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('apps');

  @override
  Future<void> postApp(AppListing app) async {
    final model = AppListingModel(
      id: app.id,
      ownerId: app.ownerId,
      ownerName: app.ownerName,
      appName: app.appName,
      description: app.description,
      packageName: app.packageName,
      optInUrl: app.optInUrl,
      category: app.category,
      testersNeeded: app.testersNeeded,
      testerIds: app.testerIds,
      createdAt: app.createdAt,
      iconUrl: app.iconUrl,
    );
    await _col.doc(app.id).set(model.toFirestore());
  }

  @override
  Future<List<AppListing>> fetchAllApps() async {
    final snap =
        await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map(AppListingModel.fromFirestore).toList();
  }

  @override
  Future<List<AppListing>> fetchUserApps(String userId) async {
    final snap = await _col
        .where('ownerId', isEqualTo: userId)
        .get();
    final list = snap.docs.map(AppListingModel.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<AppListing?> fetchAppById(String appId) async {
    final doc = await _col.doc(appId).get();
    if (!doc.exists) return null;
    return AppListingModel.fromFirestore(doc);
  }

  @override
  Future<bool> packageExists(String packageName) async {
    final snap = await _col
        .where('packageName', isEqualTo: packageName)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Stream<List<AppListing>> watchAllApps() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(AppListingModel.fromFirestore).toList(),
        );
  }

  @override
  Stream<List<AppListing>> watchUserApps(String userId) {
    return _col.where('ownerId', isEqualTo: userId).snapshots().map(
      (snap) {
        final list = snap.docs.map(AppListingModel.fromFirestore).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  @override
  Future<void> notifyNewAppListed({
    required String appId,
    required String appName,
    required String ownerName,
  }) async {
    // Uses FCM topic 'new_apps' — all users subscribed receive this push
    await _db.collection('notification_requests').add({
      'topic': 'new_apps',
      'title': '🚀 New app listed!',
      'body': '$ownerName just listed "$appName" — be among the first testers!',
      'data': {'type': 'new_app', 'appId': appId, 'appName': appName},
      'type': 'new_app',
      'createdAt': Timestamp.now(),
    });
  }
}
