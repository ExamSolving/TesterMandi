import 'package:get/get.dart';
import 'notification_service.dart';

class LocalNotificationService {
  static Future<void> init() async {}

  static Future<void> scheduleDailyProofReminder() =>
      Get.find<NotificationService>().scheduleDailyProofReminder();

  static Future<void> cancelAll() =>
      Get.find<NotificationService>().cancelAll();
}
