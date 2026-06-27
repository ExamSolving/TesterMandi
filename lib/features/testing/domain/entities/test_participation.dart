import 'package:cloud_firestore/cloud_firestore.dart';

/// Completion tier set by the Cloud Function after the 14-day window expires.
enum CompletionTier {
  completed, // 12–14 proofs
  partial,   // 7–11 proofs
  abandoned, // 1–6 proofs
  noShow,    // 0 proofs
}

CompletionTier? completionTierFromString(String? s) {
  switch (s) {
    case 'completed':
      return CompletionTier.completed;
    case 'partial':
      return CompletionTier.partial;
    case 'abandoned':
      return CompletionTier.abandoned;
    case 'no_show':
      return CompletionTier.noShow;
    default:
      return null;
  }
}

class TestParticipation {
  const TestParticipation({
    required this.id,
    required this.appId,
    required this.appName,
    required this.appOwnerName,
    required this.appOwnerId,
    required this.testerId,
    required this.testerName,
    required this.joinedAt,
    required this.optInUrl,
    this.iconUrl,
    this.participationStatus = 'active',
    this.proofsSubmitted = 0,
    this.completionTier,
    this.lastProofAt,
    this.deactivatedAt,
    this.reactivationCount = 0,
  });

  final String id;
  final String appId;
  final String appName;
  final String appOwnerName;
  final String appOwnerId;
  final String testerId;
  final String testerName;
  final Timestamp joinedAt;
  final String optInUrl;
  final String? iconUrl;

  /// Firestore status field: 'active' | 'completed' | 'expired' | 'deactivated'
  /// Defaults to 'active' so old documents without this field are treated as active.
  final String participationStatus;

  /// Running count of proofs submitted — incremented by Cloud Function on each proof.
  final int proofsSubmitted;

  /// Set by Cloud Function when the window expires: 'completed' | 'partial' | 'abandoned' | 'no_show'
  final CompletionTier? completionTier;

  /// Timestamp of the last submitted proof, set by Cloud Function.
  final Timestamp? lastProofAt;

  /// Set when the 14-day window ends and status becomes 'deactivated'.
  /// Cleared to null when the tester reactivates.
  final Timestamp? deactivatedAt;

  /// Incremented each time the tester reactivates after a deactivation.
  final int reactivationCount;

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get isActive => participationStatus == 'active';
  bool get isCompleted => participationStatus == 'completed';
  bool get isExpired => participationStatus == 'expired';
  bool get isDeactivated => participationStatus == 'deactivated';

  int get daysElapsed {
    final joinDate = joinedAt.toDate();
    final j = DateTime(joinDate.year, joinDate.month, joinDate.day);
    final now = DateTime.now();
    final t = DateTime(now.year, now.month, now.day);
    return t.difference(j).inDays + 1;
  }

  int get daysRemaining => (15 - daysElapsed).clamp(0, 14);

  bool get isApproachingExpiry => isActive && daysElapsed >= 12;

  /// Full days elapsed since deactivation (0 if not deactivated).
  int get daysSinceDeactivation {
    if (deactivatedAt == null) return 0;
    final d = deactivatedAt!.toDate();
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
  }

  /// Days remaining before this participation is permanently deleted.
  /// Returns 0 when deletion is imminent.
  int get daysUntilCleanup => (14 - daysSinceDeactivation).clamp(0, 14);

  String get joinedDateLabel {
    final d = joinedAt.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }
}
