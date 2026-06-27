import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../testing/domain/entities/test_participation.dart';
import '../../../testing/presentation/controllers/testing_controller.dart';
import '../../domain/entities/daily_proof.dart';
import '../../domain/repositories/proofs_repository.dart';

class ProofsController extends GetxController {
  ProofsController(this._repo);
  final ProofsRepository _repo;

  final isSubmitting = false.obs;
  final isLoading = false.obs;
  final selectedImages = <File>[].obs;
  final feedbackCtrl = TextEditingController();
  final proofs = <DailyProof>[].obs;
  // Maps participationId → bool (has any proof today — pending or approved)
  final submittedToday = <String, bool>{}.obs;
  // Maps participationId → Set of APPROVED day numbers (green dots)
  final approvedDays = <String, Set<int>>{}.obs;
  // Maps participationId → Set of PENDING day numbers (orange dots)
  final pendingDays = <String, Set<int>>{}.obs;
  // Maps participationId → today's pending proofId (for owner to approve)
  final todayPendingProofId = <String, String?>{}.obs;
  final remindingId = Rx<String?>(null);
  final approvingId = Rx<String?>(null);

  final _picker = ImagePicker();

  String get _uid => Get.find<AuthController>().currentUser.value?.uid ?? '';

  @override
  void onClose() {
    feedbackCtrl.dispose();
    super.onClose();
  }

  Future<void> pickImages() async {
    final remaining = 3 - selectedImages.length;
    if (remaining <= 0) return;
    final images = await _picker.pickMultiImage(imageQuality: 75, limit: remaining);
    if (images.isEmpty) return;
    // Take only as many as slots remaining, then append (never replace)
    selectedImages.addAll(images.take(remaining).map((x) => File(x.path)));
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  Future<void> submitProof(TestParticipation participation) async {
    if (selectedImages.isEmpty) {
      _snack('Add at least one screenshot before submitting.');
      return;
    }
    if (feedbackCtrl.text.trim().isEmpty) {
      _snack('Please write a brief feedback.');
      return;
    }
    isSubmitting.value = true;
    try {
      // Calendar-based day number: day 1 = join date, day 2 = next day, etc.
      final joinDate = DateTime(
        participation.joinedAt.toDate().year,
        participation.joinedAt.toDate().month,
        participation.joinedAt.toDate().day,
      );
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final dayNumber = (today.difference(joinDate).inDays + 1).clamp(1, 14);

      await _repo.submitProof(
        participationId: participation.id,
        appId: participation.appId,
        appName: participation.appName,
        testerId: _uid,
        screenshots: selectedImages,
        feedback: feedbackCtrl.text.trim(),
        dayNumber: dayNumber,
      );

      submittedToday[participation.id] = true;
      // Optimistically mark today as pending (not approved yet)
      final pending = Set<int>.from(pendingDays[participation.id] ?? {});
      pending.add(dayNumber);
      pendingDays[participation.id] = pending;

      selectedImages.clear();
      feedbackCtrl.clear();
      Get.back();
      _snack('Proof submitted successfully! ✅', success: true);
    } catch (e) {
      _snack('Failed to submit: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> loadProofs(String participationId) async {
    isLoading.value = true;
    try {
      proofs.value = await _repo.fetchProofsForParticipation(participationId);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkSubmittedToday(List<TestParticipation> participations) async {
    await Future.wait(participations.map((p) => _loadForParticipation(p)));
  }

  /// Re-fetches all proof statuses for the currently tracked participations.
  Future<void> refreshAll() async {
    final testing = Get.find<TestingController>();
    final participations = <TestParticipation>[
      ...testing.myParticipations,
      ...testing.myAppTesters,
    ];
    if (participations.isEmpty) return;
    await checkSubmittedToday(participations);
  }

  Future<void> _loadForParticipation(TestParticipation p) async {
    final results = await Future.wait([
      _repo.hasSubmittedTodayFor(p.id),
      _repo.fetchDayStatuses(p.id),
      _repo.fetchTodayPendingProofId(p.id),
    ]);
    submittedToday[p.id] = results[0] as bool;
    final statuses = results[1] as Map<int, String>;
    approvedDays[p.id] =
        statuses.entries.where((e) => e.value == 'approved').map((e) => e.key).toSet();
    pendingDays[p.id] =
        statuses.entries.where((e) => e.value == 'pending').map((e) => e.key).toSet();
    todayPendingProofId[p.id] = results[2] as String?;
  }

  Future<void> approveProof(String participationId) async {
    final proofId = todayPendingProofId[participationId];
    if (proofId == null || approvingId.value != null) return;
    approvingId.value = participationId;
    try {
      await _repo.approveDayProof(proofId);
      final pending = Set<int>.from(pendingDays[participationId] ?? {});
      final approved = Set<int>.from(approvedDays[participationId] ?? {});
      final today = pending.isNotEmpty ? pending.last : null;
      if (today != null) {
        pending.remove(today);
        approved.add(today);
      }
      pendingDays[participationId] = pending;
      approvedDays[participationId] = approved;
      todayPendingProofId[participationId] = null;
      Get.back(); // dismiss the review sheet before showing the snack
      _snack('Proof approved! ✅', success: true);
    } catch (_) {
      _snack('Could not approve proof.');
    } finally {
      approvingId.value = null;
    }
  }

  Future<DailyProof?> fetchPendingProofData(String participationId) async {
    final proofId = todayPendingProofId[participationId];
    if (proofId == null) return null;
    return _repo.fetchProofById(proofId);
  }

  Future<void> rejectProof(String participationId) async {
    final proofId = todayPendingProofId[participationId];
    if (proofId == null || approvingId.value != null) return;
    approvingId.value = participationId;
    try {
      await _repo.rejectDayProof(proofId);
      final pending = Set<int>.from(pendingDays[participationId] ?? {});
      pending.remove(pending.isEmpty ? 0 : pending.last);
      pendingDays[participationId] = pending;
      todayPendingProofId[participationId] = null;
      submittedToday[participationId] = false;
      Get.back(); // dismiss the review sheet before showing the snack
      _snack('Proof rejected.');
    } catch (_) {
      _snack('Could not reject proof.');
    } finally {
      approvingId.value = null;
    }
  }

  Future<void> sendReminderToTester({
    required String participationId,
    required String testerId,
    required String appName,
  }) async {
    if (remindingId.value != null) return;
    remindingId.value = participationId;
    try {
      final userName =
          Get.find<AuthController>().currentUser.value?.displayName ?? 'App Owner';
      final sent = await _repo.sendReminderToTester(
        participationId: participationId,
        testerId: testerId,
        appName: appName,
        senderName: userName,
      );
      if (sent) {
        _snack('Reminder sent! 🔔', success: true);
      } else {
        _snack('Already reminded recently. Wait 1 hour between reminders.');
      }
    } catch (_) {
      _snack('Could not send reminder.');
    } finally {
      remindingId.value = null;
    }
  }

  Future<void> sendReminderToOwner({
    required String participationId,
    required String ownerId,
    required String appName,
  }) async {
    if (remindingId.value != null) return;
    remindingId.value = participationId;
    try {
      final userName =
          Get.find<AuthController>().currentUser.value?.displayName ?? 'Tester';
      final sent = await _repo.sendReminderToOwner(
        participationId: participationId,
        ownerId: ownerId,
        appName: appName,
        senderName: userName,
      );
      if (sent) {
        _snack('Reminder sent! 🔔', success: true);
      } else {
        _snack('Already reminded recently. Wait 1 hour between reminders.');
      }
    } catch (_) {
      _snack('Could not send reminder.');
    } finally {
      remindingId.value = null;
    }
  }

  Future<void> scheduleDailyReminders() async {
    await LocalNotificationService.scheduleDailyProofReminder();
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
