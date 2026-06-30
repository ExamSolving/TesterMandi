import 'package:get/get.dart';
import '../../../../core/services/update_service.dart';

class HomeController extends GetxController {
  final currentTabIndex = 0.obs;

  void changeTab(int index) => currentTabIndex.value = index;

  @override
  void onReady() {
    super.onReady();
    // Delay slightly so the home screen finishes rendering first
    Future.delayed(const Duration(seconds: 2), _checkUpdate);
  }

  Future<void> _checkUpdate() async {
    final context = Get.context;
    if (context == null) return;
    await UpdateService.instance.checkForUpdate(context);
  }
}
