import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/constants/firebase_constants.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.createdAt,
    super.photoUrl,
    super.fcmToken,
    super.status,
    super.isBanned,
    super.publishedAppIds,
    super.activeTestingIds,
    super.reputationScore,
    super.totalTestsCompleted,
    super.publishedAppCount,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data[FirebaseConstants.fieldUid] as String? ?? doc.id,
      email: data[FirebaseConstants.fieldEmail] as String? ?? '',
      displayName: data[FirebaseConstants.fieldName] as String? ?? '',
      createdAt: (data[FirebaseConstants.fieldJoinedAt] as Timestamp?)
              ?.toDate() ??
          DateTime.now(),
      photoUrl: data['photoUrl'] as String?,
      fcmToken: data[FirebaseConstants.fieldFcmToken] as String?,
      status: _parseStatus(data['status'] as String?),
      isBanned: data[FirebaseConstants.fieldIsBanned] as bool? ?? false,
      publishedAppIds:
          List<String>.from(data['publishedAppIds'] as List? ?? []),
      activeTestingIds:
          List<String>.from(data['activeTestingIds'] as List? ?? []),
      reputationScore:
          (data[FirebaseConstants.fieldRating] as num?)?.toDouble() ?? 0.0,
      totalTestsCompleted:
          data[FirebaseConstants.fieldCompletedTests] as int? ?? 0,
      publishedAppCount: data['publishedAppCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        FirebaseConstants.fieldUid: uid,
        FirebaseConstants.fieldEmail: email,
        FirebaseConstants.fieldName: displayName,
        FirebaseConstants.fieldJoinedAt: Timestamp.fromDate(createdAt),
        'photoUrl': photoUrl,
        FirebaseConstants.fieldFcmToken: fcmToken,
        'status': status.name,
        FirebaseConstants.fieldIsBanned: isBanned,
        'publishedAppIds': publishedAppIds,
        'activeTestingIds': activeTestingIds,
        FirebaseConstants.fieldRating: reputationScore,
        FirebaseConstants.fieldCompletedTests: totalTestsCompleted,
        'publishedAppCount': publishedAppCount,
        FirebaseConstants.fieldLastSeen: FieldValue.serverTimestamp(),
      };

  static UserStatus _parseStatus(String? value) {
    return UserStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserStatus.active,
    );
  }
}
