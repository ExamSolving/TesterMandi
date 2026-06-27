import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../models/app_notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    // Single-field query only — avoids composite index requirement.
    // Sort and cap client-side.
    return _col
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list =
              snap.docs.map(AppNotificationModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.length > 60 ? list.sublist(0, 60) : list;
        });
  }

  @override
  Future<void> markAsRead(String notificationId) =>
      _col.doc(notificationId).update({'isRead': true});

  @override
  Future<void> markAllAsRead(String userId) async {
    // Query only by recipientId (single-field index) then filter isRead client-side
    // to avoid requiring a composite index.
    final snap = await _col.where('recipientId', isEqualTo: userId).get();
    final unread = snap.docs
        .where((d) => (d.data()['isRead'] as bool?) != true)
        .toList();
    if (unread.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<void> saveNotification(AppNotification notification) =>
      _col.doc(notification.id).set(
            (notification as AppNotificationModel).toFirestore(),
            SetOptions(merge: true),
          );

  @override
  Future<void> deleteNotification(String notificationId) =>
      _col.doc(notificationId).delete();
}
