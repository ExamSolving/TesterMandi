import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> saveNotification(AppNotification notification);
  Future<void> deleteNotification(String notificationId);
}
