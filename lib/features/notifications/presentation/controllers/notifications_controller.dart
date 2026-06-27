import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsController extends GetxController {
  NotificationsController(this._repo);
  final NotificationsRepository _repo;

  StreamSubscription<List<AppNotification>>? _sub;

  final notifications = <AppNotification>[].obs;
  final isLoading = true.obs;

  String get _uid =>
      Get.find<AuthController>().currentUser.value?.uid ?? '';

  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    ever(auth.currentUser, (_) {
      _sub?.cancel();
      if (_uid.isNotEmpty) _subscribe();
    });
    if (_uid.isNotEmpty) _subscribe();
  }

  void _subscribe() {
    isLoading.value = true;
    _sub = _repo.watchNotifications(_uid).listen(
      (list) {
        notifications.value = list;
        isLoading.value = false;
      },
      onError: (e) {
        debugPrint('[NotificationsController] stream error: $e');
        isLoading.value = false;
      },
    );
  }

  Future<void> reload() async {
    _sub?.cancel();
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 400));
    if (_uid.isNotEmpty) _subscribe();
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    if (_uid.isEmpty) return;
    await _repo.markAllAsRead(_uid);
  }

  Future<void> delete(String id) async {
    await _repo.deleteNotification(id);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
