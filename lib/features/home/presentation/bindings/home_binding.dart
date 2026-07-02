import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../apps/presentation/controllers/apps_controller.dart';
import '../../../apps/data/repositories/apps_repository_impl.dart';
import '../../../testing/presentation/controllers/testing_controller.dart';
import '../../../testing/data/repositories/testing_repository_impl.dart';
import '../../../proofs/data/repositories/proofs_repository_impl.dart';
import '../../../proofs/presentation/controllers/proofs_controller.dart';
import '../../../swaps/data/repositories/swap_repository_impl.dart';
import '../../../swaps/presentation/controllers/swap_controller.dart';
import '../../../chat/data/repositories/chat_repository_impl.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../../notifications/data/repositories/notifications_repository_impl.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final db = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    Get.lazyPut<AppsRepositoryImpl>(() => AppsRepositoryImpl(db, storage));
    Get.lazyPut<TestingRepositoryImpl>(() => TestingRepositoryImpl(db));
    Get.lazyPut<ProofsRepositoryImpl>(() => ProofsRepositoryImpl(db, storage));
    Get.lazyPut<SwapRepositoryImpl>(() => SwapRepositoryImpl(db));
    Get.lazyPut<ChatRepositoryImpl>(() => ChatRepositoryImpl(db));

    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => AppsController(Get.find<AppsRepositoryImpl>()));
    Get.lazyPut(() => TestingController(Get.find<TestingRepositoryImpl>()));
    Get.lazyPut(() => ProofsController(Get.find<ProofsRepositoryImpl>()));
    Get.lazyPut(() => SwapController(Get.find<SwapRepositoryImpl>()));
    Get.lazyPut(() => ChatController(Get.find<ChatRepositoryImpl>()));

    // Register eagerly so the Firestore stream starts the moment the user
    // lands on home — badge updates and foreground banners work immediately.
    if (!Get.isRegistered<NotificationsRepositoryImpl>()) {
      Get.put<NotificationsRepositoryImpl>(
        NotificationsRepositoryImpl(db),
        permanent: true,
      );
    }
    if (!Get.isRegistered<NotificationsController>()) {
      Get.put(
        NotificationsController(Get.find<NotificationsRepositoryImpl>()),
        permanent: true,
      );
    }
  }
}
