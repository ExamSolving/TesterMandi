import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../controllers/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsRepositoryImpl>(
      () => NotificationsRepositoryImpl(FirebaseFirestore.instance),
    );
    Get.lazyPut(
      () => NotificationsController(Get.find<NotificationsRepositoryImpl>()),
    );
  }
}
