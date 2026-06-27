import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/translation_keys.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/test_participation.dart';
import '../../domain/repositories/testing_repository.dart';
import '../../../apps/domain/entities/app_listing.dart';
import '../../../apps/presentation/controllers/apps_controller.dart';

class TestingController extends GetxController {
  TestingController(this._repo);
  final TestingRepository _repo;

  StreamSubscription<List<TestParticipation>>? _participationsSub;
  StreamSubscription<List<TestParticipation>>? _testersSub;

  final dataLoaded = false.obs;
  final myParticipations = <TestParticipation>[].obs;
  final myAppTesters = <TestParticipation>[].obs;
  final joiningAppId = Rx<String?>(null);

  String get _uid => Get.find<AuthController>().currentUser.value?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    ever(auth.currentUser, (_) => _resubscribe());
    if (auth.currentUser.value != null) _resubscribe();
  }

  void _resubscribe() {
    if (_uid.isEmpty) {
      _participationsSub?.cancel();
      _testersSub?.cancel();
      return;
    }
    dataLoaded.value = false;
    _participationsSub?.cancel();
    _testersSub?.cancel();
    // Use a local flag so dataLoaded flips only once both streams have fired.
    bool pLoaded = false, tLoaded = false;
    _participationsSub = _repo.watchUserParticipations(_uid).listen(
      (list) {
        myParticipations.value = list;
        pLoaded = true;
        if (pLoaded && tLoaded) dataLoaded.value = true;
      },
      onError: (e) => debugPrint('[TestingController] watchParticipations error: $e'),
    );
    _testersSub = _repo.watchTestersForMyApps(_uid).listen(
      (list) {
        myAppTesters.value = list;
        tLoaded = true;
        if (pLoaded && tLoaded) dataLoaded.value = true;
      },
      onError: (e) => debugPrint('[TestingController] watchTesters error: $e'),
    );
  }

  @override
  void onClose() {
    _participationsSub?.cancel();
    _testersSub?.cancel();
    super.onClose();
  }

  Future<void> loadMyParticipations() async => _refresh();
  Future<void> loadMyAppTesters() async => _refresh();

  Future<void> _refresh() async {
    if (_uid.isEmpty) return;
    _resubscribe();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<bool> isAlreadyTesting(String appId) =>
      _repo.isAlreadyTesting(userId: _uid, appId: appId);

  Future<void> joinApp(AppListing app) async {
    if (_uid.isEmpty) return;
    joiningAppId.value = app.id;
    try {
      final myName = Get.find<AuthController>().currentUser.value?.displayName ?? '';
      await _repo.joinApp(
        appId: app.id,
        appName: app.appName,
        appOwnerName: app.ownerName,
        appOwnerId: app.ownerId,
        testerId: _uid,
        testerName: myName,
        optInUrl: app.optInUrl,
        iconUrl: app.iconUrl,
      );
      await Get.find<AppsController>().refreshAll();
      await LocalNotificationService.scheduleDailyProofReminder();
      _snack(TKeys.detailJoinSuccess.tr, success: true);
    } catch (e) {
      _snack(TKeys.detailJoinError.tr);
    } finally {
      joiningAppId.value = null;
    }
  }

  Future<void> reactivateParticipation(String participationId) async {
    try {
      await _repo.reactivateParticipation(participationId);
      _snack('Testing reactivated! Fresh 14-day window started.', success: true);
    } catch (e) {
      _snack('Failed to reactivate. Please try again.');
    }
  }

  Future<void> openOptInLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> installApp(String packageName) async {
    final market = Uri.parse('market://details?id=$packageName');
    final web = Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageName');
    if (await canLaunchUrl(market)) {
      await launchUrl(market);
    } else {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  void _snack(String msg, {bool success = false}) {
    Get.snackbar(
      '',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          success ? const Color(0xFF059669) : const Color(0xFFDC2626),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      titleText: const SizedBox.shrink(),
    );
  }
}
