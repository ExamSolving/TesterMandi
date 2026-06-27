import 'dart:io';
import '../entities/daily_proof.dart';

abstract class ProofsRepository {
  Future<void> submitProof({
    required String participationId,
    required String appId,
    required String appName,
    required String testerId,
    required List<File> screenshots,
    required String feedback,
    required int dayNumber,
  });

  Future<List<DailyProof>> fetchProofsForParticipation(String participationId);

  Future<bool> hasSubmittedTodayFor(String participationId);

  /// Returns {dayNumber: status} for all proofs of this participation.
  Future<Map<int, String>> fetchDayStatuses(String participationId);

  Future<String?> fetchTodayPendingProofId(String participationId);

  Future<void> approveDayProof(String proofId);

  Future<DailyProof?> fetchProofById(String proofId);
  Future<void> rejectDayProof(String proofId);

  // Returns false if throttled (< 1 hour since last reminder)
  Future<bool> sendReminderToTester({
    required String participationId,
    required String testerId,
    required String appName,
    required String senderName,
  });

  Future<bool> sendReminderToOwner({
    required String participationId,
    required String ownerId,
    required String appName,
    required String senderName,
  });
}
