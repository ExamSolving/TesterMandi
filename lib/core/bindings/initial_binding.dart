import 'package:get/get.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../services/settings_controller.dart';
import '../services/storage_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final storage = Get.put(StorageService(), permanent: true);
    Get.put(SettingsController(storage), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.put(AdService(), permanent: true);
  }
}
