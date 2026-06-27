import '../entities/test_participation.dart';

abstract class TestingRepository {
  Future<void> joinApp({
    required String appId,
    required String appName,
    required String appOwnerName,
    required String appOwnerId,
    required String testerId,
    required String testerName,
    required String optInUrl,
    String? iconUrl,
  });
  Future<List<TestParticipation>> fetchUserParticipations(String userId);
  Future<List<TestParticipation>> fetchTestersForMyApps(String ownerId);
  Future<bool> isAlreadyTesting({required String userId, required String appId});
  Future<void> reactivateParticipation(String participationId);

  Stream<List<TestParticipation>> watchUserParticipations(String userId);
  Stream<List<TestParticipation>> watchTestersForMyApps(String ownerId);
}
