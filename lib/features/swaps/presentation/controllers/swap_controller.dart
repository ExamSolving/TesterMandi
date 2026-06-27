import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../apps/domain/entities/app_listing.dart';
import '../../../apps/presentation/controllers/apps_controller.dart';
import '../../domain/entities/swap_request.dart';
import '../../domain/repositories/swap_repository.dart';

class SwapController extends GetxController {
  SwapController(this._repo);
  final SwapRepository _repo;

  StreamSubscription<List<SwapRequest>>? _receivedSub;
  StreamSubscription<List<SwapRequest>>? _sentSub;

  final dataLoaded = false.obs;
  final pendingReceived = <SwapRequest>[].obs;
  final sentRequests = <SwapRequest>[].obs;
  final isSending = false.obs;
  final isResponding = Rx<String?>(null);

  String get _uid => Get.find<AuthController>().currentUser.value?.uid ?? '';
  String get _myName =>
      Get.find<AuthController>().currentUser.value?.displayName ?? '';

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    ever(auth.currentUser, (_) => _resubscribe());
    if (auth.currentUser.value != null) _resubscribe();
  }

  void _resubscribe() {
    if (_uid.isEmpty) {
      _receivedSub?.cancel();
      _sentSub?.cancel();
      return;
    }
    dataLoaded.value = false;
    _receivedSub?.cancel();
    _sentSub?.cancel();
    bool rLoaded = false, sLoaded = false;
    _receivedSub = _repo.watchReceivedRequests(_uid).listen(
      (list) {
        pendingReceived.value = list;
        rLoaded = true;
        if (rLoaded && sLoaded) dataLoaded.value = true;
      },
      onError: (e) => debugPrint('[SwapController] watchReceived error: $e'),
    );
    _sentSub = _repo.watchSentRequests(_uid).listen(
      (list) {
        sentRequests.value = list;
        sLoaded = true;
        if (rLoaded && sLoaded) dataLoaded.value = true;
      },
      onError: (e) => debugPrint('[SwapController] watchSent error: $e'),
    );
  }

  @override
  void onClose() {
    _receivedSub?.cancel();
    _sentSub?.cancel();
    super.onClose();
  }

  Future<void> loadRequests() async {
    if (_uid.isEmpty) return;
    _resubscribe();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// True if the current user has any non-denied sent request targeting [toAppId].
  /// Used by browse cards to show the "Pending" state.
  bool hasPendingSentRequestTo(String toAppId) {
    return sentRequests.any(
      (r) => r.toAppId == toAppId && r.status != SwapStatus.denied,
    );
  }

  /// True if a non-denied request or active participation already exists for
  /// the given app pair in either direction.
  bool hasExistingSwapFor({required String myAppId, required String theirAppId}) {
    // Outgoing: I sent a non-denied request for this pair
    final sentDup = sentRequests.any((r) =>
        r.fromAppId == myAppId &&
        r.toAppId == theirAppId &&
        r.status != SwapStatus.denied);
    if (sentDup) return true;
    // Incoming: they sent me a request for the same pair (reverse direction)
    final receivedDup = pendingReceived.any(
        (r) => r.fromAppId == theirAppId && r.toAppId == myAppId);
    return receivedDup;
  }

  Future<void> sendSwapRequest({
    required AppListing myApp,
    required AppListing theirApp,
  }) async {
    if (_uid.isEmpty) {
      _snack('You must be logged in to send a swap request.');
      return;
    }
    isSending.value = true;
    try {
      // Fast local check using already-loaded streams before hitting Firestore.
      if (hasExistingSwapFor(myAppId: myApp.id, theirAppId: theirApp.id)) {
        _snack('A swap request already exists for this app pair.');
        return;
      }
      // Full server-side check: also covers active participations and cases
      // where local stream hasn't caught up yet.
      final alreadyPending = await _repo.hasPendingRequest(
        fromUserId: _uid,
        fromAppId: myApp.id,
        toAppId: theirApp.id,
      );
      if (alreadyPending) {
        _snack('You\'re already swapping or testing this app.');
        return;
      }
      await _repo.sendSwapRequest(
        fromUserId: _uid,
        fromUserName: _myName,
        fromAppId: myApp.id,
        fromAppName: myApp.appName,
        fromAppIconUrl: myApp.iconUrl,
        toUserId: theirApp.ownerId,
        toAppId: theirApp.id,
        toAppName: theirApp.appName,
        toAppIconUrl: theirApp.iconUrl,
      );
      // Stream will reflect the new request automatically.
      _snack('Swap request sent! ✅', success: true);
    } catch (e) {
      debugPrint('[SwapController] sendSwapRequest error: $e');
      _snack('Failed to send swap request.');
    } finally {
      isSending.value = false;
    }
  }

  /// Returns true on success so the caller can show the congratulations sheet.
  Future<bool> acceptRequest(SwapRequest request) async {
    isResponding.value = request.id;
    try {
      final myApp = Get.find<AppsController>()
          .myApps
          .firstWhereOrNull((a) => a.id == request.toAppId);

      await _repo.acceptRequest(
        request: request,
        ownerName: _myName,
        ownerOptInUrl: myApp?.optInUrl ?? '',
        ownerAppIconUrl: myApp?.iconUrl,
      );
      return true;
    } catch (e) {
      debugPrint('[SwapController] acceptRequest error: $e');
      _snack('Failed to accept request. Check your connection and try again.');
      return false;
    } finally {
      isResponding.value = null;
    }
  }

  Future<void> denyRequest(SwapRequest request) async {
    isResponding.value = request.id;
    try {
      await _repo.denyRequest(request);
      // Stream will remove the denied request automatically.
      _snack('Request declined.');
    } catch (e) {
      debugPrint('[SwapController] denyRequest error: $e');
      _snack('Failed to decline request.');
    } finally {
      isResponding.value = null;
    }
  }

  void _snack(String msg, {bool success = false}) {
    Get.snackbar(
      '',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: success ? const Color(0xFF059669) : const Color(0xFFDC2626),
      colorText: const Color(0xFFFFFFFF),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      titleText: const SizedBox.shrink(),
    );
  }
}
